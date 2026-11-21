NAME := small
PREFIX := CCSmall
WIDTH := 189
EXTRACT := SmallExtract
ML_MODULE := Small_generated
include ../certifier.mk

CCSmallWords.v: $(PARENT)/proof/CCPackedWords.v outside.inc.v
	cat $^ > $@

CCSmall%.v: ../wide/CCWide%.v
	sed 's/CCWide/CCSmall/g;s/378/189/g' $< > $@

SmallExtract.v: ../wide/WideExtract.v
	sed 's/CCWide/CCSmall/g;s/wide_generated/small_generated/g' $< > $@

small_driver.inc.ml: ../wide/wide_driver.inc.ml
	sed 's/Wide_advice/Small_advice/g;s/pcm-wide/pcm-small/g;s/378/189/g' $< > $@

small_advice.ml: ../wide/wide_advice.ml generate_advice.py
	python3 -B generate_advice.py $< $@

clean: clean-inputs
.PHONY: clean-inputs
clean-inputs:
	$(RM) $(HAND_PROOFS) SmallExtract.v small_advice.ml small_driver.inc.ml
