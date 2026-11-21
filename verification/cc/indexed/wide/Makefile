NAME := wide
PREFIX := CCWide
WIDTH := 378
EXTRACT := WideExtract
ML_MODULE := Wide_generated
include ../certifier.mk

.PHONY: pair-controls
pair-controls: proof.stamp
	coqc $(COQFLAGS) PairControls.v

.PHONY: double-controls
double-controls: pcm-wide test_double.ml
	ocamlopt -ccopt "$(CFLAGS)" -o double-controls-test $(LIBS) wide_generated.cmx dual_advice.cmx row_advice.cmx wide_advice.cmx test_double.ml wide_hint.c ../row_order.c ../line_hint.c ../dual_hint.c ../../extract/pcm_stubs.c ../../ccv.c ../../ccv_primitives.c
	./double-controls-test

clean: clean-double
.PHONY: clean-double
clean-double:
	$(RM) double-controls-test
