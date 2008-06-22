Things Export 1.0
=================

Written by **Loren Segal** in 2008. Licensed under MIT license.


SYNOPSIS
--------

Exports your **Things.app** todo items to a simple webpage using `scp`. It
is recommended that you add your public key to your remote SSH server for
this to work smoothly.


INSTALL
-------

`things-export` requires the environment variable `THINGS_REMOTE_PATH` to be
set to the public www directory that the page will be copied to. You can set
this manually per session or in your `~/.profile` file with:

    export THINGS_REMOTE_PATH=user@example.com:/var/www/htdocs/todo/
    
*Note the username and host that need to be changed.*

You can optionally specify the `THINGS_AUTHOR` environment variable which will
put your name in the title, ex. "Loren Segal's ToDo List". Defaults to "My ToDo List".

Finally, type `ruby things-export.rb --install` after configuring your environment 
variables to copy over the necessary support files to the remote server. This will
also export your database for the first time. After the support files are copied,
you no longer need to run the script with `--install`.


RUNNING
-------

After things-exporter is installed on the remote server, simply use `ruby things-export.rb`
to update the remote just the index file. If there is nothing to update, no connection will
be made. You can force an update with -f. Ideally, you can run this script from a cron-job 
to update your Things todo list every now and then.