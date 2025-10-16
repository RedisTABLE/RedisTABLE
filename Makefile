# -----------------------------------------------------------------------------
# RedisTABLE Module Makefile
# Author: Raphael Drai
# Date: October 3, 2025
# -----------------------------------------------------------------------------

.NOTPARALLEL:

MAKEFLAGS += --no-print-directory

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

ROOT := $(shell pwd)
MODULE_NAME := redistable
MODULE_SO := $(MODULE_NAME).so
SRCDIR := .
BINDIR := bin

# Source files
SOURCES := redis_table.c
OBJECTS := $(SOURCES:.c=.o)

# Redis Module SDK (bundled)
REDIS_MODULE_SDK := $(ROOT)/deps/RedisModulesSDK

# Redis configuration
# REDIS_SRC is now optional - we bundle redismodule.h in deps/RedisModulesSDK
# You can still override it if needed for compatibility
REDIS_SRC ?= $(REDIS_MODULE_SDK)
REDIS_SERVER ?= redis-server

# Compiler configuration
CC := gcc
LD := gcc

# Build type flags
DEBUG ?= 0
PROFILE ?= 0
COV ?= 0
VERBOSE ?= 0

# Optimization flags
ifeq ($(DEBUG),1)
	OPTIMIZATION := -O0
	DEBUG_FLAGS := -g -ggdb
else
	OPTIMIZATION := -O2
	DEBUG_FLAGS :=
endif

# Profiling flags
ifeq ($(PROFILE),1)
	PROFILE_FLAGS := -pg -fno-omit-frame-pointer
	DEBUG_FLAGS := -g -ggdb
else
	PROFILE_FLAGS :=
endif

# Coverage flags
ifeq ($(COV),1)
	COV_FLAGS := --coverage -fprofile-arcs -ftest-coverage
	DEBUG_FLAGS := -g -ggdb
else
	COV_FLAGS :=
endif

# Compiler flags
CFLAGS := -Wall -Werror -Wextra -Wno-unused-parameter -std=gnu99 -fPIC
CFLAGS += $(OPTIMIZATION) $(DEBUG_FLAGS) $(PROFILE_FLAGS) $(COV_FLAGS)
# Use bundled Redis Module SDK by default, or REDIS_SRC if explicitly set
CFLAGS += -I$(REDIS_SRC)

# Linker flags
LDFLAGS := -shared
LDFLAGS += $(PROFILE_FLAGS) $(COV_FLAGS)

# Verbose output
ifeq ($(VERBOSE),1)
	Q :=
else
	Q := @
endif

# -----------------------------------------------------------------------------
# Help text
# -----------------------------------------------------------------------------

define HELPTEXT
RedisTABLE Build System

Note: This module bundles redismodule.h and is self-contained.
      No external Redis source required!

Setup:
  make setup         Install packages required for build

Build:
  make build         Compile and link (default target)
    DEBUG=1            Build for debugging (with symbols, no optimization)
    PROFILE=1          Build with profiling support
    COV=1              Build with coverage instrumentation
    VERBOSE=1          Verbose build output
    REDIS_SRC=/path    Override bundled SDK (for compatibility)
  
  make all           Same as 'make build'
  make clean         Remove build artifacts
    ALL=1              Remove all build directories

Testing:
  make test          Run all tests
  make unit-tests    Run unit tests
  make flow-tests    Run flow tests
    TEST=name          Run test matching 'name'
    QUICK=1            Run quick test subset
  make client-tests  Run client compatibility tests (alias: test-clients)
  make memory-tests  Run memory leak detection tests (alias: test-memory)
  make test-config   Run configuration tests
  make test-all      Run all tests (unit + client + memory + config)
  
Development:
  make run           Run Redis with RedisTABLE module
    GDB=1              Run with gdb debugger
    VALGRIND=1         Run with valgrind
  make debug         Build and show debug instructions
  
Packaging:
  make install       Install module to system location
    PREFIX=/path       Install to custom prefix (default: /usr/local)
  
Coverage:
  make coverage      Generate coverage report (implies COV=1)
  make show-cov      Show coverage results in browser
  
Maintenance:
  make format        Format source code
  make lint          Run linters
  
endef

# -----------------------------------------------------------------------------
# Targets
# -----------------------------------------------------------------------------

.DEFAULT_GOAL := build

help:
	$(info $(HELPTEXT))
	@:

# Build target
build: $(MODULE_SO)

all: build

# Compile object files
%.o: %.c
	@echo "CC $<"
	$(Q)$(CC) $(CFLAGS) -c $< -o $@

# Link shared library
$(MODULE_SO): $(OBJECTS)
	@echo "LD $@"
	$(Q)$(LD) $(LDFLAGS) -o $@ $^
	@echo "Module built successfully: $(MODULE_SO)"

