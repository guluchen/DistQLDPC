CC ?= cc
CFLAGS ?= -std=c99 -O2 -Wall -Wextra -Werror -Wconversion -pedantic
SOURCES := ccv.c ccv_primitives.c
MODULES := $(sort $(wildcard proof/*.v))
COQFLAGS := -Q proof CCV
ifneq ($(VST_ROOT),)
COQFLAGS += $(foreach pkg,msl sepcomp veric floyd zlist,-Q $(VST_ROOT)/$(pkg) VST.$(pkg)) -R $(VST_ROOT)/compcert compcert
endif

.PHONY: all test mutants proofs pcm check-ast clean
all: ccv libccv.so

ccv: ccv_cli.c $(SOURCES) ccv.h
	$(CC) $(CFLAGS) ccv_cli.c $(SOURCES) -o $@

libccv.so: $(SOURCES) ccv.h
	$(CC) $(CFLAGS) -fPIC -shared $(SOURCES) -o $@

test: all
	python3 -B tests/test_ccv.py ./libccv.so
	python3 -B tests/test_invalid_and_reuse.py

mutants:
	python3 -B tests/test_mutants.py

proofs:
	coq_makefile $(COQFLAGS) $(MODULES) -o Makefile.coq
	$(MAKE) -j1 -f Makefile.coq all

pcm: all
	coq_makefile $(COQFLAGS) $(MODULES) -o Makefile.coq
	$(MAKE) -j1 -f Makefile.coq proof/CCPCMAnswer.vo proof/CCPCMBitRows.vo
	coqc $(COQFLAGS) extract/PCMExtract.v
	ocamlopt -ccopt "$(CFLAGS)" -I . -o pcm-prepare pcm_generated.mli pcm_generated.ml extract/pcm_prepare.ml extract/pcm_stubs.c $(SOURCES)

check-ast:
	sha256sum --check source-ast.sha256

clean:
	$(RM) ccv libccv.so mutant-*.so mutant-*.log pcm-prepare pcm_stubs.o ccv.o ccv_primitives.o pcm_generated.* extract/*.cm[iox] extract/*.o extract/*.vo* extract/*.glob extract/.*.aux
	$(if $(wildcard Makefile.coq),$(MAKE) -f Makefile.coq clean)
	$(RM) Makefile.coq Makefile.coq.conf .Makefile.coq.d
