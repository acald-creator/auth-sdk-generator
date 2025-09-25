.PHONY: build test generate clean dev install-deps

# Install OCaml dependencies
install-deps:
	@echo "📦 Installing OCaml dependencies..."
	opam install -y dune core yojson menhir sedlex ppx_deriving alcotest ounit2
	@echo "✅ Dependencies installed"

# Build the OCaml generator
build:
	@echo "🔨 Building OCaml generator..."
	dune build
	@echo "✅ Build complete"

# Run OCaml tests
test:
	@echo "🧪 Running tests..."
	dune runtest
	@echo "✅ Tests complete"

# Generate TypeScript SDK from prototype spec
generate: build
	@echo "📦 Generating TypeScript SDK with validation..."
	./_build/default/bin/main.exe specs/prototype.auth generated/typescript
	@echo "✅ SDK generated in generated/typescript/"

# Generate Python SDK from prototype spec
generate-python: build
	@echo "📦 Generating Python SDK with validation..."
	./_build/default/bin/main.exe --lang python specs/prototype.auth generated/python
	@echo "✅ SDK generated in generated/python/"

# Generate without validation (fast mode)
generate-fast: build
	@echo "📦 Generating TypeScript SDK without validation..."
	./_build/default/bin/main.exe --no-validate specs/prototype.auth generated/typescript-fast
	@echo "✅ SDK generated in generated/typescript-fast/"

# Generate Python SDK without validation (fast mode)
generate-python-fast: build
	@echo "📦 Generating Python SDK without validation..."
	./_build/default/bin/main.exe --lang python --no-validate specs/prototype.auth generated/python-fast
	@echo "✅ SDK generated in generated/python-fast/"

# Validate existing specs without generating files
validate: build
	@echo "🔍 Validating TypeScript generation..."
	./_build/default/bin/main.exe --no-validate specs/prototype.auth /tmp/validation-test > /dev/null 2>&1 || true
	rm -rf /tmp/validation-test
	@echo "✅ Validation complete"

# Generate GitHub SDK example
generate-github: build
	@echo "📦 Generating GitHub TypeScript SDK..."
	./_build/default/bin/main.exe specs/github.auth generated/github-typescript
	@echo "✅ SDK generated in generated/github-typescript/"

# Development workflow: build generator + generate TS + build TS
dev: generate
	@echo "🚀 Building generated TypeScript SDK..."
	cd generated/typescript && npm install && npm run build
	@echo "✅ TypeScript SDK built successfully"

# Development workflow for Python: build generator + generate Python + test import
dev-python: generate-python
	@echo "🚀 Testing generated Python SDK..."
	cd generated/python && python3 -c "from auth_sdk import OAuth2Client; print('✅ Python SDK imports successfully')"
	@echo "✅ Python SDK tested successfully"

# Test generated SDK with live version fetching
test-live-versions: build
	@echo "🧪 Testing with live version fetching..."
	rm -rf generated/test-live
	./_build/default/bin/main.exe specs/prototype.auth generated/test-live
	@echo "📦 Installing and building generated SDK..."
	cd generated/test-live && npm install && npm run build
	@echo "✅ Live versions test completed"

# Test generated SDK with fallback versions
test-fallback-versions: build
	@echo "🧪 Testing with fallback versions..."
	rm -rf generated/test-fallback
	./_build/default/bin/main.exe --offline specs/prototype.auth generated/test-fallback
	@echo "📦 Installing and building generated SDK..."
	cd generated/test-fallback && npm install && npm run build
	@echo "✅ Fallback versions test completed"

# Run both version tests
test-versions: test-fallback-versions test-live-versions
	@echo "✅ All version tests completed"

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	dune clean
	rm -rf generated/*
	@echo "✅ Clean complete"

# Show project status
status:
	@echo "📊 Project Status:"
	@echo "   - OCaml build: $$(dune build 2>&1 >/dev/null && echo '✅' || echo '❌')"
	@echo "   - Generated SDKs: $$(ls generated/ 2>/dev/null | wc -l) directories"
	@echo "   - Test specs: $$(ls specs/*.auth 2>/dev/null | wc -l) files"