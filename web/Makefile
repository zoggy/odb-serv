MKDIR=mkdir -p
CP=cp -fr
MYSITE=/opt/mysite/mysite
RSS2CONTENT=/opt/godi/bin/cduce -I /opt/mysite --run rss.cdo --arg

DEST_DIR=website/

PNGFILES=2servers.png \
	4servers.png

XMLFILES=site.xml

all: $(XMLFILES) $(PNGFILES) $(DEST_DIR)tool_doc.html
	$(MKDIR) $(DEST_DIR)
	$(MYSITE) site.xml -lang fr -o $(DEST_DIR) #$(MYSITE) site.xml -lang en -o $(DEST_DIR)
	$(CP) style.css $(DEST_DIR)
	$(CP) *.png $(DEST_DIR)
	$(CP) img $(DEST_DIR)
	$(CP) $(DEST_DIR)/index.fr.html $(DEST_DIR)/index.html
	rpl "&amp;&amp;" "&&" $(DEST_DIR)/*.html
	highlight -S ocaml ../plugins/ocamlwc.ml  > $(DEST_DIR)ocamlwc.html --inline-css -s bright
	(cd .. && make docdepgraph)
	$(CP) ../ocamldoc/* $(DEST_DIR)refdoc/

$(DEST_DIR)tool_doc.html: ../odb-server
	bash -c "(../odb-server &  sleep 1 ; ../odb-client \"server: doc\" > $@ ; kill %1)"


%.png: %.dot
	dot -Tpng -o $@ $<
%.png: %.dotc
	circo -Tpng -o $@ $<

clean:
	rm -fr $(DEST_DIR) $(PNGFILES)