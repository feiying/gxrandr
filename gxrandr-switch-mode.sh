#! /bin/bash

function add_newmode_to_monitor()
{
    monitor=$1
    modeline=$2
    resolution=$3

    echo "### monitor:${monitor}" >> ${LOG}
    echo "### modeline:${modeline}" >> ${LOG}
    echo "### resolution:${resolution}" >> ${LOG}

    echo "### cmd: xrandr --newmode ${modeline}" >> ${LOG}
    xrandr --newmode ${modeline} &>/dev/null
    xrandr --newmode `echo ${modeline} | sed -r 's/"//g'`
    echo "### cmd: xrandr --addmode ${monitor} ${resolution}" >> ${LOG}
    xrandr --addmode ${monitor} ${resolution} #&>/dev/null
}

function add_and_set_newmode_to_main_monitor()
{
    echo "### add_newmode_to_main_monitor ###" >> ${LOG}
    modeline="$(echo ${S_MAX_RES} | tr -s 'x' ' '| xargs cvt | grep "Modeline" |sed -r 's/Modeline//g' | sed -r 's/_60.00//g')"
    resolution="$(echo ${modeline} | awk '{print $1}' | sed -r 's/"//g')"

    ### 增加1024x768 分辨率到主屏。
    add_newmode_to_monitor ${M_MONITOR} "${modeline}" ${resolution}

    ### 设置复制模式
    echo "### cmd: xrandr --output ${S_MONITOR} --mode ${resolution} --auto --output ${M_MONITOR} --mode ${resolution} --same-as ${S_MONITOR}">>${LOG}
    xrandr --output ${S_MONITOR} --mode ${resolution} --auto --output ${M_MONITOR} --mode ${resolution} --same-as ${S_MONITOR}
}

function add_and_set_newmode_to_second_monitor()
{
    echo "### add_newmode_to_second_monitor ###" >> ${LOG}
    modeline="$(echo ${M_MAX_RES} | tr -s 'x' ' '| xargs cvt | grep "Modeline" |sed -r 's/Modeline//g' | sed -r 's/_60.00//g')"
    resolution="$(echo ${modeline} | awk '{print $1}' | sed -r 's/"//g')"

    ### 增加主屏的最大分辨率到副屏；
    add_newmode_to_monitor ${S_MONITOR} "${modeline}" ${resolution}
 
    ### 设置复制模式
    echo "### cmd: xrandr --output ${M_MONITOR} --mode ${M_MAX_RES} --auto --output ${S_MONITOR} --mode ${resolution} --same-as ${M_MONITOR}">> ${LOG}
    xrandr --output ${M_MONITOR} --mode ${M_MAX_RES} --auto --output ${S_MONITOR} --mode ${resolution} --same-as ${M_MONITOR}
}

function checking_resolution_max_between_main_and_second()
{
    echo "### M_MAX_RES: ${M_MAX_RES} # S_MAX_RES: ${S_MAX_RES}" >> ${LOG}
    M_RES_EQUATION=`echo ${M_MAX_RES} | sed -r 's/x/*/g'`
    M_RES_MUL=$[${M_RES_EQUATION}]
    S_RES_EQUATION=`echo ${S_MAX_RES} | sed -r 's/x/*/g'`
    S_RES_MUL=$[${S_RES_EQUATION}]
   
    if [ ${M_RES_MUL} -gt ${S_RES_MUL} ]
    then
        # main monitor add mode of second max resolution. 
        echo "### M_RES_MUL:${M_RES_MUL} greate than SRES_MUL:${S_RES_MUL}" >> ${LOG}
        return 1
    elif [ ${M_RES_MUL} -lt ${S_RES_MUL} ]
    then
        # second monitor add mode with max of main monitor "1366x768" or "1600x900"
        echo "### M_RES_MUL:${M_RES_MUL} little than S_RES_MUL:${S_RES_MUL}" >> ${LOG}
        return 2
    else
        # no operations.
        echo "### M_RES_MUL:${M_RES_MUL} equal S_RES_MUL:${S_RES_MUL}" >> ${LOG}
        return 0
    fi
}

