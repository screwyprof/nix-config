.PHONY: test test-verbose clean install check

# Default target
all: test

# Run tests with Bats
test:
	@echo "Running alias-teacher tests with Bats..."
	@nix-shell --run "bats test/alias-teacher.bats"


# Run tests with verbose output
test-verbose:
	@echo "Running alias-teacher tests with verbose output..."
	@nix-shell --run "bats -v test/alias-teacher.bats"

# Run all test suites
test-all: test test-integration

test-integration:
	@echo "Running integration tests..."
	@if [ -f ./test/test_runner.zsh ]; then \
		./test/test_runner.zsh; \
	else \
		echo "Integration tests not available"; \
	fi

# Test with nix build (includes check phase)
nix-test:
	nix build .#alias-teacher --check

# Clean test artifacts
clean:
	@echo "Cleaning up..."
	@rm -f .YSU_BUFFER

# Install plugin locally (for testing)
install-local:
	@echo "Installing to ~/.local/share/zsh/plugins/alias-teacher..."
	@mkdir -p ~/.local/share/zsh/plugins/alias-teacher
	@cp alias-teacher.plugin.zsh ~/.local/share/zsh/plugins/alias-teacher/
	@echo "Plugin installed. Add to your .zshrc:"
	@echo "  source ~/.local/share/zsh/plugins/alias-teacher/alias-teacher.plugin.zsh"

# Check code quality (requires nix)
check:
	@echo "Running checks..."
	@nix flake check --no-build 2>/dev/null || echo "Flake check not available outside of nix-config repo"

# Help
help:
	@echo "Available targets:"
	@echo "  test         - Run basic tests"
	@echo "  test-verbose - Run tests with verbose output"
	@echo "  test-all     - Run all test suites"
	@echo "  nix-test     - Test with nix build (includes check phase)"
	@echo "  clean        - Clean test artifacts"
	@echo "  install-local- Install plugin locally for testing"
	@echo "  check        - Run code quality checks"
	@echo "  help         - Show this help"