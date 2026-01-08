cli_script := "lua/codesettings/build/cli.lua"
nvim_build := "nvim --cmd 'set rtp^=.' -l " + cli_script

# Fetch updated VS Code schemas and generate Lua type annotations
build target="":
    @{{ nvim_build }} build {{ target }}

# Delete all JSON schemas and other generated files
clean target="":
    @{{ nvim_build }} clean {{ target }}

# Build all generated files and check for diffs
check-generated-files:
    #!/usr/bin/env bash
    if [ "$CI" != "true" ]; then
      exit 0
    fi
    echo "Running builds to check for outdated generated files..."
    just build config >/dev/null 2>&1
    just build docs >/dev/null 2>&1
    just build-vimdoc >/dev/null 2>&1
    if ! git diff --quiet; then
      echo "Error: Generated files are out of date. Please run the following commands and commit the results to your PR:"
      echo
      git --no-pager diff --name-only
      echo
      echo "Commands to update:"
      echo "  just build config"
      echo "  just build docs"
      echo
      git --no-pager diff
      exit 1
    fi
    echo "All generated files are up to date."
    echo

# Run all checks (linting, formatting, tests)
check: && check-generated-files test
    @echo "Checking justfile formatting with \`just --fmt --check\`..."
    @just --unstable --fmt --check # TODO remove --unstable when --fmt is stablized
    @echo "Checking formatting with Stylua..."
    @stylua --check ./lua/ ./spec/
    @echo
    @echo "Checking lints with Selene..."
    @selene ./lua/ ./spec/
    @echo

# Run all tests
test:
    @echo "Running unit tests..."
    @echo
    @nvim --headless --noplugin --clean -l ./spec/runner.lua

# Run benchmarks and regenerate report
bench:
    @echo "Running benchmarks..."
    @nvim --noplugin --clean --cmd "set rtp^=." -l ./bench/run.lua
    @echo "Generated report at ./bench/report.md"
