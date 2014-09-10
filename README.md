OpenStack_Daemon
================

Copy OpenStack_Daemon.pl and lib folder to /root on the OpenStack host server. 
Simply execute with:

perl OpenStack_Daemon.pl

process will be logged in log.txt
errors will be logged in error.txt

Trigger to start monitor is to create a empty file named "boom"
Trigger to kill daemon process is to create empty file named "kill"

Time between trigger parsing is 6 minutes, or 360 secs :-)
