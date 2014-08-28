#ifndef UTILITY_H
#define UTILITY_H

extern char monitors[2][64]; // 显示器接口名
extern char mode_name[32]; // mode, eg. 1024x768 1399x768 ...
extern int valid_monitor_number;

char* cvt(int width, int height);
void real_change_mode(int mode);
int guess();

#endif
