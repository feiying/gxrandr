CC = gcc

CFLAGS = -Wall -Wunused                 \
        -DG_DISABLE_DEPRECATED          \
        -DGDK_DISABLE_DEPRECATED        \
        -DGDK_PIXBUF_DISABLE_DEPRECATED \
        -DGTK_DISABLE_DEPRECATED

all:gxrandr

gxrandr: gxrandr.o utility.o
	$(CC) -g -o gxrandr gxrandr.o utility.o `pkg-config --libs gtk+-2.0`

gxrandr.o: src/gxrandr.c src/gxrandr.h
	$(CC) -g -c -o gxrandr.o src/gxrandr.c `pkg-config --cflags gtk+-2.0`


utility.o: src/utility.c src/utility.h
	$(CC) -g -c -o utility.o src/utility.c

clean: 
	rm -f *.o

distclean:
	rm -f *.o gxrandr

dist:
	rm -f /tmp/gxrandr-2.3-tar.gz
	tar -czvf /tmp/gxrandr-2.3.tar.gz ../gxrandr-2.3/
	mv /tmp/gxrandr-2.3.tar.gz .

install: gxrandr
	rm -rf $(DESTDIR)/usr/share/gxrandr/images/
	install -d $(DESTDIR)/usr/bin/
	install -d $(DESTDIR)/usr/share/gxrandr/images/
	install -d $(DESTDIR)/usr/share/applications/
	cp -f gxrandr $(DESTDIR)/usr/bin/
	cp -f src/project-daemon.sh $(DESTDIR)/usr/bin/
	cp share/*.png $(DESTDIR)/usr/share/gxrandr/images/
	cp share/icon.png $(DESTDIR)/usr/share/gxrandr/
	#cp share/*.desktop $(DESTDIR)/usr/share/applications/
	
uninstall:
	rm -f $(DESTDIR)/usr/bin/gxrandr
	rm -f $(DESTDIR)/usr/bin/project_daemon.sh
	rm -rf $(DESTDIR)/usr/share/gxrandr
	rm -f $(DESTDIR)/usr/share/applications/gxrandr*.desktop
