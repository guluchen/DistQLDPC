# QLDPC / CSS minimum-distance calculator (DistQLDPC)

SRC     = src
CORE    = $(SRC)/core
SOLVER  = $(SRC)/solver
CCDIR   = $(SRC)/cc
BUILD   = build
BIN     = bin/distqldpc
MAXCDCL = bin/maxcdcl

CXX     ?= g++
OPTFLAGS ?= -O3 -g -DNDEBUG
CFLAGS  ?= $(OPTFLAGS)
CXXFLAGS = -I$(SOLVER) -Wall -Wno-parentheses $(OPTFLAGS) \
           -D __STDC_LIMIT_MACROS -D __STDC_FORMAT_MACROS
LDFLAGS  = -lz

ENGINE_OBJS = \
	$(BUILD)/SimpSolver.o \
	$(BUILD)/Solver.o \
	$(BUILD)/Options.o \
	$(BUILD)/System.o

# GH-124 (experimental): connected-cluster level-search engine (C++17), linked into bin/distqldpc
CC_OBJS = \
	$(BUILD)/cc_half.o $(BUILD)/cc_level.o \
	$(BUILD)/cc_driver.o \
	$(BUILD)/cc_ubsearch.o \
	$(BUILD)/cc_aut.o
CC_HDRS = $(CCDIR)/cc_epoch.h $(CCDIR)/cc_level.h $(CCDIR)/cc_half.h $(CCDIR)/cc_driver.h $(CCDIR)/cc_ubsearch.h $(CCDIR)/cc_aut.h
TEST_CC = $(BUILD)/test_cc_engine

.PHONY: all clean test-cc test-cc-flags

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

$(BUILD)/cc_level.o: $(CCDIR)/cc_level.c $(CCDIR)/cc_level.h $(CCDIR)/cc_epoch.h | dirs
	$(CC) $(CPPFLAGS) $(CFLAGS) -std=c99 -Wall -c -o $@ $<

$(BUILD)/cc_half.o: $(CCDIR)/cc_half.cc $(CCDIR)/cc_pack_row.h $(CCDIR)/cc_candidate_row.h $(CCDIR)/cc_row_builder.h $(CCDIR)/cc_overlap.h $(CCDIR)/cc_overlap_policy.h $(CCDIR)/cc_seed_policy.h $(CC_HDRS) | dirs
	$(CXX) $(CXXFLAGS) -std=c++17 -c -o $@ $<

$(BUILD)/cc_driver.o: $(CCDIR)/cc_driver.cc $(CCDIR)/cc_distance_bounds.h $(CC_HDRS) | dirs
	$(CXX) $(CXXFLAGS) -std=c++17 -c -o $@ $<

$(BUILD)/cc_ubsearch.o: $(CCDIR)/cc_ubsearch.cc $(CC_HDRS) | dirs
	$(CXX) $(CXXFLAGS) -std=c++17 -c -o $@ $<

$(BUILD)/cc_aut.o: $(CCDIR)/cc_aut.cc $(CC_HDRS) | dirs
	$(CXX) $(CXXFLAGS) -std=c++17 -c -o $@ $<

# GH-124 engine tests (brute-force oracle, rule subsets, relabeling seeds, mutants, forked pipe driver)
$(TEST_CC): tests/test_cc_engine.cc $(CORE)/distqldpc.cc $(ENGINE_OBJS) $(CC_OBJS) $(CC_HDRS) | dirs
	$(CXX) $(CXXFLAGS) -std=c++17 -o $@ tests/test_cc_engine.cc $(ENGINE_OBJS) $(CC_OBJS) $(LDFLAGS)

test-cc: $(TEST_CC)
	./$(TEST_CC)

# GH-124 command-line checks: engine flag conflicts rejected, invalid CC flag values rejected
test-cc-flags: $(BIN)
	bash tests/test_cc_flags.sh ./$(BIN)

clean:
	rm -rf build $(BIN) $(MAXCDCL)
