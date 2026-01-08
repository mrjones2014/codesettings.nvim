cli_script := "lua/codesettings/build/cli.lua"
nvim_run := "nvim --headless --noplugin --clean --cmd 'set rtp^=.' -l "
nvim_build := nvim_run + cli_script

# Fetch updated VS Code schemas and generate Lua type annotations
build target="":
    @{{ nvim_build }} build {{ target }}

# Delete all JSON schemas and other generated files
clean target="":
    @{{ nvim_build }} clean {{ target }}

check-generated-files:
    #!/usr/bin/env bash
    if [ "$CI" != "true" ]; then
      exit 0
    fi
    echo "Building and checking generated files..."
    just build doc
    if ! git diff --quiet; then
      echo
      echo "Error: Generated files are out of date."
      echo
      echo "Modified files:"
      git diff --name-only
      echo
      echo "Please run the following command and commit the results to your PR:"
      echo "just build doc"
      echo
      exit 1
    fi
    echo "All generated files are up to date."
    echo

# Run all checks (linting, formatting, tests)
check: && check-generated-files test
    @echo "Checking justfile formatting with \`just --fmt --check\`..."
    @just --unstable --fmt --check # TODO remove when --fmt is stablized
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
    @{{ nvim_run }} ./spec/runner.lua

# Run benchmarks and regenerate report
bench:
    @echo "Running benchmarks..."
    @{{ nvim_run }} ./bench/run.lua
    @echo "Generated report at ./bench/report.md"
