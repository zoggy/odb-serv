#

INCLUDES=
COMPFLAGS=$(INCLUDES) -annot
OCAMLPP=

OCAMLC=ocamlc
OCAMLOPT=ocamlopt
OCAMLLEX=ocamllex
OCAMLYACC=ocamlyacc
CAMLP4O=camlp4o
RM=rm -f

SYSLIBS=unix.cmxa dynlink.cmxa
SYSLIBS_BYTE=unix.cma dynlink.cma

LIB_CMXFILES=config.cmx \
	misc.cmx \
	commands.cmx \
	comm.cmx

LIB_CMOFILES=$(LIB_CMXFILES:.cmx=.cmo)
LIB_CMIFILES=$(LIB_CMXFILES:.cmx=.cmi)

LIB=odb.cmxa
LIB_BYTE=$(LIB:.cmxa=.cma)

SERVER_CMXFILES=\
	tools.cmx \
	server.cmx

SERVER_CMOFILES=$(SERVER_CMXFILES:.cmx=.cmo)
SERVER_CMIFILES=$(SERVER_CMXFILES:.cmx=.cmi)

SERVER=odb-server
SERVER_BYTE=$(SERVER).byte

all: opt byte

opt: $(LIB) $(SERVER)
byte: $(LIB_BYTE) $(SERVER_BYTE)

$(SERVER): $(LIB) $(SERVER_CMIFILES) $(SERVER_CMXFILES)
	$(OCAMLOPT) -o $@ $(COMPFLAGS) $(SYSLIBS) $(LIB) $(SERVER_CMXFILES)

$(SERVER_BYTE): $(LIB_BYTE) $(SERVER_CMIFILES) $(SERVER_CMOFILES)
	$(OCAMLC) -o $@ $(COMPFLAGS) $(SYSLIBS_BYTE) $(LIB_BYTE) $(SERVER_CMOFILES)

$(LIB): $(LIB_CMIFILES) $(LIB_CMXFILES)
	$(OCAMLOPT) -a -o $@ $(LIB_CMXFILES)


$(LIB_BYTE): $(LIB_CMIFILES) $(LIB_CMOFILES)
	$(OCAMLC) -a -o $@ $(LIB_CMOFILES)

#####
clean:
	$(RM) $(SERVER) $(SERVER_BYTE) *.cm* *.o *.a *.x *.annot

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

commands.cmo: commands.ml
	$(OCAMLC) $(COMPFLAGS) -c -pp "$(CAMLP4O)" $<
commands.cmx: commands.ml
	$(OCAMLOPT) $(COMPFLAGS) -c -pp "$(CAMLP4O)" $<

.PHONY: clean depend

.depend depend:
	ocamldep -pp $(CAMLP4O) *.ml > .depend

include .depend