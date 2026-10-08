# QLDPC / CSS minimum-distance calculator (DistQLDPC)

SRC     = src
CORE    = $(SRC)/core
SOLVER  = $(SRC)/solver
BUILD   = build
BIN     = bin/distqldpc
MAXCDCL = bin/maxcdcl

CXX     ?= g++
CXXFLAGS = -I$(SOLVER) -Wall -Wno-parentheses -O3 -g \
           -D __STDC_LIMIT_MACROS -D __STDC_FORMAT_MACROS -DNDEBUG
LDFLAGS  = -lz

# PGO is optional and applies only to the embedded engine translation units.
# Always clean generated objects when changing PGO mode; retain PGO_DIR.
PGO ?= off
PGO_DIR ?= $(CURDIR)/pgo-data
ifeq ($(PGO),generate)
PGO_ENGINE_FLAGS = -fprofile-generate=$(PGO_DIR) -ftest-coverage
PGO_APP_FLAGS = -DDISTQLDPC_PROFILE_TRAINING
PGO_LINK_FLAGS = -lgcov
else ifeq ($(PGO),use)
PGO_ENGINE_FLAGS = -fprofile-use=$(PGO_DIR) -Werror=missing-profile -Werror=coverage-mismatch
else ifneq ($(PGO),off)
$(error PGO must be off, generate or use)
endif

ENGINE_OBJS = \
	$(BUILD)/SimpSolver.o \
	$(BUILD)/Solver.o \
	$(BUILD)/Options.o \
	$(BUILD)/System.o

.PHONY: all clean pgo-config

all: $(BIN) $(MAXCDCL)

$(MAXCDCL): $(SOLVER)/Main.cc $(ENGINE_OBJS) | dirs pgo-config
	$(CXX) $(CXXFLAGS) -o $@ $(SOLVER)/Main.cc $(ENGINE_OBJS) $(LDFLAGS) $(PGO_LINK_FLAGS)

$(BIN): $(CORE)/distqldpc.cc $(ENGINE_OBJS) | dirs pgo-config
	$(CXX) $(CXXFLAGS) $(PGO_APP_FLAGS) -o $@ $(CORE)/distqldpc.cc $(ENGINE_OBJS) $(LDFLAGS) $(PGO_LINK_FLAGS)

dirs:
	@mkdir -p build bin
	@$(if $(filter generate,$(PGO)),mkdir -p "$(PGO_DIR)",:)

# Refuse stale objects when callers change build mode, profile path or flags.
# Explicit clean is intentional: never silently delete a user's build outputs.
pgo-config: | dirs
	@printf '%s\n' '$(PGO)|$(PGO_DIR)|$(CXX)|$(CXXFLAGS)' > $(BUILD)/.pgo-request
	@if test -f $(BUILD)/.pgo-config && ! cmp -s $(BUILD)/.pgo-config $(BUILD)/.pgo-request; then \
	  rm -f $(BUILD)/.pgo-request; \
	  echo 'PGO configuration changed: run make clean before rebuilding (retain PGO_DIR).' >&2; exit 1; \
	fi
	@mv $(BUILD)/.pgo-request $(BUILD)/.pgo-config

$(BUILD)/SimpSolver.o: $(SOLVER)/SimpSolver.cc | dirs pgo-config
	$(CXX) $(CXXFLAGS) $(PGO_ENGINE_FLAGS) -c -o $@ $<

$(BUILD)/Solver.o: $(SOLVER)/Solver.cc | dirs pgo-config
	$(CXX) $(CXXFLAGS) $(PGO_ENGINE_FLAGS) -c -o $@ $<

$(BUILD)/Options.o: $(SOLVER)/utils/Options.cc | dirs pgo-config
	$(CXX) $(CXXFLAGS) $(PGO_ENGINE_FLAGS) -c -o $@ $<

$(BUILD)/System.o: $(SOLVER)/utils/System.cc | dirs pgo-config
	$(CXX) $(CXXFLAGS) $(PGO_ENGINE_FLAGS) -c -o $@ $<

clean:
	rm -rf build $(BIN) $(MAXCDCL)
