# Auth SDK Generator

[![OCaml](https://img.shields.io/badge/OCaml-5.1+-orange.svg)](https://ocaml.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Release](https://img.shields.io/github/v/release/acald-creator/auth-sdk-generator?include_prereleases)](https://github.com/acald-creator/auth-sdk-generator/releases)

An OCaml-based polyglot authentication SDK generator that creates type-safe OAuth 2.0 SDKs for multiple programming languages from simple DSL specifications.

## Features

- 🚀 **Multi-language Support**: Generate SDKs for TypeScript and Python (more coming soon)
- 🔐 **OAuth 2.0 with PKCE**: Full implementation with state parameter and code verifier
- ✅ **In-memory Validation**: Code validated before file generation
- 📦 **Smart Dependencies**: Dynamic version management with fallback strategies
- 🏗️ **Production Ready**: Generated SDKs include build configs, tests, and documentation
- 📝 **Simple DSL**: Easy-to-write specification format

## Quick Start

### Prerequisites

- [OCaml](https://ocaml.org/install) 5.1+ and [opam](https://opam.ocaml.org/doc/Install.html) 2.x
- Dune 3.20+
- Node.js 18+ (for TypeScript SDK testing)
- Python 3.8+ (for Python SDK testing)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/acald-creator/auth-sdk-generator.git
cd auth-sdk-generator
```

2. Set up an opam switch (if you don't already have one with OCaml 5.1+):
```bash
opam switch create . 5.4.1 --no-install
eval $(opam env)
```

3. Install OCaml dependencies:
```bash
opam update
opam install . --deps-only -y
```

4. Build the generator:
```bash
make build
```

5. Verify everything works:
```bash
make test
```

### Basic Usage

1. Create an auth specification file (e.g., `myapp.auth`):
```
name = "MyApp Auth"
client_id = "your-client-id"
authorize_url = "https://provider.com/oauth2/authorize"
token_url = "https://provider.com/oauth2/token"
scopes = "read,write,profile"
```

2. Generate an SDK:
```bash
# TypeScript
./_build/default/bin/main.exe --lang typescript specs/myapp.auth output/typescript

# Python
./_build/default/bin/main.exe --lang python specs/myapp.auth output/python
```

## Development Workflow

### Common Commands

```bash
# Build the OCaml generator
make build

# Run tests
make test

# Generate TypeScript SDK from prototype.auth
make generate

# Generate Python SDK from prototype.auth
make generate-python

# Full development cycle (build + generate + validate)
make dev           # For TypeScript
make dev-python    # For Python

# Clean all artifacts
make clean
```

### CLI Options

```bash
# Use offline mode (fallback versions)
./_build/default/bin/main.exe --offline specs/myapp.auth output/dir

# Skip validation (faster, use with caution)
./_build/default/bin/main.exe --no-validate specs/myapp.auth output/dir

# Specify language explicitly
./_build/default/bin/main.exe --lang python specs/myapp.auth output/dir
```

## Generated SDK Features

### TypeScript SDK
- Complete OAuth 2.0 client with PKCE support
- TypeScript strict mode with comprehensive types
- Jest testing setup
- Build and development scripts
- Automatic token refresh
- Error handling and retry logic

### Python SDK
- Modern async/await implementation
- Type hints and dataclasses
- pytest testing framework
- mypy type checking
- Automatic token management
- Comprehensive error handling

## DSL Specification Format

The `.auth` specification uses a simple key=value format:

```
name = "Application Name"
client_id = "your-client-id"
client_secret = "your-client-secret"  # Optional
authorize_url = "https://oauth.provider.com/authorize"
token_url = "https://oauth.provider.com/token"
redirect_uri = "http://localhost:8080/callback"
scopes = "scope1,scope2,scope3"
```

### Supported Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | SDK name and package name |
| `client_id` | Yes | OAuth client ID |
| `client_secret` | No | OAuth client secret (if needed) |
| `authorize_url` | Yes | Authorization endpoint URL |
| `token_url` | Yes | Token exchange endpoint URL |
| `redirect_uri` | No | OAuth callback URL |
| `scopes` | No | Comma-separated list of scopes |

## Project Structure

```
auth-sdk-generator/
├── bin/                 # CLI entry point
├── lib/
│   ├── ast/            # Core types and AST
│   ├── parsers/        # DSL parser
│   ├── generators/     # Language-specific generators
│   ├── validators/     # Code validation
│   └── utils/          # Version management, helpers
├── specs/              # Example specifications
├── doc/                # Documentation and ADRs
└── test/               # OCaml test suite
```

## Architecture

The generator follows a pipeline architecture:

1. **Parse**: DSL file → AST representation
2. **Validate**: Check specification completeness
3. **Generate**: AST → Language-specific code
4. **Validate Output**: In-memory code validation
5. **Write**: Save validated SDK to disk

For detailed architecture decisions, see the [ADRs](doc/architecture/decisions/).

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup

1. Fork the repository
2. Clone and install dependencies:
   ```bash
   git clone https://github.com/<you>/auth-sdk-generator.git
   cd auth-sdk-generator
   opam update && opam install . --deps-only -y
   make build && make test
   ```
3. Create a feature branch (`git checkout -b feature/amazing-feature`)
4. Make your changes
5. Run tests (`make test`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## Roadmap

- [x] TypeScript SDK generator
- [x] Python SDK generator
- [ ] Java SDK generator (Issue #5)
- [ ] Go SDK generator (Issue #6)
- [ ] Rust SDK generator
- [ ] C# SDK generator
- [ ] Ruby SDK generator
- [ ] OIDC support
- [ ] OAuth 3.0/GNAP support

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

Built with OCaml and powered by:
- [Dune](https://dune.build/) - OCaml build system
- [Core](https://opensource.janestreet.com/core/) - Alternative standard library
- [Yojson](https://github.com/ocaml-community/yojson) - JSON parsing
- [ppx_deriving](https://github.com/ocaml-ppx/ppx_deriving) - Type-driven code generation

## Support

- 📖 [Documentation](doc/)
- 🐛 [Report Issues](https://github.com/acald-creator/auth-sdk-generator/issues)
- 💬 [Discussions](https://github.com/acald-creator/auth-sdk-generator/discussions)

---

**Current Status**: Beta (v1.0.0-beta.1) - Core functionality complete, seeking feedback!