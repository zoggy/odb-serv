#

INCLUDES=
COMPFLAGS=$(INCLUDES) -annot
OCAMLPP=

OCAMLC=ocamlc -g
OCAMLOPT=ocamlopt
OCAMLLEX=ocamllex
OCAMLYACC=ocamlyacc
CAMLP4O=camlp4o
OCAMLLIB:=`$(OCAMLC) -where`

ADDITIONAL_LIBS=str.cmxa
ADDITIONAL_LIBS_BYTE=str.cma

INSTALLDIR=$(OCAMLLIB)/odb-server

RM=rm -f
CP=cp -f
MKDIR=mkdir -p

SYSLIBS=unix.cmxa dynlink.cmxa
SYSLIBS_BYTE=unix.cma dynlink.cma

LIB_CMXFILES=odb_config.cmx \
	odb_misc.cmx \
	odb_commands.cmx \
	odb_comm.cmx \
	odb_tools.cmx \
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

all: opt byte

opt: $(LIB) $(SERVER) $(CLIENT)
byte: $(LIB_BYTE) $(SERVER_BYTE) $(CLIENT_BYTE)

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

##########
install:
	$(MKDIR) $(INSTALLDIR)
	$(CP) $(LIB_CMIFILES) $(LIB) $(LIB_BYTE) $(LIB:.cmxa=.a) \
	`ls $(SERVER_CMIFILES) | grep -v server.cmi` $(INSTALLDIR)
	$(CP) $(SERVER) $(CLIENT)  `dirname \`which $(OCAMLC)\``/

#####
clean:
	$(RM) $(SERVER) $(SERVER_BYTE) $(CLIENT) $(CLIENT_BYTE) *.cm* *.o *.a *.x *.annot

#############
.SUFFIXES: .mli .ml .cmi .cmo .cmx .mll .mly

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

.PHONY: clean depend

.depend depend:
	ocamldep -pp $(CAMLP4O) *.ml > .depend

include .depend