OpenStack_Daemon
================

Simple monitoring tool for back-end openstack host server

FOR WINDOWS - REQUIRES ACTIVESTATE PERL
DOWNLOAD HERE - http://www.activestate.com/activeperl/downloads/thank-you?dl=http://downloads.activestate.com/ActivePerl/releases/5.16.3.1604/ActivePerl-5.16.3.1604-MSWin32-x86-298023.msi


IMPORTANT!!!!!
Open lib/SSH.pm with a text editor (notepad)
edit line 21 
-pw yourpassword


Simply execute with:

perl OpenStack_Daemon.pl

process will be logged in log.txt errors will be logged in error.txt

Trigger to start monitor is to create a empty file named "boom" Trigger to kill daemon process is to create empty file named "kill"

Time between trigger parsing is 6 minutes, or 360 secs :-)
