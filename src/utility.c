#include <stdio.h>
#include <stdlib.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>

#include <unistd.h>
#include <pwd.h>

#include "gxrandr.h"

char monitors[2][64]; // 显示器接口名
char mode_name[32]; // mode, eg. 1024x768 1399x768 ...
int valid_monitor_number = TRUE;
char cvt_string[128] = "";

static void read_cvt(char* buf) {
	FILE* fp = fopen("/tmp/gxrandr_cvt", "r");
	fgets(buf, 128, fp);
	fclose(fp);
}

char* cvt(int width, int height)
{
	char cmd[256];
	sprintf(cmd, "cvt %d %d | grep Modeline | awk -F' ' '{print $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13}' > /tmp/gxrandr_cvt", width, height);
	system(cmd);
	char* result = (char*)malloc(sizeof(char) * 128);
	read_cvt(result);
	system("rm -f /tmp/gxrandr_cvt");
	
	return result;
}

// ensures only one process is running at the same time
void single_process() {
	int pid_file = open("/tmp/gxrandr.pid", O_CREAT | O_RDWR, 0666);

	FILE* fp = fopen("/tmp/gxrandr.pid", "w");
	fprintf(fp, "%d\n", getpid());
	fclose(fp);

	int lock = lockf(pid_file, F_TLOCK, 0);
	
	if ( lock != 0 ) {
		fprintf(stderr, "gxrandr is already running\n");
		exit(1);
	}
}

void get_cvt_string()
{
	int width = 0;
	int height = 0;

	sscanf(mode_name, "%dx%d", &width, &height);
	
        width=1024;
        height=768;
        printf ("### width: %d\t height: %d\n", width, height);
	char* buf = cvt(width, height);
	strcpy(cvt_string, buf);
	free(buf);
}

// use xrandr to perform the real configuration change
void real_change_mode(int mode)
{
	char command[256] = "";
	char cmd[256] = "";
	char* cvt_str = NULL;
	int com;

	switch(mode) {
	    case COMPUTER_MODE:
	        sprintf(command, "gxrandr-switch-mode.sh COMPUTER");
		break;
	    case DUPLICATE_MODE:
	        sprintf(command, "gxrandr-switch-mode.sh DUPLICATE");
		break;
	    case EXTENSION_MODE:
	        sprintf(command, "gxrandr-switch-mode.sh EXTENSION");
		break;
	    case PROJECTER_MODE:
	        sprintf(command, "gxrandr-switch-mode.sh PROJECTOR");
		break;
	    default:
	        sprintf(command, "gxrandr-switch-mode.sh");
		break;
	}
	system(command);
	
	switch(mode) {
		case COMPUTER_MODE:
			sprintf(cmd, "echo %d > ~/.gxrandr", COMPUTER_MODE);
			break;
		case DUPLICATE_MODE:
			sprintf(cmd, "echo %d > ~/.gxrandr", DUPLICATE_MODE);
			break;
		case EXTENSION_MODE:
			sprintf(cmd, "echo %d > ~/.gxrandr", EXTENSION_MODE); 
			break;
		case PROJECTER_MODE:
			sprintf(cmd, "echo %d > ~/.gxrandr", PROJECTER_MODE); 
			break;
	    }
	    
	//printf("%s\n", command);
	//system(command);
	system("touch ~/.gxrandr");
	system(cmd);
}

// read home dir name to result.
static void get_home_dir(char* result) {
	uid_t user_id = getuid();
	struct passwd *pw = getpwuid(user_id);
	strcpy(result, pw->pw_dir);
}

static void get_monitor_names() {
	FILE* fp = NULL;
	int tag = system("test `xrandr | grep \' connected\' | wc -l` -eq 2");

	if ( tag != 0 ) {
		// 目前仅支持2个显示器
		valid_monitor_number = FALSE;
		strcpy(monitors[0], "LVDS");
		strcpy(monitors[1], "VGA-0");
	}
	else {
		system("xrandr | grep \' connected\' | awk -F' ' '{print $1}' > /tmp/gxrandr");

		fp = fopen("/tmp/gxrandr", "r");
		if ( fp == NULL ) {
			printf("[error] cannot read /tmp/gxrandr\n");
			strcpy(monitors[0], "LVDS");
			strcpy(monitors[1], "VGA-0");
		}
		else {
			fscanf(fp, "%s\n", monitors[0]);
			fscanf(fp, "%s\n", monitors[1]);
			fclose(fp);
		}

		// if LVDS is dectected as the second monitor, make it the first one.
		//if ( strcmp(monitors[1], "LVDS") == 0 ) {
		//	char str[128] = "";
		//	strcpy(str, monitors[0]);
		//	strcpy(monitors[0], "LVDS");
		//	strcpy(monitors[1], str);
		//}
		// if DP5 is dectected as the second monitor, make it the first one.
		if ( strcmp(monitors[1], "DP5") == 0 ) {
			char str[128] = "";
			strcpy(str, monitors[0]);
			strcpy(monitors[0], "DP5");
			strcpy(monitors[1], str);
		}
		if ( strcmp(monitors[1], "DP6") == 0 ) {
			char str[128] = "";
			strcpy(str, monitors[0]);
			strcpy(monitors[0], "DP6");
			strcpy(monitors[1], str);
		}
		if ( strcmp(monitors[1], "LCD") == 0 ) {
			char str[128] = "";
			strcpy(str, monitors[0]);
			strcpy(monitors[0], "LCD");
			strcpy(monitors[1], str);
		}
	}
}

// guess the latest projecter mode
int guess() {
	int mode = 0;
	FILE* fp = NULL;

	if ( system("test -f ~/.gxrandr") == 0 ) {
		char* home = (char*)alloca(sizeof(char) * 256);
		get_home_dir(home);
		strcat(home, "/.gxrandr");

		fp = fopen(home, "r");
		fscanf(fp, "%d", &mode);
		fclose(fp);
	}

	get_monitor_names();

	if ( system("test -f /tmp/gxrandr-mode") != 0 ) {
		system("xrandr | grep \" connected\" | awk -F' ' '{ print $4 }' | awk -F'+' '{print $1}' | grep -e \"[0-9]*x[0-9]*\" > /tmp/gxrandr-mode");
		if ( system("xrandr |grep \" connected\" |grep DP |grep -v primary") == 0 ){
			system("xrandr | grep \" connected\" |grep DP | awk -F' ' '{ print $3 }' | awk -F'+' '{print $1}' | grep -e \"[0-9]*x[0-9]*\" > /tmp/gxrandr-mode");
		}
	}
		if ( system("xrandr |grep \" connected\" |grep DP |grep primary ") == 0 ){
			system("xrandr | grep \" connected\" |grep DP | awk -F' ' '{ print $4 }' | awk -F'+' '{print $1}' | grep -e \"[0-9]*x[0-9]*\" > /tmp/gxrandr-mode");
		}
	fp = fopen("/tmp/gxrandr-mode", "r");
	fscanf(fp, "%s", mode_name);
	sprintf(mode_name,"%s","1024x768_60.00");
	fclose(fp);

	return mode;
}
