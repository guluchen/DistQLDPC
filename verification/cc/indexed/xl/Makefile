NAME := xl
PREFIX := CCXL
WIDTH := 1512
EXTRACT := XlExtract
ML_MODULE := Xl_generated
IMPORTED_STAMP := ../large/proof.stamp
ROW_ADVICE_LIMIT := $(WIDTH)
ADVICE_FLAGS := -DCCV_ADVICE_WIDTH=$(WIDTH)
include ../certifier.mk

CCXLWords.v: ../large/CCLargeWords.v
	sed 's/CCWide/CCLarge/g;s/756/1512/g;s/378/756/g;s/left_half/xl_low/g;s/right_half/xl_high/g' $< > $@

CCXL%.v: ../large/CCLarge%.v
	sed 's/CCLarge/CCXL/g;s/756/1512/g' $< > $@

XlExtract.v: ../large/LargeExtract.v
	sed 's/CCLarge/CCXL/g;s/large_generated/xl_generated/g' $< > $@

xl_driver.inc.ml: ../large/large_driver.inc.ml
	sed 's/Large_advice/Xl_advice/g;s/pcm-large/pcm-xl/g;s/756/1512/g' $< > $@

xl_advice.ml: ../large/large_advice.ml generate_advice.py
	python3 -B generate_advice.py $< $@

clean: clean-inputs
.PHONY: clean-inputs
clean-inputs:
	$(RM) $(HAND_PROOFS) XlExtract.v xl_advice.ml xl_driver.inc.ml
