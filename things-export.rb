require 'rubygems'
require 'hpricot'
require 'markaby'
require 'ostruct'

if ARGV.index('-v') || ARGV.index('--version')
  puts "things-export 1.0"
  exit
end

if !ENV['THINGS_REMOTE_PATH']
  STDERR.puts "You need to set THINGS_REMOTE_PATH as the URL to copy the index file with scp."
  STDERR.puts "Example: username@example.com:/var/www/htdocs/todo/"
  exit
end

author = ENV['THINGS_AUTHOR'] ? "#{ENV['THINGS_AUTHOR']}'s" : "My"
things_remote = ENV['THINGS_REMOTE_PATH']

if ARGV.index('--configure') || ARGV.index('-c') || ARGV.index('--install') || ARGV.index('-i')
  pub = File.join(File.dirname(__FILE__), 'public')
  puts "Installing things-export to #{things_remote}"
  system("scp -r #{pub} #{things_remote}")
end

todos = {:done => [], :notdone => []}
$tags = {}

filename = File.expand_path('~/Library/Application Support/Cultured Code/Things/Database.xml')
doc = Hpricot(File.read(filename))

# Get all tags
doc.search('object[@type="TAG"]').each do |tag|
  $tags[tag.attributes["id"]] = tag.search('attribute[@name="title"]').text
end

# Loop through todo items
doc.search('object[@type="TODO"]').each do |todo|
  next if todo.search('relationship[@name="parent"][@idrefs]').empty?
  which = todo.search('attribute[@name="status"]').text.to_i == 3 ? :done : :notdone
  
  obj = OpenStruct.new
  obj.tags = []
  if which == :done
    obj.completed = todo.search('attribute[@name="datecompleted"]').text.to_f
  elsif t=todo.search('attribute[@name="datedue"]').first
    time = Time.at(t.inner_html.to_f).utc
    obj.duedate = Time.utc(Time.now.year, time.month, time.day, time.hour, time.min, time.sec)
  end
  
  if t=todo.search('relationship[@name="tags"][@idrefs]').first
    obj.tags += t.attributes["idrefs"].split(/\s+/)
  end
  
  obj.title = todo.search('attribute[@name="title"]').text
  obj.index = todo.search('attribute[@name="index"]').text
  
  todos[which] << obj
end
todos[:done] = todos[:done].sort_by {|x| x.index }
todos[:notdone] = todos[:notdone].sort_by {|x| x.index }

def taglist(mab, taglist)
  taglist.each do |tag|
    mab.span(:class => 'tag') do
      span(:class => 'leftcap')
      span(:class => 'tagtitle') { $tags[tag] }
      span(:class => 'rightcap')
    end
  end
end

mab = Markaby::Builder.new
mab.html do
  head do 
    title "#{author} ToDo List" 
    link :rel => 'stylesheet', :href => 'style.css', :type => 'text/css', :charset => 'utf-8'
  end
  body do
    h1 "#{author} Things List"

    ul(:id => 'notdone') do
      row = 0
      todos[:notdone].each do |todo|
        row = !row
        li(:class => (row ? 'even' : 'odd')) do
          span(:class => 'leftcap')
          span(:class => 'title') { todo.title }
          span(:class => 'rightcap')
          span(:class => 'duedate') do 
            if (n=((todo.duedate - Time.now.utc) / 86400).to_i) > 14
              todo.duedate.strftime("%b %d")
            else
              n.to_s + " days left"
            end
          end if todo.duedate 
          span(:class => 'tags') { taglist(mab, todo.tags) }
        end
      end
    end

    ul(:id => 'done') do
      row = 0
      todos[:done].each do |todo|
        row = !row
        li(:class => (row ? 'even' : 'odd')) do
          span(:class => 'leftcap')
          span(:class => 'completed') { Time.at(todo.completed).utc.strftime("%b %d, %Y") }
          span(:class => 'title') { todo.title }
          span(:class => 'rightcap')
          span(:class => 'tags') { taglist(mab, todo.tags) }
        end
      end
    end
    
  end
end

index = File.join(File.dirname(__FILE__), 'public', 'index.html')
contents = <<-eof
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
#{mab}
eof

if !ARGV.index('-f') && File.file?(index) && File.read(index) == contents
  puts "Todo list is identical to current local copy, no remote update necessary. Use -f to force."
  exit
end

File.open(index, "w") {|f| f.write(contents) }

puts "Pushing new list to #{things_remote}"
system("scp #{index} #{things_remote}")
