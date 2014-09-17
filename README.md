OpenStack_Daemon
================

Simple monitoring tool for back-end openstack host server

FOR WINDOWS - REQUIRES ACTIVESTATE PERL
DOWNLOAD HERE - http://www.activestate.com/activeperl/downloads/thank-you?dl=http://downloads.activestate.com/ActivePerl/releases/5.16.3.1604/ActivePerl-5.16.3.1604-MSWin32-x86-298023.msi


IMPORTANT!!!!!
Open login.config
and edit with your info.

first line is the ip to openstack host

second line is the password for root admin. 

third line is minimum number of instances you want active

fourth line is minimum number of instances  you want created


Simply execute with:

perl OpenStack_Daemon.pl

process will be logged in log.txt errors will be logged in error.txt

resource audit values will be in audit.txt

Trigger to start monitor is to create a empty file named "boom" Trigger to kill daemon process is to create empty file named "kill"

Time between trigger parsing is 6 minutes, or 360 secs :-)
