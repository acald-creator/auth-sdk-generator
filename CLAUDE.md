# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an OCaml-based authentication SDK generator that creates type-safe SDKs for multiple programming languages from custom DSL specifications. It supports OAuth 2.0 with PKCE and includes comprehensive validation to ensure generated SDKs are production-ready.

**Supported Languages:**
- **TypeScript**: Complete OAuth2 client with strict type safety and comprehensive validation
- **Python**: Modern async/await OAuth2 client with dataclasses and type hints
- **ReScript** (Planned): Sound type system with functional programming paradigms and JavaScript interop

**Planned Languages:**
- **Go**: Struct-based OAuth client with goroutine support
- **Java**: Enterprise-ready SDK with Spring integration

**Key Features:**
- In-memory code validation before file generation
- Dynamic dependency version management with fallback strategies
- Multi-language CLI with comprehensive error reporting
- Production-ready SDK generation with full build/test integration
- **ReScript Bridge** (Planned): Web-based management UI for visual spec creation and SDK generation

## Essential Commands

### Core Development
```bash
make build                    # Build OCaml generator
make test                     # Run OCaml tests

# TypeScript Generation
make generate                 # Generate TypeScript SDK from prototype.auth
make generate-fast            # Generate TypeScript SDK without validation
make dev                      # Full workflow: build generator + generate TS + build TS SDK

# Python Generation
make generate-python          # Generate Python SDK from prototype.auth
make generate-python-fast     # Generate Python SDK without validation
make dev-python              # Full workflow: build generator + generate Python + test imports

# Utility Commands
make clean                    # Clean all build artifacts
make status                   # Show project status
```

### Advanced Testing
```bash
make test-versions            # Test both version fetching strategies
make test-live-versions       # Test with live npm version fetching
make test-fallback-versions   # Test with hardcoded fallback versions
```

### Direct Generator Usage
```bash
# TypeScript Generation
./_build/default/bin/main.exe specs/prototype.auth output/directory
./_build/default/bin/main.exe --lang typescript specs/prototype.auth output/directory

# Python Generation
./_build/default/bin/main.exe --lang python specs/prototype.auth output/directory

# Options
./_build/default/bin/main.exe --offline specs/prototype.auth output/directory      # Use fallback versions
./_build/default/bin/main.exe --no-validate specs/prototype.auth output/directory # Skip validation
```

### OCaml Specific
```bash
dune build                    # Build without Make wrapper
dune runtest                  # Run tests without Make wrapper
dune clean                    # Clean OCaml build artifacts only
```

## Architecture

### Core Components

**AST Layer** (`lib/ast/auth_types.ml`)
- Defines the core types: `auth_spec`, `provider`, `oauth2_config`, `oauth2_flow`
- Uses `[@@deriving show]` for pretty-printing
- Central data model shared across all components

**Parser Layer** (`lib/parsers/simple_parser.ml`)
- Parses `.auth` specification files (simple key=value format)
- Handles quoted values and ignores comments starting with `#`
- Creates `auth_spec` AST from DSL files
- Key function: `parse_file : string -> auth_spec`

**Generator Layer**
- **TypeScript Generator** (`lib/generators/typescript/ts_generator.ml`): Complete TypeScript OAuth2 client with PKCE support, creates full project structure
- **Python Generator** (`lib/generators/python/py_generator.ml`): Modern Python OAuth2 client with async/await, dataclasses, and type hints
- Both generators create complete project structures with build configs, documentation, and examples

**Version Management** (`lib/utils/version_fetcher.ml`)
- Dynamically fetches latest npm package versions for TypeScript SDKs
- Fallback system: npm command → curl API → hardcoded versions
- Validates version formats and provides early error detection
- Key function: `get_typescript_versions : ?use_fallback_first:bool -> unit -> (string * string) list`

**Validation Layer**
- **TypeScript Validator** (`lib/validators/typescript_validator.ml`): In-memory validation with OAuth2 structure checks and strict TypeScript compilation
- **Python Validator** (`lib/validators/python_validator.ml`): Python syntax validation with `py_compile` and optional mypy type checking
- Both validators prevent generation of invalid SDKs by validating before file creation

### Data Flow

1. **Specification Parsing**: `.auth` file → `Simple_parser.parse_file` → `auth_spec`
2. **Language Selection**: CLI determines target language (TypeScript/Python)
3. **In-Memory Validation**: Generated code is validated before file creation
   - **OAuth2 Structure Validation**: Ensures required components are present
   - **Language-Specific Validation**: TypeScript compilation or Python syntax checking
4. **Version Resolution** (TypeScript only): `Version_fetcher.get_typescript_versions` → package versions
5. **SDK Generation**: Complete project structure with source, configs, docs, and tests
6. **Integration Testing**: Generated SDKs are built/tested to verify functionality

### DSL Format

Auth specification files use simple key=value syntax:
```
name = "App Name"
client_id = "your-client-id"
authorize_url = "https://provider.com/oauth2/auth"
token_url = "https://provider.com/oauth2/token"
scopes = "scope1,scope2,scope3"
```

### Generated SDK Structures