# Clean targets
clean:
ifeq ($(ALL),1)
	@echo "Cleaning all build artifacts..."
	$(Q)rm -rf $(BINDIR)
	$(Q)rm -f $(OBJECTS) $(MODULE_SO)
	$(Q)rm -f *.gcda *.gcno *.gcov
	$(Q)rm -rf coverage/
else
	@echo "Cleaning build artifacts..."
	$(Q)rm -f $(OBJECTS) $(MODULE_SO)
	$(Q)rm -f *.gcda *.gcno *.gcov
endif

# Setup dependencies
setup:
	@echo "Installing build dependencies..."
	@echo "Note: This requires sudo privileges"
	@which gcc > /dev/null || (echo "Installing gcc..." && sudo apt-get install -y gcc)
	@which redis-server > /dev/null || (echo "Redis not found. Please install Redis first." && exit 1)
	@echo "Dependencies OK"

# Test targets
test: unit-tests

unit-tests: $(MODULE_SO)
	@echo "Running unit tests..."
	$(Q)cd tests && ./run_tests.sh

flow-tests: unit-tests

test-clients: $(MODULE_SO)
	@echo "Running client compatibility tests..."
	@echo "Note: Tests will be skipped if dependencies are not installed"
	$(Q)cd tests && ./run_client_tests.sh

# Alias for consistency with documentation
client-tests: test-clients

test-memory: $(MODULE_SO)
	@echo "Running memory leak detection tests..."
	$(Q)cd tests && ./test_memory_leaks.sh

# Alias for consistency with documentation
memory-tests: test-memory

test-memory-profiler: $(MODULE_SO)
	@echo "Running memory profiler..."
	$(Q)cd tests && python3 test_memory_profiler.py || true

test-config: $(MODULE_SO)
	@echo "Running configuration tests..."
	$(Q)cd tests && ./test_configuration.sh

test-all: test test-clients test-memory test-config

# Run Redis with module
run: $(MODULE_SO)
ifeq ($(GDB),1)
	@echo "Starting Redis with module under GDB..."
	gdb --args $(REDIS_SERVER) --loadmodule $(ROOT)/$(MODULE_SO)
else ifeq ($(VALGRIND),1)
	@echo "Starting Redis with module under Valgrind..."
	valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes \
		$(REDIS_SERVER) --loadmodule $(ROOT)/$(MODULE_SO)
else
	@echo "Starting Redis with module..."
	@echo "Module path: $(ROOT)/$(MODULE_SO)"
	$(REDIS_SERVER) --loadmodule $(ROOT)/$(MODULE_SO)
endif

# Debug target
debug: $(MODULE_SO)
	@echo "Module built with debug info: $(MODULE_SO)"
	@echo ""
	@echo "To debug with GDB:"
	@echo "  make run GDB=1"
	@echo "  or"
	@echo "  gdb --args $(REDIS_SERVER) --loadmodule $(ROOT)/$(MODULE_SO)"
	@echo ""
	@echo "To check for memory leaks:"
	@echo "  make run VALGRIND=1"
	@echo "  or"
	@echo "  make test-memory"

# Install target
install: $(MODULE_SO)
	@echo "Installing $(MODULE_SO)..."
	$(Q)mkdir -p $(PREFIX)/lib/redis/modules/
	$(Q)cp $(MODULE_SO) $(PREFIX)/lib/redis/modules/
	@echo "Installed to $(PREFIX)/lib/redis/modules/$(MODULE_SO)"

# Coverage targets
coverage: COV=1
coverage: clean build test
	@echo "Generating coverage report..."
	$(Q)mkdir -p coverage
	$(Q)gcov $(SOURCES)
	$(Q)lcov --capture --directory . --output-file coverage/coverage.info 2>/dev/null || true
	$(Q)genhtml coverage/coverage.info --output-directory coverage/html 2>/dev/null || true
	@echo "Coverage report generated in coverage/html/index.html"

show-cov: coverage
	@echo "Opening coverage report..."
	$(Q)xdg-open coverage/html/index.html 2>/dev/null || open coverage/html/index.html 2>/dev/null || \
		echo "Please open coverage/html/index.html in your browser"

# Code formatting (placeholder - requires clang-format)
format:
	@echo "Formatting source code..."
	@which clang-format > /dev/null && clang-format -i $(SOURCES) || \
		echo "clang-format not found. Skipping formatting."

# Linting (placeholder - requires static analysis tools)
lint:
	@echo "Running linters..."
	@which cppcheck > /dev/null && cppcheck --enable=all --suppress=missingIncludeSystem $(SOURCES) || \
		echo "cppcheck not found. Skipping lint."

# Phony targets
.PHONY: all build clean setup test unit-tests flow-tests test-clients test-memory \
        test-memory-profiler test-config test-all memory-tests client-tests run debug \
        install coverage show-cov format lint help

# Default prefix for install
PREFIX ?= /usr/local
