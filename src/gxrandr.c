#include <errno.h>
#include <gtk/gtk.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <gdk/gdkkeysyms.h>
#include <unistd.h>
#include "gxrandr.h"

static GtkWidget *window = NULL; // 主窗口
static GtkWidget *fixed = NULL; // 固定框(不可见，容器)
GtkWidget *horizontal_box = NULL;  // 水平容器
static GtkWidget* frame; // 选择框
static GtkWidget* image[4]; // 图片
static GtkWidget* event_box[4];

static GtkWidget* closebtn = NULL;
static GtkWidget* closebtn_event_box = NULL;

static int frame_pos[4];
static int current_mode = -1;

int screen_width = 1024;
int screen_height = 768;
int win_width = 512;
int win_height = 128;
static int mode_chosen=0;
// forward declarations
static gint timeout_cb(gpointer data);
static void get_display_metrics();
static void update_widget_sizes();
static void key_value(GtkWidget *widget, GdkEventKey *event, gpointer data);
static void change_mode(int mode);

void event_execute(gint event)
{
	printf("enter event_execute\n");
	switch(event)
	{
		case 0:
			system("gxrandr-switch-mode.sh COMPUTER");
			system("rm /tmp/myp_exist");
			printf("gx0\n");
			gtk_main_quit();
			break;

		case 1:
			system("gxrandr-switch-mode.sh DUPLICATE");
			system("rm /tmp/myp_exist");
			printf("gx1\n");
			gtk_main_quit();
			break;

		case 2:
			system("gxrandr-switch-mode.sh EXTENSION");
			system("rm /tmp/myp_exist");
			printf("gx2\n");
			gtk_main_quit();
			break;

		case 3:
			system("gxrandr-switch-mode.sh PROJECTOR");
			system("rm /tmp/myp_exist");
			printf("gx3\n");
			gtk_main_quit();
			break;
Default:
			break;
	}
}

static void key_value(GtkWidget *widget, GdkEventKey *event, gpointer data)
{
	if( event->keyval == 0xffeb )
	{
		mode_chosen = (mode_chosen+1)%4;
		change_mode(mode_chosen);
	}
	else if( event->keyval == 0xff0d )
	{
		printf("enter or button is pressed\n");
		event_execute(mode_chosen);
	}

	else if( event->keyval == 0xff53)
	{
		mode_chosen = (mode_chosen+1)%4;
		change_mode(mode_chosen);
	}
	else if( event->keyval == 0xff51)
	{
		mode_chosen = (mode_chosen+3)%4;
		change_mode(mode_chosen);
	}

	printf("the keyval is %x\n",event->keyval);

}

static void change_mode(int mode) {
	if ( mode < 0 || mode > 3 ) {
		g_print("[ERROR] Unrecognizable mode(%d)\n",mode);
		return;
	}
	mode_chosen = mode;
	if ( current_mode != mode ) {
		//gtk_widget_set_visible(frame[mode], TRUE);
		gtk_fixed_move(GTK_FIXED(fixed), frame, frame_pos[mode], 0);
		current_mode = mode;
	}
}

static void get_display_metrics()
{
	GdkScreen* screen = gdk_screen_get_default();
	screen_width = gdk_screen_get_width(screen);
	screen_height = gdk_screen_get_height(screen);

	if ( screen_width > 1440 ) {
		screen_width = 1440;
	}

	win_width = screen_width / 2;
	win_height = win_width / 4;


	int i = 0;
	for ( i = 0; i < 4; i++ ) {
		frame_pos[i] = i * win_height;
	}
}

static void update_widget_sizes()
{
	get_display_metrics();
	gtk_window_resize(GTK_WINDOW(window), win_width, win_height);
	gtk_widget_set_size_request( frame, win_height, win_height);

	int i = 0;
	for ( i = 0; i < 4; i++ ) {
		gtk_widget_set_size_request(GTK_WIDGET(image[i]), win_height, win_height);
	}
}


