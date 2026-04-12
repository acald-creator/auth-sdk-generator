# Auth SDK Generator - Gemini CLI Guidelines

This repository contains an OCaml-based polyglot authentication SDK generator that creates type-safe OAuth 2.0 SDKs for multiple programming languages (TypeScript, Python, and ReScript) from simple DSL specifications (`.auth` files).

## Core Principles & Mandates

- **Type Safety First**: Leverage OCaml's strong type system for all AST manipulations and code generation. Avoid exceptions; use `Result` types for explicit error handling.
- **Validation-Driven Generation**: NEVER generate an SDK that hasn't passed in-memory validation. Every generator MUST have a corresponding validator that checks for syntax correctness and OAuth2 structural compliance before files are written to disk.
- **Production-Ready Output**: Generated SDKs must be complete, including build configurations (package.json, setup.py), documentation (README.md), and test suites (Jest, pytest).
- **Dynamic Dependency Management**: SDKs should use up-to-date dependencies. Follow the three-tier resolution strategy: Live NPM/PyPI fetch -> Registry API -> Hardcoded fallbacks (in `lib/utils/version_fetcher.ml`).
- **Functional Idioms**: Adhere to functional programming patterns in OCaml. Use pattern matching extensively for AST transformations.

## Architecture Overview

The generator follows a strict pipeline architecture:
1. **Parse**: `.auth` file → `Simple_parser` → `auth_spec` (AST).
2. **Validate Spec**: Ensure the AST contains all required fields (client_id, authorize_url, etc.).
3. **Generate**: `auth_spec` → Language-specific generator (`ts_generator.ml`, `py_generator.ml`).
4. **Validate Output**: In-memory validation of the generated code strings (Syntax + OAuth2 structure).
5. **Write**: Save the validated SDK project structure to the target directory.

### Key Components
- `lib/ast/auth_types.ml`: The source of truth for the core data model.
- `lib/parsers/simple_parser.ml`: Handles DSL parsing.
- `lib/generators/`: Contains language-specific generation logic.
- `lib/validators/`: Implements in-memory validation for each target language.
- `lib/utils/version_fetcher.ml`: Manages dynamic dependency versions.
- `studio/`: ReScript-based web interface for visual spec editing.

## Technical Standards

- **OCaml**: Version 5.1+, using Dune for builds. Prefer `Core` over the standard library where applicable.
- **Testing**: Use `dune runtest` for OCaml tests. Every new feature or bug fix MUST include unit tests in the `test/` directory.
- **DSL Format**: Key-value pairs. Quoted strings are required for values containing spaces or special characters. Comments start with `#`.
- **OAuth2 Compliance**: Generated SDKs MUST support PKCE by default. State parameters are mandatory for authorization flows.

## Common Workflows

- **Build**: `make build`
- **Test**: `make test`
- **Development Cycle (TS)**: `make dev` (builds generator, generates TS SDK, runs TS tests).
- **Development Cycle (Python)**: `make dev-python`.
- **Clean**: `make clean`.

## Adding a New Language

1. Define the generator in `lib/generators/<lang>/`.
2. Implement a validator in `lib/validators/<lang>_validator.ml`.
3. Update `bin/main.ml` to include the new language option.
4. Add integration tests in `test/`.
5. Update `CLAUDE.md` and `README.md` with the new capability.
