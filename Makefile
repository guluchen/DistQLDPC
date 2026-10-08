# QLDPC / CSS minimum-distance calculator (DistQLDPC)

SRC     = src
CORE    = $(SRC)/core
SOLVER  = $(SRC)/solver
BUILD   = build
BIN     = bin/distqldpc
MAXCDCL = bin/maxcdcl

ifneq ($(filter default undefined,$(origin CXX)),)
CXX      = clang++ -Wno-reserved-user-defined-literal
LINK_CXX ?= g++
else
LINK_CXX ?= $(CXX)
endif
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

$(MAXCDCL): $(BUILD)/Main.o $(ENGINE_OBJS) | dirs
	$(LINK_CXX) $(CXXFLAGS) -o $@ $(BUILD)/Main.o $(ENGINE_OBJS) $(LDFLAGS)

$(BIN): $(BUILD)/distqldpc.o $(ENGINE_OBJS) | dirs
	$(LINK_CXX) $(CXXFLAGS) -o $@ $(BUILD)/distqldpc.o $(ENGINE_OBJS) $(LDFLAGS)

$(BUILD)/Main.o: $(SOLVER)/Main.cc | dirs
	$(CXX) $(CXXFLAGS) -c -o $@ $<

$(BUILD)/distqldpc.o: $(CORE)/distqldpc.cc | dirs
	$(CXX) $(CXXFLAGS) -c -o $@ $<

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

clean:
	rm -rf build $(BIN) $(MAXCDCL)
