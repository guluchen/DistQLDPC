NAME := wide
PREFIX := CCWide
WIDTH := 378
EXTRACT := WideExtract
ML_MODULE := Wide_generated
include ../certifier.mk

.PHONY: pair-controls
pair-controls: proof.stamp
	coqc $(COQFLAGS) PairControls.v
