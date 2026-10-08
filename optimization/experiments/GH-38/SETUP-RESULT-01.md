# Attempt01: engineering INCONCLUSIVE, no scientific test

Executed support05bf25500de9a8fcb1dbbb7f63efcdcb0fdbc2bd,
driver SHA256f04c9140bbd9322a86ab2ee89155caa6d22fe1d4e0585ef746b4c1f4b1fee9d5,
assignment6066796343/session58495/exit0. Production candidateb8ddb902 remains
isolated and unadopted. All27 setup/minimal-probe commands rc0. All9 archives
match pinned SHA512/size; original10,216 files unchanged and byte-identical in
the overlay. All85 resource checks eligible, min global idle81.201923%, min half
spare6.496154 logical CPUs;9 contention alerts retained. Single CPU mask64,
all4 settings restored, owned=[] and independent post-exit runner lookup absent.
Windows released6066880356 with process-check correction6066891028.

Actual GCC14.4.0/Clang22.1.8, default C++17/x86-64/Cygwin and selected ISA macros
agree. Minimal printed ABI/vector/zlib output identical. Traces select original
GCC14 GNU standard-library headers;98 GCC/112 Clang actual header paths mapped.
All non-Clang-resource headers and used GNU archives are original bytes. Clang
resource headers are separately disclosed, not claimed byte-identical to GCC.
Every actually loaded cyg DLL is an original byte-identical file; loaded sets
differ because Clang optimized away the minimal vector's allocation/runtime
dependencies. Set difference alone is not a scientific mismatch.

The actual default link recipe fails the preregistered comparability gate:
GCC embeds original default-manifest.o (.rsrc with asInvoker/supportedOS XML,
manifest SHA256eba2c9713517c971783fd9ea9282ff53e0e1a13d9ae462bc0b00106049765344);
Clang default link embeds no manifest and chooses a different existing GNU
library recipe. BOTH actual PE DLLCharacteristics are0x8000: high-entropy ASLR,
dynamic base and NX already disabled in the original GNU configuration.
Clang's explicit disable argv does NOT imply those effective bits differ.
No solver/Tier0 or performance run, no speed or correctness claim. Decision:
INCONCLUSIVE / default-driver comparison not established; NOT ADOPTED.

Two audit corrections are retained explicitly. Initial sandbox CIM returned
AccessDenied, but PowerShell continued and produced invalid absence metadata;
POST-EXIT-INVALID-UNVERIFIED.json is invalid. The successful approved read and
correction are in POST-EXIT.json. Initial draft audit incorrectly inferred PE
bit inequality from argv despite its own numeric values showing equality;
AUDIT-DRAFT-INVALID-PE-INFERENCE.json is invalid. Corrected independent audit
supersedes that interpretation. Original command/stdout/stderr streams unchanged.

Next: prerecord a supporting comparability correction for the SAME fixed Clang
codegen concept: compile candidate objects with Clang, link both configurations
with original GCC14 GNU driver/flags/libraries/manifest. Retain failed default
candidate and all attempt01 evidence. No arbitrary linker/security/numeric
flags or semantic source changes, no automatic scientific/performance work.
