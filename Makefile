# QLDPC / CSS minimum-distance calculator (DistQLDPC)

SRC     = src
CORE    = $(SRC)/core
SOLVER  = $(SRC)/solver
ENGINE  = $(SRC)/engine
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

.PHONY: all clean

all: $(BIN) $(MAXCDCL)

$(MAXCDCL): $(SOLVER)/Main.cc $(ENGINE_OBJS) | dirs
	$(CXX) $(CXXFLAGS) -o $@ $(SOLVER)/Main.cc $(ENGINE_OBJS) $(LDFLAGS)

$(BIN): $(CORE)/distqldpc.cc $(ENGINE_OBJS) | dirs
	$(CXX) $(CXXFLAGS) -o $@ $(CORE)/distqldpc.cc $(ENGINE_OBJS) $(LDFLAGS)

dirs:
	@mkdir -p build bin

$(BUILD)/SimpSolver.o: $(SOLVER)/SimpSolver.cc | dirs
	$(CXX) $(CXXFLAGS) -c -o $@ $<

# DistQLDPC engine (restructured from MaxCDCL Solver.cc, GH-95): ONE translation unit.
# Engine.cc #includes the module files of src/engine/ in a fixed order; never compile them alone.
# The object keeps the name build/Solver.o (same link position; CI links tests against it).
ENGINE_SRCS = $(wildcard $(ENGINE)/*.cc) $(wildcard $(ENGINE)/*.h)

$(BUILD)/Solver.o: $(ENGINE)/Engine.cc $(ENGINE_SRCS) | dirs
	$(CXX) $(CXXFLAGS) -c -o $@ $<

$(BUILD)/Options.o: $(SOLVER)/utils/Options.cc | dirs
	$(CXX) $(CXXFLAGS) -c -o $@ $<

$(BUILD)/System.o: $(SOLVER)/utils/System.cc | dirs
	$(CXX) $(CXXFLAGS) -c -o $@ $<

clean:
	rm -rf build $(BIN) $(MAXCDCL)
