# Each width uses a separate extraction directory and shares the checked PCM parser.
PARENT := $(abspath ../..)
CCV_BASE_PROOF ?= $(PARENT)/proof
COQFLAGS := -Q "$(CCV_BASE_PROOF)" CCV
ifneq ($(VST_ROOT),)
COQFLAGS += $(foreach pkg,msl sepcomp veric floyd zlist,-Q "$(VST_ROOT)/$(pkg)" VST.$(pkg)) -R "$(VST_ROOT)/compcert" compcert
endif
COQ_OCAML_ROOT ?= $(shell ocamlfind query coq-core)
CFLAGS ?= -std=c99 -O3 -Wall -Wextra -Werror -Wconversion -pedantic
LIBS := -I "$(COQ_OCAML_ROOT)/kernel" -I "$(COQ_OCAML_ROOT)/vm" -I . -I "$(COQ_OCAML_ROOT)/clib" "$(COQ_OCAML_ROOT)/clib/clib.cmxa" "$(COQ_OCAML_ROOT)/kernel/kernel.cmxa" -cclib -lcoqrun_stubs
GENERATED_TAGS := Branch Refute Roots Layout Index Short Orbit Dual
TAGS := Words $(GENERATED_TAGS) Half Cached Answer
MODULES := $(addprefix $(PREFIX),$(TAGS))
PARENT_SRC := $(foreach t,$(GENERATED_TAGS),$(PARENT)/proof/CCPacked$(t).v)
HAND_PROOFS := $(addprefix $(PREFIX),Words.v Cached.v Half.v Answer.v)
.NOTPARALLEL:
.PHONY: all proof clean
all: pcm-$(NAME)
proof: proof.stamp
	coqchk $(COQFLAGS) $(foreach module,$(MODULES),-norec $(module))

proof.stamp: ../wide/instantiate.py $(HAND_PROOFS) $(PARENT_SRC) $(IMPORTED_STAMP) ../CCShortSound.vo
	cp ../CCShortSound.vo .
	$(if $(IMPORTED_STAMP),cp ../wide/CCWide*.vo .,true)
	python3 -B ../wide/instantiate.py "$(PARENT)/proof" . $(PREFIX) $(WIDTH)
	set -e; for module in $(MODULES); do coqc $(COQFLAGS) "$$module.v"; done
	touch $@

$(NAME)_generated.ml: proof.stamp $(EXTRACT).v ../CCCompactPrepare.vo
	cp ../CCCompactPrepare.vo .
	coqc $(COQFLAGS) $(EXTRACT).v

$(NAME)_driver.ml: ../pcm_proved.ml $(NAME)_driver.inc.ml
	sed '/^let distance () =/,$$d;s/open Pcm_generated/open $(ML_MODULE)/' $< > $@
	cat $(NAME)_driver.inc.ml >> $@

dual_advice.ml: ../dual_advice.ml
	cp $< $@

row_advice.ml: ../row_advice.ml
	cp $< $@

pcm-$(NAME): row_advice.ml ../row_order.c $(NAME)_generated.ml $(NAME)_driver.ml dual_advice.ml $(NAME)_advice.ml $(NAME)_hint.c ../../ccv.c ../../ccv_primitives.c ../../extract/pcm_stubs.c
	ocamlopt -ccopt "$(CFLAGS)" -o $@ $(LIBS) $(NAME)_generated.mli $(NAME)_generated.ml dual_advice.ml row_advice.ml $(NAME)_advice.ml $(NAME)_driver.ml $(NAME)_hint.c ../row_order.c ../../extract/pcm_stubs.c ../../ccv.c ../../ccv_primitives.c

clean:
	$(RM) $(addsuffix .v,$(addprefix $(PREFIX),$(GENERATED_TAGS))) *.vo* *.glob .*.aux *.o *.cm[iox] $(NAME)_generated.ml $(NAME)_generated.mli $(NAME)_driver.ml dual_advice.ml row_advice.ml pcm-$(NAME) proof.stamp
