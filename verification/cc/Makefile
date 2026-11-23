CC ?= cc
CFLAGS ?= -std=c99 -O2 -Wall -Wextra -Werror -Wconversion -pedantic
SOURCES := ccv.c ccv_primitives.c
COQ_OCAML_ROOT ?= $(shell ocamlfind query coq-core)
PACKED_LIBS = -I "$(COQ_OCAML_ROOT)/kernel" -I "$(COQ_OCAML_ROOT)/vm" -I . -I extract -I "$(COQ_OCAML_ROOT)/clib" "$(COQ_OCAML_ROOT)/clib/clib.cmxa" "$(COQ_OCAML_ROOT)/kernel/kernel.cmxa" -cclib -lcoqrun_stubs
PACKED_ML = pcm_generated.mli pcm_generated.ml extract/packed_advice.ml
MODULES := $(sort $(wildcard proof/*.v))
COQFLAGS := -Q proof CCV
ifneq ($(VST_ROOT),)
COQFLAGS += $(foreach pkg,msl sepcomp veric floyd zlist,-Q $(VST_ROOT)/$(pkg) VST.$(pkg)) -R $(VST_ROOT)/compcert compcert
endif

.PHONY: all test mutants proofs pcm test-packed test-portable-level check-ast check-shared-level clean
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
	$(MAKE) -j1 -f Makefile.coq proof/CCPackedAnswer.vo proof/CCPCMBitRows.vo
	coqc $(COQFLAGS) extract/PCMExtract.v
	ocamlopt -ccopt "$(CFLAGS)" -o pcm-prepare $(PACKED_LIBS) $(PACKED_ML) extract/pcm_prepare.ml extract/packed_hint.c extract/pcm_stubs.c $(SOURCES)

test-packed: pcm
	ocamlopt -ccopt "$(CFLAGS)" -o packed-oracle $(PACKED_LIBS) $(PACKED_ML) tests/packed_oracle.ml extract/packed_hint.c
	./packed-oracle

check-shared-level:
	python3 -B shared/check.py

test-portable-level: portable-level-test
	./portable-level-test

portable-level-test: shared/test_portable_level.c ../../src/cc/cc_level.c ../../src/cc/cc_level.h
	$(CC) $(CPPFLAGS) -std=c11 -O2 -Wall -Wextra -Werror -I../../src/cc shared/test_portable_level.c ../../src/cc/cc_level.c $(LDFLAGS) -o $@

check-ast:
	sha256sum --check source-ast.sha256

clean:
	$(RM) portable-level-test
	$(RM) ccv libccv.so mutant-*.so mutant-*.log pcm-prepare packed-oracle packed_hint.o tests/packed_oracle.cm[iox] tests/packed_oracle.o pcm_stubs.o ccv.o ccv_primitives.o pcm_generated.* extract/*.cm[iox] extract/*.o extract/*.vo* extract/*.glob extract/.*.aux
	$(if $(wildcard Makefile.coq),$(MAKE) -f Makefile.coq clean)
	$(RM) Makefile.coq Makefile.coq.conf .Makefile.coq.d