static gboolean press_handler(GtkWidget* widget, GdkEvent* event, gpointer user_data)
{
	change_mode((int)user_data);

	event_execute((int)user_data);

	return FALSE;
}

static gboolean close_handler(GtkWidget* widget, GdkEvent* event, gpointer user)
{
	gtk_main_quit();
	system("rm /tmp/myp_exist");
	//	system("rm -f /tmp/gxrandr.pid; rm -f /tmp/gxrandr");
	return FALSE;
}

static GdkPixbuf* closebtn_pixbuf[2];
// 鼠标进入关闭按钮时被调用
static gboolean closebtn_enter_handler(	GtkWidget* widget, GdkEvent* event, gpointer user)
{
	gtk_image_set_from_pixbuf((GtkImage*)closebtn, closebtn_pixbuf[1]);
	return FALSE;
}

// 鼠标离开关闭按钮时被调用
static gboolean closebtn_leave_handler(	GtkWidget* widget, GdkEvent* event, gpointer user)
{
	gtk_image_set_from_pixbuf((GtkImage*)closebtn, closebtn_pixbuf[0]);
	return FALSE;
}

// 加载图片，放大缩小，再传给新的GtkImage
GtkWidget* gtk_image_new_from_file_at_scale( const gchar *filename, int width, int height)
{
	GdkPixbuf* pixbuf = NULL;

	pixbuf = gdk_pixbuf_new_from_file_at_scale(filename, width, height, FALSE, NULL);
	if ( pixbuf == NULL ) {
		return NULL;
	}

	GtkWidget* image = gtk_image_new_from_pixbuf(pixbuf);
	return image;
}

static int cmd_mode = 0;
static int cmd_mode_no = 0;

void init(int argc, char* argv[]) {

	// getopt, getopt_long, getopt_long_only, optarg, opterr, optopt
	int c = getopt(argc, argv, "m:");

	if ( c == 'm' ) {
		cmd_mode = 1;
		cmd_mode_no = atoi(optarg);
		exit(0);
	}
	else {
		gtk_init(&argc, &argv);
		get_display_metrics();
	}
}

void create_main_window() {
	window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
	gtk_window_resize(GTK_WINDOW(window), win_width, win_height);
	gtk_window_set_opacity(GTK_WINDOW(window), 0.8f);

	gtk_window_set_position(GTK_WINDOW(window),GTK_WIN_POS_CENTER_ALWAYS);

	//destroy-event
	g_signal_connect( G_OBJECT(window), "destroy",G_CALLBACK(gtk_main_quit), NULL);

	gtk_window_set_decorated(GTK_WINDOW(window), FALSE); /* hide the title bar and the boder */
	gtk_container_set_border_width(GTK_CONTAINER(window), 0);
}

void create_close_button() {
	// close button
	closebtn_pixbuf[0] = gdk_pixbuf_new_from_file_at_scale(CLOSEBTN_DEFAULT_PNG, 32, 32, FALSE, NULL);

	closebtn_pixbuf[1] = gdk_pixbuf_new_from_file_at_scale(CLOSEBTN_ENTERED_PNG, 32, 32, FALSE, NULL);

	closebtn = gtk_image_new_from_pixbuf(closebtn_pixbuf[0]);

	closebtn_event_box = gtk_event_box_new();
	gtk_container_add(GTK_CONTAINER(closebtn_event_box), closebtn);

	gtk_fixed_put(GTK_FIXED(fixed), closebtn_event_box, win_width, 0);
	gtk_widget_show(closebtn_event_box);
	gtk_widget_show(closebtn);
	gtk_event_box_set_visible_window((GtkEventBox*)closebtn_event_box, FALSE);

	g_signal_connect(G_OBJECT(closebtn_event_box), "button-press-event", G_CALLBACK(close_handler), NULL);
	g_signal_connect(G_OBJECT(closebtn_event_box), "enter-notify-event", G_CALLBACK(closebtn_enter_handler), NULL);
	g_signal_connect(G_OBJECT(closebtn_event_box), "leave-notify-event", G_CALLBACK(closebtn_leave_handler), NULL);
}

