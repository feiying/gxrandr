#!/bin/bash
# ellenpeng <yan.peng@cs2c.com.cn> @ 2012-05-30
# This script want to detect the VGA plug/unplug event.

# display_old, display_new is the number of display 
# to compare the display_old and display_new to check the plug/unplug event
display_old=1
/bin/cat /proc/cmdline |grep notebook  >/dev/null 2>&1
if [ 1 == $? ];then
   exit
fi

while true
do
	sleep 2
   # use drm drvier, just for opensource intel/ati/nv driver
	if [ -d /sys/class/drm/card0 ]; then
		display_new=0
		for i in `ls /sys/class/drm/card*/status`
		do
			if [ `cat $i` = "connected" ];then
				display_new=$((display_new+1))
			fi
		done
   fi

   if [ $display_old -ne $display_new ]; then
		if [ $display_new -eq 2 ];then
			# dual display, change the display to clone mode
			/usr/bin/gxrandr &
		fi
   fi
   
   if [ $display_new -eq 1 -a -f /tmp/gxrandr.pid ]; then
		if [ `cat ~/.gxrandr` -eq 3 ]; then
			pid=`cat /tmp/gxrandr.pid`
			kill -9 $pid
			rm -f /tmp/gxrandr.pid
			#/usr/bin/gxrandr -m 1
			xrandr --auto
		fi
   	fi
   display_old=$display_new
done