function set_computer_mode()
{
    echo "### switching mode: computer" >> ${LOG}
    echo "### cmd: xrandr --output ${M_MONITOR} --auto --output ${S_MONITOR} --off" >> ${LOG}
    xrandr --output ${M_MONITOR} --auto --output ${S_MONITOR} --off
}

function set_duplicate_mode()
{
    echo "### switching mode: duplicate" >> ${LOG}
    checking_resolution_max_between_main_and_second; res=$?
    if [ ${res} -eq 1 ]; then
        echo "### main monitor have the max resolution, Main Monitor # ${res}" >> ${LOG}
        add_and_set_newmode_to_main_monitor
    elif [ ${res} -eq 2 ];then
        echo "### second monitor have the max resolution, Second Monitor # ${res}" >> ${LOG}
        add_and_set_newmode_to_second_monitor
    else
        echo "### max of main screen same as second screen." >> ${LOG}
    fi
}

function set_extension_mode()
{
    echo "### switching mode: extension " >> ${LOG}
    echo "### cmd:xrandr --output ${M_MONITOR} --auto --output ${S_MONITOR} --right-of ${M_MONITOR}" >> ${LOG}
    xrandr --output ${M_MONITOR}  --auto  --output ${S_MONITOR} --right-of ${M_MONITOR}
}

function set_projector_mode()
{
    echo "### switching mode: projector # " >> ${LOG}
    echo "### cmd:xrandr --output ${S_MONITOR} --auto --output ${M_MONITOR} --off" >> ${LOG}
    xrandr --output ${S_MONITOR} --auto --output ${M_MONITOR} --off
}

function check_and_set_mode()
{
    mode=$1
    if [ "${mode}" = "COMPUTER" ]
    then
        set_computer_mode
    elif [ "${mode}" = "DUPLICATE" ]
    then
        set_duplicate_mode
    elif [ "${mode}" = "EXTENSION" ]
    then
        set_extension_mode
    elif [ "${mode}" = "PROJECTOR" ]
    then
        set_projector_mode
    else
        echo "### switching mode: Unknown" >> ${LOG}
    fi
}

MODE="$1"; N_NUM=""; M_MONITOR=""; S_MONITOR=""; M_MAX_RES=""; S_MAX_RES=""
#TIME=`date "+%y%m%d%H%M%S"`
#LOG="/dev/stdout"
LOG="/tmp/xrandr.log"
if [ -e ${LOG} ];then rm ${LOG}; fi

### M_NUM:Monitor numbers. 判断是否双显示器
M_NUM="$(xrandr | grep "\<connected\>" | wc -l)" 
if [ "${M_NUM}" = "2" ];then
    xrandr | grep "\<connected\>" | grep "DP5"; res=$?
    echo "### res: $res"
    if [ ${res} -eq 0 ]
    then
        echo "### primary monitor is DP5" >> $LOG
        M_MONITOR="$(xrandr  | grep "\<connected\>" | sed -n '2 p' | awk '{print $1}')"
        S_MONITOR="$(xrandr | grep -m 1 "\<connected\>" | cut -d ' ' -f1)"
    else
        echo "### primary monitor is not DP5" >> $LOG
        M_MONITOR="$(xrandr | grep -m 1 "\<connected\>" | cut -d ' ' -f1)"
        S_MONITOR="$(xrandr  | grep "\<connected\>" | sed -n '2 p' | awk '{print $1}')"
    fi
    xrandr --output ${M_MONITOR} --auto --output ${S_MONITOR} --off
    M_MAX_RES="$(xrandr | grep "*" | awk '{print $1}' | sed -n '1 p')"
    xrandr --output ${S_MONITOR} --auto --output ${M_MONITOR} --off
    S_MAX_RES="$(xrandr | grep "*" | awk '{print $1}' | sed -n '1 p')"
    
    echo "### MonitorNum:${M_NUM} #M_MONITOR: ${M_MONITOR} #S_MONITOR: ${S_MONITOR} #M_MAX_RES: ${M_MAX_RES} #S_MAX_RES: ${S_MAX_RES}" >> ${LOG}
    ### 判断需要设置的模式
    check_and_set_mode ${MODE}
else
    echo "### ERROR, Please checking monitor number." >> ${LOG}
    exit -1
fi
