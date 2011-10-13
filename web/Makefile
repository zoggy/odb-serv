#################################################################################
#                Odb-server                                                     #
#                                                                               #
#    Copyright (C) 2011 Institut National de Recherche en Informatique          #
#    et en Automatique. All rights reserved.                                    #
#                                                                               #
#    This program is free software; you can redistribute it and/or modify       #
#    it under the terms of the GNU General Public License as                    #
#    published by the Free Software Foundation; either version 2 of the         #
#    License.                                                                   #
#                                                                               #
#    This program is distributed in the hope that it will be useful,            #
#    but WITHOUT ANY WARRANTY; without even the implied warranty of             #
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              #
#    GNU Library General Public License for more details.                       #
#                                                                               #
#    You should have received a copy of the GNU General Public                  #
#    License along with this program; if not, write to the Free Software        #
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                   #
#    02111-1307  USA                                                            #
#                                                                               #
#    As a special exception, you have permission to link this program           #
#    with the OCaml compiler and distribute executables, as long as you         #
#    follow the requirements of the GNU GPL in regard to all of the             #
#    software in the executable aside from the OCaml compiler.                  #
#                                                                               #
#    Contact: Maxence.Guesdon@inria.fr                                          #
#                                                                               #
#################################################################################

MKDIR=mkdir -p
CP=cp -fr
MYSITE=/opt/mysite/mysite
RSS2CONTENT=/opt/godi/bin/cduce -I /opt/mysite --run rss.cdo --arg

DEST_DIR=website/
REMOTE_DIR=zoggy@odb-serv.forge.ocamlcore.org:/home/groups/odb-serv/htdocs/

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
	$(CP) ../project.odb $(DEST_DIR)project.txt


$(DEST_DIR)tool_doc.html: ../odb-server
	bash -c "(../odb-server &  sleep 1 ; ../odb-client \"server: doc\" > $@ ; kill %1)"


%.png: %.dot
	dot -Tpng -o $@ $<
%.png: %.dotc
	circo -Tpng -o $@ $<

clean:
	rm -fr $(DEST_DIR) $(PNGFILES)

install:
	scp -r $(DEST_DIR)* $(REMOTE_DIR)