#!/bin/bash

while [ 1 ]
do
	num_screen=`xrandr |grep connected |grep -v disconnected |wc -l`
	
	case "$num_screen" in
		'1' )
			#echo "1"
			size_mode=`xrandr | grep " connected" | awk -F' ' '{ print $4 }' | awk -F'+' '{print $1}' | grep -e "[0-9]*x[0-9]*"`
			in_screen=`xrandr |grep " connected"|awk '{print $1}'`
			if [ -f "/tmp/gxrandr-mode" ];then
				size_mode_exit=`cat /tmp/gxrandr-mode`
				if [ "$size_mode_exit" != "$size_mode" ];then
					echo $size_mode >/tmp/gxrandr-mode
				fi
			else
				echo $size_mode >/tmp/gxrandr-mode
			fi
			if [ ! -f ~/.in_screen ];then
				echo $in_screen >~/.in_screen
			fi
			if [ -f ~/.num_screen ];then
				num_screen_exit=`cat ~/.num_screen`
				if [ "$num_screen_exit" != "$num_screen" ];then
					echo $num_screen >~/.num_screen
				fi
			else
				echo $num_screen >~/.num_screen
			fi
			echo "0" >~/.gxrandr
		;;
		'2' )
			#echo "2"
			if [ -f ~/.num_screen ];then
				num_screen_exit=`cat ~/.num_screen`
				#echo "$num_screen_exit-----$num_screen"
				if [ "$num_screen_exit" != "$num_screen" ];then
					in_screen=`cat ~/.in_screen`
					size_mode=`cat /tmp/gxrandr-mode`
					out_screen=`xrandr |grep " connected" |grep -v "$in_screen" |awk '{print $1}'`
					wight=`echo $size_mode |awk -F 'x' '{print $1}'`
                                        hight=`echo $size_mode |awk -F 'x' '{print $2}'`
					if [ "$in_screen"  != "DP5" ];then
                                        	cvt_string=`cvt $wight $hight |grep -v \# |sed 's/Modeline//g'` 
                                        	new_size_mode=`echo $cvt_string |awk -F '"' '{print $2}'`
						cvt_string_2=`echo $cvt_string |awk -F '"' '{print $3}'`
                                        	xrandr --newmode $new_size_mode $cvt_string_2
                                        	xrandr --addmode $out_screen $new_size_mode

						xrandr  --output $in_screen --auto --mode $size_mode  --output $out_screen --off
						usleep 10000
						xrandr --output $in_screen --mode $size_mode --output $out_screen --mode $new_size_mode --same-as $in_screen
					else
						xrandr  --output $in_screen --auto --mode $size_mode  --output $out_screen --off
						usleep 10000
						xrandr --output $in_screen --auto --output $out_screen  --auto --same-as $in_screen
					fi
					echo "1" >~/.gxrandr
					echo $num_screen >~/.num_screen
				fi
			else	
				echo $num_screen >~/.num_screen
			fi
		;;
	esac
	sleep 1
done
