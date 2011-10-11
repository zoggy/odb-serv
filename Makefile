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

#

INCLUDES=-I +threads
COMPFLAGS=$(INCLUDES) -annot -thread
OCAMLPP=

OCAMLC=ocamlc -g
OCAMLOPT=ocamlopt -g
OCAMLLEX=ocamllex
OCAMLYACC=ocamlyacc
OCAMLDOC=ocamldoc
OCAMLDOCOPT=ocamldoc.opt
CAMLP4O=camlp4o
OCAMLLIB:=`$(OCAMLC) -where`

ADDITIONAL_LIBS=
ADDITIONAL_LIBS_BYTE=

INSTALLDIR=$(OCAMLLIB)/odb-server

RM=rm -f
CP=cp -f
MKDIR=mkdir -p

SYSLIBS=unix.cmxa threads.cmxa dynlink.cmxa str.cmxa
SYSLIBS_BYTE=unix.cma threads.cma dynlink.cma str.cma

LIB_CMXFILES=odb_config.cmx \
	odb_misc.cmx \
	odb_file.cmx \
	odb_commands.cmx \
	odb_comm.cmx \
	odb_project_types.cmx \
	odb_project_parser.cmx \
	odb_project_lexer.cmx \
	odb_project.cmx \
	odb_client.cmx \
	odb_doc.cmx \
	odb_tools.cmx \
	odb_project_tool.cmx \
	odb_server.cmx

LIB_CMOFILES=$(LIB_CMXFILES:.cmx=.cmo)
LIB_CMIFILES=$(LIB_CMXFILES:.cmx=.cmi)

LIB=odb.cmxa
LIB_BYTE=$(LIB:.cmxa=.cma)

SERVER_CMXFILES=\
	server.cmx

SERVER_CMOFILES=$(SERVER_CMXFILES:.cmx=.cmo)
SERVER_CMIFILES=$(SERVER_CMXFILES:.cmx=.cmi)

SERVER=odb-server
SERVER_BYTE=$(SERVER).byte

CLIENT_CMXFILES=\
	client.cmx

CLIENT_CMOFILES=$(CLIENT_CMXFILES:.cmx=.cmo)
CLIENT_CMIFILES=$(CLIENT_CMXFILES:.cmx=.cmi)

CLIENT=odb-client
CLIENT_BYTE=odb-client.byte

PLUGINS=plugins/ocamlwc.cmxs
PLUGINS_BYTE=$(PLUGINS:.cmxs=.cmo)

all: opt byte plugins

opt: $(LIB) $(SERVER) $(CLIENT)
byte: $(LIB_BYTE) $(SERVER_BYTE) $(CLIENT_BYTE)
plugins: $(PLUGINS)

$(SERVER): $(LIB) $(SERVER_CMIFILES) $(SERVER_CMXFILES)
	$(OCAMLOPT) -verbose -linkall -o $@ $(COMPFLAGS) $(SYSLIBS) \
	$(ADDITIONAL_LIBS) $(LIB) $(SERVER_CMXFILES)

$(SERVER_BYTE): $(LIB_BYTE) $(SERVER_CMIFILES) $(SERVER_CMOFILES)
	$(OCAMLC) -linkall -o $@ $(COMPFLAGS) $(SYSLIBS_BYTE) \
	$(ADDITIONAL_LIBS_BYTE) $(LIB_BYTE) $(SERVER_CMOFILES)

$(CLIENT): $(LIB) $(CLIENT_CMIFILES) $(CLIENT_CMXFILES)
	$(OCAMLOPT) -o $@ $(COMPFLAGS) $(SYSLIBS) $(LIB) $(CLIENT_CMXFILES)

$(CLIENT_BYTE): $(LIB_BYTE) $(CLIENT_CMIFILES) $(CLIENT_CMOFILES)
	$(OCAMLC) -o $@ $(COMPFLAGS) $(SYSLIBS_BYTE) $(LIB_BYTE) $(CLIENT_CMOFILES)

$(LIB): $(LIB_CMIFILES) $(LIB_CMXFILES)
	$(OCAMLOPT) -a -o $@ $(LIB_CMXFILES)


$(LIB_BYTE): $(LIB_CMIFILES) $(LIB_CMOFILES)
	$(OCAMLC) -a -o $@ $(LIB_CMOFILES)