**TypeScript SDK:**
- **OAuth2 Client**: Complete implementation with PKCE, state parameter, token exchange
- **Type Definitions**: AuthConfig interface, token response types, error handling
- **Build System**: package.json with latest TypeScript/Jest versions, strict tsconfig.json
- **Documentation**: README.md with usage examples and configuration details

**Python SDK:**
- **OAuth2 Client**: Modern async/await implementation with PKCE support
- **Type Definitions**: Dataclasses for configuration, comprehensive type hints
- **Build System**: setup.py, requirements.txt, pytest.ini, mypy.ini configuration
- **Documentation**: README.md with asyncio examples and development guides

### Version Management Strategy

The system uses a three-tier fallback approach for npm package versions:
1. **Live fetching**: `npm show <package> version`
2. **API fallback**: `curl` to npm registry JSON API
3. **Hardcoded fallback**: Known-good versions in `fallback_versions`

This ensures generated SDKs always have working dependencies, whether online or offline.

### Dune Build System

The project uses Dune 3.20+ with these key libraries:
- `core`: Standard library
- `yojson`: JSON parsing for npm API responses
- `unix`: Process execution for version fetching
- `str`: Regex validation
- `ppx_deriving`: Code generation for AST pretty-printing

### Testing Philosophy

**Multi-Layer Validation Approach:**

1. **In-Memory Validation**: Code is validated before file creation to prevent invalid SDK generation
2. **Integration Testing**: Generated SDKs are built/tested to verify they work with resolved dependencies
3. **Language-Specific Validation**:
   - **TypeScript**: Strict compilation with enhanced type checking
   - **Python**: Syntax validation with py_compile + optional mypy type checking

**Production Readiness Verification:**
- Generated SDKs must compile/build successfully before being considered valid
- Dependency versions are validated and tested in context
- OAuth2 compliance is verified through structural validation
- All generated projects include comprehensive build/test/lint configurations

This ensures that every generated SDK is production-ready and follows language best practices.

## Project Structure

```
auth-sdk-generator/
├── bin/                     # CLI executable
├── lib/
│   ├── ast/                 # Core data types and AST definitions
│   ├── parsers/             # Specification file parsers (.auth format)
│   ├── generators/
│   │   ├── typescript/      # TypeScript SDK generation
│   │   └── python/          # Python SDK generation
│   ├── validators/          # In-memory validation systems
│   └── utils/               # Utilities (version fetching, etc.)
├── doc/
│   ├── architecture/decisions/  # Architecture Decision Records (ADRs)
│   ├── project-audit-2025.md   # Comprehensive project analysis
│   ├── github-issues-structure.md # GitHub repository setup guide
│   └── ready-for-github-release.md # Release readiness verification
├── specs/                   # Example specification files
├── generated/               # Generated SDK outputs (temporary)
├── test/                    # OCaml test suite
├── examples/                # Usage examples and templates
├── tools/                   # Development and build tools
├── Makefile                 # Development workflows
├── CLAUDE.md                # Project documentation (this file)
└── dune-project             # OCaml build configuration
```

### Key Directories

- **`doc/architecture/decisions/`**: Contains all Architecture Decision Records (ADRs) documenting major design decisions
- **`lib/generators/`**: Language-specific SDK generators, each implementing the same core OAuth2+PKCE functionality
- **`lib/validators/`**: In-memory validation systems that ensure generated code is syntactically correct and OAuth2-compliant
- **`specs/`**: Example `.auth` specification files showing how to configure OAuth2 providers
- **`generated/`**: Temporary directory where SDKs are generated during development and testing
- **`bridge/`** (Planned): ReScript bridge for web UI and enhanced CLI tooling

## Planned ReScript Integration

### ReScript as Target Language
The generator will support ReScript as a target language, providing:
- **Sound Type System**: Guaranteed type safety with no runtime type errors
- **Functional Paradigms**: Pure functional programming with immutable data structures
- **Fast Compilation**: Leveraging ReScript's OCaml-based compiler for quick builds
- **JavaScript Interop**: Seamless integration with existing JavaScript/TypeScript codebases
- **React Bindings**: First-class support for React applications

### ReScript Bridge for Management
A web-based management interface built with ReScript will provide:
- **Visual Spec Editor**: Drag-and-drop OAuth configuration without writing `.auth` files
- **Flow Visualization**: Real-time OAuth flow diagrams showing authorization paths
- **Live SDK Preview**: Instant code generation preview in the browser
- **Template Library**: Pre-configured specs for common providers (Google, GitHub, Auth0, Ory Hydra)
- **Batch Generation**: Generate multiple SDKs across different languages simultaneously
- **Version Management**: Track and manage specification versions

### Why ReScript?
- **Type Soundness**: Unlike TypeScript, ReScript's type system is sound - no `any` types or runtime surprises
- **OCaml Heritage**: Natural fit with our OCaml core, sharing the same type system foundations
- **Compilation Speed**: 10-100x faster compilation than TypeScript for large codebases
- **Functional First**: Encourages immutable, predictable code patterns ideal for SDK generation
- **Gradual Adoption**: Can be adopted incrementally alongside existing TypeScript/JavaScript code