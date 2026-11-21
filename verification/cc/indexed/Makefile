CC ?= cc
CFLAGS ?= -std=c99 -O3 -Wall -Wextra -Werror -Wconversion -pedantic
PARENT := $(abspath ..)
BASE := $(PARENT)/extract
CCV_BASE_PROOF ?= $(PARENT)/proof
COQFLAGS := -Q "$(CCV_BASE_PROOF)" CCV
ifneq ($(VST_ROOT),)
COQFLAGS += $(foreach pkg,msl sepcomp veric floyd zlist,-Q "$(VST_ROOT)/$(pkg)" VST.$(pkg)) -R "$(VST_ROOT)/compcert" compcert
endif
COQ_OCAML_ROOT ?= $(shell ocamlfind query coq-core)
LIBS = -I "$(COQ_OCAML_ROOT)/kernel" -I "$(COQ_OCAML_ROOT)/vm" -I . -I "$(COQ_OCAML_ROOT)/clib" "$(COQ_OCAML_ROOT)/clib/clib.cmxa" "$(COQ_OCAML_ROOT)/kernel/kernel.cmxa" -cclib -lcoqrun_stubs
INDEX := ccv_indexed.c ccv_sparse.c ccv_flip.c
HEADERS := sparse_search.h orbit.h short.h redundant.h ../ccv.h ../ccv.c
PROOFS := CCCompactPrepare CCRawDual CCBoundReplay CCShortSound CCTieMinimum VerifSparseGather VerifSparseFlip
ML_INPUTS := pcm_generated.mli pcm_generated.ml packed_advice.ml dual_advice.ml
C_STUBS := $(BASE)/packed_hint.c $(BASE)/pcm_stubs.c ../ccv_primitives.c
.PHONY: all proof test cli base-proof check-ast clean
.NOTPARALLEL:

all: pcm-indexed pcm-proved pcm-check pcm-wide pcm-large pcm-upper
cli: ccv-indexed libccv-indexed.so

ccv-indexed: $(INDEX) $(HEADERS) ../ccv_cli.c ../ccv_primitives.c
	$(CC) $(CFLAGS) ../ccv_cli.c $(INDEX) ../ccv_primitives.c -o $@

libccv-indexed.so: $(INDEX) $(HEADERS) ../ccv_primitives.c
	$(CC) $(CFLAGS) -fPIC -shared $(INDEX) ../ccv_primitives.c -o $@

base-proof:
ifeq ($(CCV_BASE_PROOF),$(PARENT)/proof)
	$(MAKE) -C .. proofs
else
	test -f "$(CCV_BASE_PROOF)/CCPackedAnswer.vo"
endif

CCCompactPrepare.vo CCShortSound.vo CCTieMinimum.vo: | base-proof
CCRawDual.vo: CCCompactPrepare.vo
CCBoundReplay.vo: CCRawDual.vo
VerifSparseGather.vo: gather_ast.vo
VerifSparseFlip.vo: flip_ast.vo
%.vo: %.v
	coqc $(COQFLAGS) $<

check-ast:
	sha256sum --check source-ast.sha256

proof: check-ast $(addsuffix .vo,$(PROOFS))
	coqchk $(COQFLAGS) $(foreach module,$(PROOFS),-norec $(module))
	$(MAKE) -C wide proof
	$(MAKE) -C large proof

# Coq extraction writes both ML files as a side effect.
pcm_generated.ml: DualExtract.v CCCompactPrepare.vo CCRawDual.vo CCBoundReplay.vo
	coqc $(COQFLAGS) $<
pcm_generated.mli: pcm_generated.ml
	@test -f $@ || coqc $(COQFLAGS) DualExtract.v

pcm_%.ml: %-driver.patch $(BASE)/pcm_prepare.ml
	patch -s -o $@ $(BASE)/pcm_prepare.ml < $<

packed_advice.ml: $(BASE)/packed_advice.ml
	cp $< $@

pcm-indexed: $(ML_INPUTS) pcm_indexed.ml $(C_STUBS) $(INDEX) $(HEADERS)
	ocamlopt -ccopt "$(CFLAGS)" -o $@ $(LIBS) $(ML_INPUTS) pcm_indexed.ml $(C_STUBS) $(INDEX)
pcm-proved: $(ML_INPUTS) pcm_proved.ml $(C_STUBS) ../ccv.c ../ccv.h
	ocamlopt -ccopt "$(CFLAGS)" -o $@ $(LIBS) $(ML_INPUTS) pcm_proved.ml $(C_STUBS) ../ccv.c

dual-test: $(ML_INPUTS) test_dual.ml
	ocamlopt -o $@ $(LIBS) pcm_generated.mli pcm_generated.ml dual_advice.ml test_dual.ml

rule-probes.so: tests/rule_probes.c $(INDEX) $(HEADERS) ../ccv_primitives.c
	$(CC) $(CFLAGS) -fPIC -shared $< ccv_sparse.c ccv_flip.c ../ccv_primitives.c -o $@

test: all cli dual-test rule-probes.so
	python3 -B ../tests/test_ccv.py ./libccv-indexed.so
	./dual-test
	python3 -B tests/test_rules.py ./rule-probes.so
	python3 -B tests/test_replay.py
	python3 -B tests/test_wide.py

clean:
	$(MAKE) -C wide clean
	$(MAKE) -C large clean
	$(RM) replay_stubs.c replay_driver.ml pcm-check pcm-wide pcm-large pcm-upper *.o *.cm[iox] *.vo* *.glob .*.aux pcm_generated.ml pcm_generated.mli pcm_indexed.ml pcm_proved.ml packed_advice.ml pcm-indexed pcm-proved ccv-indexed libccv-indexed.so dual-test rule-probes.so

replay_stubs.c: replay-stubs.patch $(BASE)/pcm_stubs.c
	patch -s -o $@ $(BASE)/pcm_stubs.c < $<

replay_driver.ml: pcm_proved.ml replay_driver.inc.ml
	sed '/^let distance () =/,$$d' $< > $@
	cat replay_driver.inc.ml >> $@

pcm-check: $(ML_INPUTS) replay_driver.ml replay_stubs.c $(C_STUBS) ../ccv.c ../ccv.h
	ocamlopt -ccopt "$(CFLAGS)" -o $@ $(LIBS) $(ML_INPUTS) replay_driver.ml $(C_STUBS) replay_stubs.c ../ccv.c

WIDE_SOURCES := certifier.mk $(wildcard wide/*.inc.ml) $(wildcard wide/CCWide*.v) wide/WideExtract.v wide/instantiate.py wide/Makefile wide/wide_hint.c wide/wide_advice.ml $(wildcard ../proof/CCPacked*.v)
pcm-wide: $(WIDE_SOURCES) CCCompactPrepare.vo CCRawDual.vo pcm_proved.ml
	$(MAKE) -C wide all
	cp wide/pcm-wide $@

pcm-upper: upper.c
	$(CC) $(CFLAGS) $< -o $@

LARGE_SOURCES := certifier.mk $(wildcard large/*.inc.ml) $(wildcard large/CCLarge*.v) large/LargeExtract.v large/Makefile large/large_hint.c large/large_advice.ml
pcm-large: $(LARGE_SOURCES) pcm-wide
	$(MAKE) -C large all
	cp large/pcm-large $@
