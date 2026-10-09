# GH63 actual Windows targeted gate

Corrected DistQLDPC/QDistSAT baseline source72d1fe18ccd91d061d0c6f1d9816d1c96ed685c7;
candidate38782bb2286667c57b1d1bc1e6f76c9f4302defa, exactly the registered
size-two computeLBD specialization. This is a downstream experiment, not a
claim about unchanged upstream MaxCDCL.

Prerecord issue63 comment6073392846; named Windows assignment6073411783,
released6073442449 after actual zero exit. Original Make/GNU14.4/Cygwin/O3
serial fresh build; actual distinct baseline objects are from independently
audited B002 targeted02. Original Main retains the disclosed test-only Cygwin
peak-memory statistic shim; no solver or scientific semantics changed by it.

Actual standalone results: all11 independent WCNF cases PASS, original valid
300-byte crash regression first at optimum5; partition80+1 PASS; actual-method
LBD whole-state fixture41,472 calls PASS including unsigned stamp wrap. No
wrong result or crash. Owned Jobs empty and all four setting restores pass;
source, support, actual objects/executables and runtime identity checks pass.
Independent whole-raw audit PASS_TARGETED_STANDALONE_ONLY verifies all133 raw
payloads,102 package files,15 support files and259 protected actual identities,
including four fresh engine objects and three actual executables. Python2563
and Cygwin10216 sets agree before/after/current; all26 commands finish naturally.
Audit SHA256b7698c4a8f01815acc14e2a371d39e86ba9cdac9ad6b01ee79b60275d50eb5e3.

Eight actual production Solver.o objdump commands preserve headers, bytes,
relocations and disassembly for both versions. All CODE sections are included;
the parser rejects an unrecognized CODE header as engineering INCONCLUSIVE.
Actual CODE/relocations differ in .text and newAuxiVarForCardinality COMDAT.
Independent actual-callsite review observes the size-two path's two direct
literal/stamp bodies instead of the generic loop backedge at two production
vec callers. The compiler also outlines a helper and adds call/return/dispatch
cost; .text grows145280 to146432 bytes (+1152). The auxiliary COMDAT difference
is a relocated call operand/layout effect. These are actual mechanism evidence,
not a hotness or net speedup conclusion. Static review
SHA2567f615cc7037164df2d5eace8166c29ea9e56731b844b3a7116dce0cfe4bbc8f3.

Package SHA2560934a01b9fdd7dedb130b59023b41e3ef6a8e4fe6e5de5019b6c85f32c822c28;
supportde55603038c3da433c90f6d7a469da128808167ee4a3d8f235b5033ca99c45e0;
raw cataloguea627dc352e41808bd39c8bfb014faae0a12191e09e7cd59ff6d276c44bc5d896;
independent source reviewda9756fb89387c8cdedb8ff810c23d3115cc2675799d07b8c475af1e7bb3ed48.
Full immutable raw/runtime/object evidence remains private locally.

Status TARGETED_PASS_NOT_FULL_TIER0. Full application correctness, hosted
artifact provenance, useful production mechanism review and separately
prerecorded baseline opportunity census remain mandatory before timing.
Tier1/2/3 NOT_RUN; performance NOT_MEASURED; no optimization acceptance.
No paper-derived method: general program optimization; bibliography N/A.
