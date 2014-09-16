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
    xrandr --newmode `echo ${modeline} | sed -r 's/"//g'` &>/dev/null
    echo "### cmd: xrandr --addmode ${monitor} ${resolution}" >> ${LOG}
    xrandr --addmode ${monitor} ${resolution} &>/dev/null
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
    m_res_equation=`echo ${M_MAX_RES} | sed -r 's/x/*/g'`
    m_res_mul=$[${m_res_equation}]
    s_res_equation=`echo ${S_MAX_RES} | sed -r 's/x/*/g'`
    s_res_mul=$[${s_res_equation}]
   
    if [ ${m_res_mul} -gt ${s_res_mul} ]
    then
        # main monitor add mode of second max resolution. 
        echo "### m_res_mul:${m_res_mul} greate than SRES_MUL:${s_res_mul}" >> ${LOG}
        return 1
    elif [ ${m_res_mul} -lt ${s_res_mul} ]
    then
        # second monitor add mode with max of main monitor "1366x768" or "1600x900"
        echo "### m_res_mul:${m_res_mul} little than s_res_mul:${s_res_mul}" >> ${LOG}
        return 2
    else
        # no operations.
        echo "### m_res_mul:${m_res_mul} equal s_res_mul:${s_res_mul}" >> ${LOG}
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
    xrandr --output ${M_MONITOR}  --auto  --output ${S_MONITOR} --right-of ${M_MONITOR} --auto
}

function set_projector_mode()
{
    echo "### switching mode: projector" >> ${LOG}
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
        ### capture current mode. 
        get_current_mode 
    fi
}

function get_current_mode()
{
    if [ "${N_NUM}" = "1" ];then 
        echo "### CAPTURE MODE: computer" >> ${LOG}
        touch ${C_FILE}
    elif [ "${N_NUM}" = "2" ]; then
        echo "### screen current: ${SCREEN_CUR} #M_MAX_RES: ${M_MAX_RES} #S_MAX_RES: ${S_MAX_RES}" >> ${LOG}
        temp_screen_cur_l=`echo ${SCREEN_CUR} | awk -Fx '{print $1}'`
        temp_m_max_res_l=`echo ${M_MAX_RES} | awk -Fx '{print $1}'`
        temp_s_max_res_l=`echo ${S_MAX_RES} | awk -Fx '{print $1}'`
        temp_m_run_res_l=`echo ${M_RUN_RES} | awk -Fx '{print $1}'`
        temp_s_run_res_l=`echo ${S_RUN_RES} | awk -Fx '{print $1}'`
        #diff_m=`expr ${temp_screen_cur_l} - ${temp_m_run_res_l}`
        #diff_m_abs=${diff_m#-}
        #diff_s=`expr ${temp_screen_cur_l} - ${temp_s_run_res_l}`
        #diff_s_abs=${diff_s#-}
        sum_m_s=`expr ${temp_m_run_res_l} + ${temp_s_run_res_l}`
        #echo "### diff_m: ${diff_m} abs: ${diff_m_abs} #diff_s: ${diff_s} abs: ${diff_s_abs} #temp_screen_cur_l: ${temp_screen_cur_l} #temp_m_run_res_l: ${temp_m_run_res_l} #temp_s_run_res_l: ${temp_s_run_res_l}" >> ${LOG}
        echo "### temp_screen_cur_l: ${temp_screen_cur_l} #temp_m_run_res_l: ${temp_m_run_res_l} #temp_s_run_res_l: ${temp_s_run_res_l}" >> ${LOG}

        num="$(xrandr | grep "*" | wc -l)" 
        if [ "${num}" = "1"  ];then
            if [ ${temp_m_max_res_l} -eq ${temp_screen_cur_l} ];then
                echo "### CAPTURE MODE: computer" >> ${LOG}
                touch ${C_FILE} 
            elif [ ${temp_s_max_res_l} -eq ${temp_screen_cur_l} ];then
                echo "### CAPTURE MODE: projector" >> ${LOG}
                touch ${P_FILE} 
            else
                echo "### CAPTURE MODE: unknown1" >> ${LOG}
            fi
        elif [ "${num}" = "2"  ];then
            #if [ ${temp_m_run_res_l} -eq ${temp_screen_cur_l} ];then
            echo "### sum_m_s: ${sum_m_s} # temp_screen_cur_l: ${temp_screen_cur_l}" >> ${LOG}
            if [ ${sum_m_s}"n" = ${temp_screen_cur_l}"n" ]; then
                echo "### CAPTURE MODE: extension" >> ${LOG}
                touch ${E_FILE} 
            else
                echo "### CAPTURE MODE: duplicate" >> ${LOG}
                touch ${D_FILE} 
            fi
        else
            echo "### CAPTURE MODE: unknown2" >> ${LOG}
        fi
    else
        echo "### CAPTURE MODE: unknown3" >> ${LOG}
    fi
}