void create_fixed_widget() {
	// fixed
	fixed = gtk_fixed_new();
	gtk_container_add(GTK_CONTAINER(window), fixed);
	gtk_widget_show(fixed);
	gtk_container_set_border_width(GTK_CONTAINER(fixed), 0);
}

void create_window_background() {
	GtkWidget* background = gtk_image_new_from_file_at_scale( BACKGROUND_PNG, win_width + 32, win_height);
	gtk_fixed_put(GTK_FIXED(fixed), background, 0, 0);
	gtk_widget_show(background);
}

void create_highlight_widget() {
	if(0==access("/tmp/computer.mode",F_OK))
		mode_chosen=0;
	else if (0==access("/tmp/duplicate.mode",F_OK))
		mode_chosen=1;
	else if (0==access("/tmp/extension.mode",F_OK))
		mode_chosen=2;
	else if (0==access("/tmp/projector.mode",F_OK))
		mode_chosen=3;
	else
		;
	printf ("mode_chosen:%d\n", mode_chosen);
	frame = gtk_image_new_from_file_at_scale( FRAME_PNG, win_height,  win_height);
	gtk_fixed_put(GTK_FIXED(fixed), frame, frame_pos[mode_chosen], 0);
	gtk_widget_show(frame);
}

void create_horizontal_box() {
	// icon container - horizontal_box
	horizontal_box = gtk_hbox_new(TRUE, 0);
	gtk_container_set_border_width(GTK_CONTAINER(horizontal_box), 0);
	//gtk_container_add( GTK_CONTAINER(window), horizontal_box);
	gtk_container_add(GTK_CONTAINER(fixed), horizontal_box);
	gtk_widget_show(horizontal_box);
}

void create_main_buttons() {
	char* paths[4] = { COMPUTER_PNG, DUPLICATE_PNG, EXTENSION_PNG, PROJECTER_PNG };
	int i = 0;

	for ( i = 0; i < 4; i++ ) {
		image[i] = gtk_image_new_from_file_at_scale( paths[i], win_height * 2 / 3, win_height * 2 / 3);
		gtk_widget_set_size_request( image[i], win_height, win_height );

		event_box[i] = gtk_event_box_new();
		gtk_container_add(GTK_CONTAINER(event_box[i]), image[i]);

		gtk_container_add(GTK_CONTAINER(horizontal_box), event_box[i]);
		gtk_widget_show(image[i]);
		gtk_widget_show(event_box[i]);
		gtk_event_box_set_visible_window((GtkEventBox*)event_box[i], FALSE);

		g_signal_connect(G_OBJECT(event_box[i]), "button-press-event", G_CALLBACK(press_handler), (gpointer)i);
	}
}

void create_user_interface() {
	create_main_window();
	create_fixed_widget();
	create_window_background();
	create_highlight_widget();
	create_close_button();
	create_horizontal_box();
	create_main_buttons();
}


void process_exist()
{
	if(0==access("/tmp/myp_exist",F_OK))
		exit(0);
	else
		system("touch /tmp/myp_exist");    
}

int main(int argc, char* argv[])
{
	init(argc, argv);
	process_exist(); 
	system("gxrandr-switch-mode.sh get");
	create_user_interface();
	gtk_widget_show(window);

	g_signal_connect(G_OBJECT(window), "key-press-event", G_CALLBACK(key_value), NULL);

	gtk_window_set_skip_taskbar_hint(GTK_WINDOW(window),TRUE);

	g_signal_connect(G_OBJECT(window), "destroy", G_CALLBACK(close_handler), NULL);


	gtk_main();

	return 0;
}
