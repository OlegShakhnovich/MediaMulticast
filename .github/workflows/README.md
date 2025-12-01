# Modular Multi-Platform CI/CD Pipeline Architecture

## Overview

The CI/CD system is structured as a set of reusable workflows designed for determinism, platform consistency, and long-term maintainability. Each workflow has a single responsibility and can be invoked independently or composed into higher-level orchestration workflows.

## Core Principles

- **Strict workflow decomposition**: each workflow handles exactly one task such as formatting, static analysis, building, or testing
- **Cross-platform unification**: shared logic resides in reusable actions; only minimal OS-specific code remains
- **Deterministic toolchain**: LLVM is fully cached and version-locked to ensure identical diagnostics and builds across Linux, macOS, and Windows
- **Artifact isolation**: each workflow produces well-scoped outputs, simplifying debugging and consumption by other systems
- **Explicit control flow**: workflow_call dependencies define the exact order of operations

## Components

### Workflows

#### `setup-llvm-cache.yml`
- **Purpose**: Pre-fetch or download LLVM toolchains for the target OS
- **Outputs**: a cached llvm directory for the runner, used by subsequent jobs
- **Notes**: Does not modify PATH; used strictly for caching and download

#### `format.yml`
- **Purpose**: Validate and optionally apply clang-format corrections
- **Behavior**:
  - Runs formatting checks against src, include, and tests
  - Auto-applies changes only when safe (non-fork PRs)
- **Outputs**: clean or updated formatting state

#### `tidy-src.yml` and `tidy-tests.yml`
- **Purpose**: Run static analysis over the main codebase and test suite respectively
- **Behavior**:
  - Independent build directories for compile_commands.json
  - Isolated clang-tidy configs for source vs tests
  - macOS runs non-blocking tidy by design due to Apple SDK variability

#### `build.yml`
- **Purpose**: Compile the library, binary, and tests using a deterministic LLVM toolchain
- **Behavior**:
  - Single build directory using Ninja
  - Consistent compiler flags across platforms
  - Outputs complete build artifacts for downstream workflows

#### `test.yml`
- **Purpose**: Execute test binaries produced by build.yml
- **Behavior**:
  - Downloads build artifacts
  - Runs ctest with parallel execution
  - Emits test reports and exit codes

#### `validate.yml`
- **Purpose**: Orchestrate the entire CI pipeline
- **Execution flow**:
  - Prepares LLVM caches for all platforms
  - Runs formatting, static analysis for source and tests
  - Builds on all platforms
  - Executes tests after build completion
- **Characteristics**:
  - Clear separation of responsibilities
  - Fully deterministic order due to explicit needs graph
  - Parallelizable where safe (formatting and tidy jobs)

### Actions

#### `setup-llvm`
- **Purpose**: Restore cached LLVM, place it on PATH, and verify compiler/diagnostic versioning
- **Guarantees**:
  - `clang`, `clang-format`, and `clang-tidy` match the pipeline's required LLVM version
  - Platform-consistent selection of tools

#### `generate-compile-commands`
- **Purpose**: Produce `compile_commands.json` using a Ninja configuration
- **Behavior**:
  - Creates isolated build directories for analysis (source and tests)
  - Respects optional test-enablement

#### `run-clang-tidy`
- **Purpose**: Run clang-tidy across selected directories using `compile_commands.json`
- **Behavior**:
  - Recursive scanning of file types: `.cpp`, `.cc`, `.h`, `.hpp`
  - OS-consistent invocation
  - Optional error-enforcement mode

## Pipeline Flow Summary

```mermaid
graph TD
    validate.yml --> setup-llvm-cache
    setup-llvm-cache --> Linux
    setup-llvm-cache --> macOS
    setup-llvm-cache --> Windows
    
    validate.yml --> format
    
    validate.yml --> tidy-src
    tidy-src --> Linux
    tidy-src --> macOS
    tidy-src --> Windows
    
    validate.yml --> tidy-tests
    tidy-tests --> Linux
    tidy-tests --> macOS
    tidy-tests --> Windows
    
    validate.yml --> build
    build --> Linux
    build --> macOS
    build --> Windows
    
    validate.yml --> test
    test --> Linux
    test --> macOS
    test --> Windows