function init_data()
{
    xrandr > ${XRANDR_INFO}    
    num_m=0; num_s=0
    while read line
    do
        # primary monitor max resolution
        xrandr | grep "\<connected\>" | grep "DP5" >/dev/null; res_m=$?
        if [ ${res_m} -eq 0 ]; then
            if [ ${num_m} -eq 1 ]; then
                M_MAX_RES=`echo ${line} | awk '{print $1}'`
                #echo "### PRIMARY MONITOR MAX RES: ${M_MAX_RES}" >> ${LOG}
            fi
            echo $line | grep DP5 >/dev/null; res_m=$?
            if [ ${res_m} -eq 0 ]; then num_m=1;else num_m=0; fi
        else
            if [ ${num_m} -eq 1 ]; then
                M_MAX_RES=`echo ${line} | awk '{print $1}'`
                #echo "### PRIMARY MONITOR MAX RES: ${M_MAX_RES}" >> ${LOG}
            fi
            echo $line | grep LCD >/dev/null; res_m=$?
            if [ ${res_m} -eq 0 ]; then num_m=1;else num_m=0; fi
        fi
        
        # CRT1 max resolution
        if [ ${num_s} -eq 1 ]; then
            S_MAX_RES=`echo ${line} | awk '{print $1}'`
            echo "### CRT1 MAX RES: ${S_MAX_RES}" >> ${LOG}
        fi
        echo $line | grep CRT1 >/dev/null; res_s=$?
        if [ ${res_s} -eq 0 ]; then num_s=1;else num_s=0; fi
    done < ${XRANDR_INFO} 
    
    SCREEN_CUR="$(xrandr | grep Screen | awk -F, '{print $2}' | sed -r 's/ //g'| sed -r 's/current//g')"
    xrandr | grep "\<connected\>" | grep "DP5" >/dev/null; res=$?
    if [ ${res} -eq 0 ]
    then
        echo "### INIT RN1400" >> ${LOG}
        M_MONITOR="$(xrandr  | grep "\<connected\>" | sed -n '2 p' | awk '{print $1}')"
        S_MONITOR="$(xrandr | grep -m 1 "\<connected\>" | cut -d ' ' -f1)"
        M_RUN_RES="$(xrandr | grep "*" |awk '{print $1}' | sed -n '2 p')"
        S_RUN_RES="$(xrandr | grep "*" |awk '{print $1}' | sed -n '1 p')"
    else
        echo "### INIT N480" >> $LOG
        M_MONITOR="$(xrandr | grep -m 1 "\<connected\>" | cut -d ' ' -f1)"
        S_MONITOR="$(xrandr  | grep "\<connected\>" | sed -n '2 p' | awk '{print $1}')"
        M_RUN_RES="$(xrandr | grep "*" |awk '{print $1}' | sed -n '1 p')"
        S_RUN_RES="$(xrandr | grep "*" |awk '{print $1}' | sed -n '2 p')"
    fi
    echo "### SCREEN_CUR:${SCREEN_CUR} #MonitorNum:${N_NUM} #M_MONITOR: ${M_MONITOR} #S_MONITOR: ${S_MONITOR} #M_MAX_RES: ${M_MAX_RES} #S_MAX_RES: ${S_RUN_RES} #M_RUN_RES: ${M_RUN_RES} #S_RUN_RES: ${S_RUN_RES}" >> ${LOG}
}

function clear_temp_file_and_log()
{
    if [ -e ${LOG} ];then rm ${LOG}; fi
    if [ -e ${C_FILE} ];then rm ${C_FILE}; fi
    if [ -e ${D_FILE} ];then rm ${D_FILE}; fi
    if [ -e ${E_FILE} ];then rm ${E_FILE}; fi
    if [ -e ${P_FILE} ];then rm ${P_FILE}; fi
}

### MAIN ### 
MODE="$1"; N_NUM=""; M_MONITOR=""; S_MONITOR=""; M_MAX_RES=""; S_MAX_RES=""; M_RUN_RES=""; S_RUN_RES=""; SCREEN_CUR=""
XRANDR_INFO="/tmp/xrandr.info"
#TIME=`date "+%y%m%d%H%M%S"` 
#LOG="/dev/stdout"
LOG="/tmp/xrandr.log"
C_FILE="/tmp/computer.mode"
D_FILE="/tmp/duplicate.mode"
E_FILE="/tmp/extension.mode"
P_FILE="/tmp/projector.mode"

# clear all cache file.
clear_temp_file_and_log

N_NUM="$(xrandr | grep "\<connected\>" | wc -l)" 
if [ "${N_NUM}" = "2" ];then
    ### init global data
    init_data

    ### checking and set switching mode.
    check_and_set_mode ${MODE}

elif [ "${N_NUM}" = "1" ];then
    echo "### CAPTURE MODE: computer" >> ${LOG}
    touch ${C_FILE} 
else
    echo "### ERROR, Please checking monitor number." >> ${LOG}
    exit -1
fi
