MKDIR=mkdir -p
CP=cp -fr
MYSITE=/opt/mysite/mysite
RSS2CONTENT=/opt/godi/bin/cduce -I /opt/mysite --run rss.cdo --arg

DEST_DIR=website/

PNGFILES=2servers.png \
	4servers.png

XMLFILES=site.xml
all: $(XMLFILES) $(PNGFILES)
	$(MKDIR) $(DEST_DIR)
	$(MYSITE) site.xml -lang fr -o $(DEST_DIR) #$(MYSITE) site.xml -lang en -o $(DEST_DIR)
	$(CP) style.css $(DEST_DIR)
	$(CP) *.png $(DEST_DIR)
	$(CP) img $(DEST_DIR)
	$(CP) $(DEST_DIR)/index.fr.html $(DEST_DIR)/index.html
	rpl "&amp;&amp;" "&&" $(DEST_DIR)/*.html

%.png: %.dot
	dot -Tpng -o $@ $<
%.png: %.dotc
	circo -Tpng -o $@ $<

clean:
	rm -fr $(DEST_DIR) $(PNGFILES)