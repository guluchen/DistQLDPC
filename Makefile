# QLDPC / CSS minimum-distance calculator (DistQLDPC)

SRC     = src
CORE    = $(SRC)/core
SOLVER  = $(SRC)/solver
CCDIR   = $(SRC)/cc
BUILD   = build
BIN     = bin/distqldpc
MAXCDCL = bin/maxcdcl

CXX     ?= g++
CXXFLAGS = -I$(SOLVER) -Wall -Wno-parentheses -O3 -g \
           -D __STDC_LIMIT_MACROS -D __STDC_FORMAT_MACROS -DNDEBUG
LDFLAGS  = -lz

ENGINE_OBJS = \
	$(BUILD)/SimpSolver.o \
	$(BUILD)/Solver.o \
	$(BUILD)/Options.o \
	$(BUILD)/System.o

# GH-124 (experimental): connected-cluster level-search engine (C++17), linked into bin/distqldpc
CC_OBJS = \
	$(BUILD)/cc_half.o \
	$(BUILD)/cc_driver.o \
	$(BUILD)/cc_ubsearch.o
CC_HDRS = $(CCDIR)/cc_half.h $(CCDIR)/cc_driver.h $(CCDIR)/cc_ubsearch.h
TEST_CC = $(BUILD)/test_cc_engine

# Web demo (web/): in-process library entry point src/core/dq_api.{h,cc} (no fork / pipe / signals). Every object of
# the library builds is compiled with -DDQ_LIBRARY in its own directory; the CLI objects above never see that macro.
LIBDIR   = $(BUILD)/lib
LIB_CXXFLAGS = $(CXXFLAGS) -DDQ_LIBRARY
LIB_OBJS = $(LIBDIR)/SimpSolver.o $(LIBDIR)/Solver.o $(LIBDIR)/Options.o $(LIBDIR)/System.o \
           $(LIBDIR)/cc_half.o $(LIBDIR)/cc_driver.o $(LIBDIR)/cc_ubsearch.o $(LIBDIR)/dq_api.o
DQ_API_TEST = $(BUILD)/dq_api_test
GIT_COMMIT := $(shell git rev-parse --short=12 HEAD 2>/dev/null || echo unknown)

# WebAssembly build (needs the Emscripten SDK: source emsdk_env.sh first). Output: web/dq.js + web/dq.wasm.
EMXX     ?= em++
WASMDIR  = $(BUILD)/wasm
WASM_CXXFLAGS = -O3 -I$(SOLVER) -Wall -Wno-parentheses -Wno-reserved-user-defined-literal \
           -D __STDC_LIMIT_MACROS -D __STDC_FORMAT_MACROS -DNDEBUG -DDQ_LIBRARY -sUSE_ZLIB=1
WASM_OBJS = $(WASMDIR)/SimpSolver.o $(WASMDIR)/Solver.o $(WASMDIR)/Options.o $(WASMDIR)/System.o \
           $(WASMDIR)/cc_half.o $(WASMDIR)/cc_driver.o $(WASMDIR)/cc_ubsearch.o $(WASMDIR)/dq_api.o
WASM_LDFLAGS = -O3 -sUSE_ZLIB=1 -sMODULARIZE=1 -sEXPORT_NAME=createDQ -sENVIRONMENT=web,worker,node \
           -sALLOW_MEMORY_GROWTH=1 -sINITIAL_MEMORY=67108864 -sMAXIMUM_MEMORY=2147483648 -sSTACK_SIZE=8388608 \
           -sEXIT_RUNTIME=0 -sEXPORTED_FUNCTIONS=_dq_solve_js,_dq_version,_malloc,_free \
           -sEXPORTED_RUNTIME_METHODS=ccall,UTF8ToString,stringToUTF8,lengthBytesUTF8,HEAPU8

.PHONY: all clean test-cc test-cc-flags test-dq-api wasm

all: $(BIN) $(MAXCDCL)

$(MAXCDCL): $(SOLVER)/Main.cc $(ENGINE_OBJS) | dirs
	$(CXX) $(CXXFLAGS) -o $@ $(SOLVER)/Main.cc $(ENGINE_OBJS) $(LDFLAGS)

$(BIN): $(CORE)/distqldpc.cc $(ENGINE_OBJS) $(CC_OBJS) $(CC_HDRS) | dirs
	$(CXX) $(CXXFLAGS) -o $@ $(CORE)/distqldpc.cc $(ENGINE_OBJS) $(CC_OBJS) $(LDFLAGS)

dirs:
	@mkdir -p build bin

$(BUILD)/SimpSolver.o: $(SOLVER)/SimpSolver.cc | dirs
	$(CXX) $(CXXFLAGS) -c -o $@ $<

$(BUILD)/Solver.o: $(SOLVER)/Solver.cc | dirs
	$(CXX) $(CXXFLAGS) -c -o $@ $<

$(BUILD)/Options.o: $(SOLVER)/utils/Options.cc | dirs
	$(CXX) $(CXXFLAGS) -c -o $@ $<