test-odb-project.x: $(LIB) test_odb_project.ml
	$(OCAMLOPT) $(COMPFLAGS) $(INCLUDES) -o $@ $(SYSLIBS) $^

test-parse-loc-mes.x: $(LIB) test_parse_loc_mes.ml
	$(OCAMLOPT) $(COMPFLAGS) $(INCLUDES) -o $@ $(SYSLIBS) $^

##########
install:
	$(MKDIR) $(INSTALLDIR)
	$(CP) $(LIB_CMIFILES) $(LIB) $(LIB_BYTE) $(LIB:.cmxa=.a) \
	`ls $(SERVER_CMIFILES) | grep -v server.cmi` $(INSTALLDIR)
	$(CP) $(SERVER) $(CLIENT)  `dirname \`which $(OCAMLC)\``/

####
oug:
	oug.x -o t.oug $(INCLUDES) -pp "$(CAMLP4O)" odb*.ml *.mli
####
	mkdir -p ocamldoc
	$(OCAMLDOCOPT) -t "Odb-server reference documentation" -d ocamldoc -html -load $<

dump.odoc: odb*.ml odb*.mli
	$(OCAMLDOCOPT) -rectypes -dump dump.odoc $(INCLUDES) -pp "$(CAMLP4O)" odb*.ml odb*.mli

docdepgraph: dump.odoc
	mkdir -p ocamldoc
	$(OCAMLDOCOPT) -t "Odb-server reference documentation" \
	-g odoc_depgraph.cmxs -width 700 -height 700 -d ocamldoc -load $<

#####
clean:
	$(RM) $(SERVER) $(SERVER_BYTE) $(CLIENT) $(CLIENT_BYTE) *.cm* *.o *.a *.x *.annot

# headers :
###########
HEADFILES= Makefile *.ml *.mli *.mly *.mll web/Makefile
headers:
	echo $(HEADFILES)
	headache -h header -c .headache_config `ls $(HEADFILES)`

noheaders:
	headache -r -c .headache_config `ls $(HEADFILES)`


#############
.SUFFIXES: .mli .ml .cmi .cmo .cmx .cmxs .mll .mly

%.cmi:%.mli
	$(OCAMLC) $(OCAMLPP) $(COMPFLAGS) -c $<

%.cmo:%.ml
	if test -f `dirname $<`/`basename $< .ml`.mli && test ! -f `dirname $<`/`basename $< .ml`.cmi ; then \
	$(OCAMLC) $(OCAMLPP) $(COMPFLAGS) -c `dirname $<`/`basename $< .ml`.mli; fi
	$(OCAMLC) $(OCAMLPP) $(COMPFLAGS) -c $<

%.cmi %.cmo:%.ml
	if test -f `dirname $<`/`basename $< .ml`.mli && test ! -f `dirname $<`/`basename $< .ml`.cmi ; then \
	$(OCAMLC) $(OCAMLPP) $(COMPFLAGS) -c `dirname $<`/`basename $< .ml`.mli; fi
	$(OCAMLC) $(OCAMLPP) $(COMPFLAGS) -c $<

%.cmx %.o:%.ml
	$(OCAMLOPT) $(OCAMLPP) $(COMPFLAGS) -c $<

%.cmxs: %.ml
	$(OCAMLOPT) -shared -o $@ $(OCAMLPP) $(COMPFLAGS) $<

%.o: %.c
	$(OCAMLOPT) $(COMPFLAGS) -c $< && $(MV) `basename $@` `dirname $@`

%.ml:%.mll
	$(OCAMLLEX) $<

%.mli %.ml:%.mly
	$(OCAMLYACC) -v $<

odb_commands.cmo: odb_commands.ml
	$(OCAMLC) $(COMPFLAGS) -c -pp "$(CAMLP4O)" $<
odb_commands.cmx: odb_commands.ml
	$(OCAMLOPT) $(COMPFLAGS) -c -pp "$(CAMLP4O)" $<

odb_project_parser.ml odb_project_parser.mli: odb_project_parser.mly
	$(OCAMLYACC) $<

odb_project_lexer.ml: odb_project_lexer.mll
	$(OCAMLLEX) $<

.PHONY: clean depend

.depend depend:
	ocamldep -pp $(CAMLP4O) *.ml > .depend

include .depend