$(BUILD)/System.o: $(SOLVER)/utils/System.cc | dirs
	$(CXX) $(CXXFLAGS) -c -o $@ $<

$(BUILD)/cc_half.o: $(CCDIR)/cc_half.cc $(CC_HDRS) | dirs
	$(CXX) $(CXXFLAGS) -std=c++17 -c -o $@ $<

$(BUILD)/cc_driver.o: $(CCDIR)/cc_driver.cc $(CC_HDRS) | dirs
	$(CXX) $(CXXFLAGS) -std=c++17 -c -o $@ $<

$(BUILD)/cc_ubsearch.o: $(CCDIR)/cc_ubsearch.cc $(CC_HDRS) | dirs
	$(CXX) $(CXXFLAGS) -std=c++17 -c -o $@ $<

# GH-124 engine tests (brute-force oracle, rule subsets, relabeling seeds, mutants, forked pipe driver)
$(TEST_CC): tests/test_cc_engine.cc $(CORE)/distqldpc.cc $(ENGINE_OBJS) $(CC_OBJS) $(CC_HDRS) | dirs
	$(CXX) $(CXXFLAGS) -std=c++17 -o $@ tests/test_cc_engine.cc $(ENGINE_OBJS) $(CC_OBJS) $(LDFLAGS)

test-cc: $(TEST_CC)
	./$(TEST_CC)

# GH-124 command-line checks: engine flag conflicts rejected, invalid CC flag values rejected
test-cc-flags: $(BIN)
	bash tests/test_cc_flags.sh ./$(BIN)

# ---- web demo: native library build + checks (tests/test_dq_api.cc), and the WebAssembly module
$(LIBDIR)/SimpSolver.o: $(SOLVER)/SimpSolver.cc | libdirs
	$(CXX) $(LIB_CXXFLAGS) -c -o $@ $<
$(LIBDIR)/Solver.o: $(SOLVER)/Solver.cc $(SOLVER)/Solver.h | libdirs
	$(CXX) $(LIB_CXXFLAGS) -c -o $@ $<
$(LIBDIR)/Options.o: $(SOLVER)/utils/Options.cc | libdirs
	$(CXX) $(LIB_CXXFLAGS) -c -o $@ $<
$(LIBDIR)/System.o: $(SOLVER)/utils/System.cc | libdirs
	$(CXX) $(LIB_CXXFLAGS) -c -o $@ $<
$(LIBDIR)/%.o: $(CCDIR)/%.cc $(CC_HDRS) | libdirs
	$(CXX) $(LIB_CXXFLAGS) -std=c++17 -c -o $@ $<
$(LIBDIR)/dq_api.o: $(CORE)/dq_api.cc $(CORE)/dq_api.h $(CORE)/distqldpc.cc $(CC_HDRS) | libdirs
	$(CXX) $(LIB_CXXFLAGS) -std=c++17 -DDQ_GIT_COMMIT='"$(GIT_COMMIT)"' -c -o $@ $<
$(DQ_API_TEST): tests/test_dq_api.cc $(LIB_OBJS) | libdirs
	$(CXX) $(LIB_CXXFLAGS) -std=c++17 -pthread -o $@ tests/test_dq_api.cc $(LIB_OBJS) $(LDFLAGS)
libdirs:
	@mkdir -p $(LIBDIR) $(WASMDIR) bin

test-dq-api: $(DQ_API_TEST)

$(WASMDIR)/SimpSolver.o: $(SOLVER)/SimpSolver.cc | libdirs
	$(EMXX) $(WASM_CXXFLAGS) -c -o $@ $<
$(WASMDIR)/Solver.o: $(SOLVER)/Solver.cc $(SOLVER)/Solver.h | libdirs
	$(EMXX) $(WASM_CXXFLAGS) -c -o $@ $<
$(WASMDIR)/Options.o: $(SOLVER)/utils/Options.cc | libdirs
	$(EMXX) $(WASM_CXXFLAGS) -c -o $@ $<
$(WASMDIR)/System.o: $(SOLVER)/utils/System.cc | libdirs
	$(EMXX) $(WASM_CXXFLAGS) -c -o $@ $<
$(WASMDIR)/%.o: $(CCDIR)/%.cc $(CC_HDRS) | libdirs
	$(EMXX) $(WASM_CXXFLAGS) -std=c++17 -c -o $@ $<
$(WASMDIR)/dq_api.o: $(CORE)/dq_api.cc $(CORE)/dq_api.h $(CORE)/distqldpc.cc $(CC_HDRS) | libdirs
	$(EMXX) $(WASM_CXXFLAGS) -std=c++17 -DDQ_GIT_COMMIT='"$(GIT_COMMIT)"' -c -o $@ $<
web/dq.js: $(WASM_OBJS)
	@mkdir -p web
	$(EMXX) $(WASM_LDFLAGS) -o $@ $(WASM_OBJS)

wasm: web/dq.js

clean:
	rm -rf build $(BIN) $(MAXCDCL)
