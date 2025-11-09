# Fetch updated VS Code schemas
build target="":
  @nvim --cmd "set rtp^=." -l "lua/codesettings/build/init.lua" {{target}}

# Delete all VS Code schemas
clean:
  @echo "Cleaning build artifacts..."
  @nvim --cmd "set rtp^=." --cmd "lua require('codesettings.build.schemas').clean()" --cmd "qa!"

ci-checks:
  #!/usr/bin/env bash
  if [ "$CI" != "true" ]; then
    exit 0
  fi
  echo "Checking if config type annotations are up to date..."
  just build config >/dev/null 2>&1
  PATH_TO_CHECK="./lua/codesettings/generated/codesettings-config-schema.lua"
  if ! git diff --quiet $PATH_TO_CHECK; then
    echo "Error: Generated configuration schema is out of date. Please run 'just build config' to update it."
    echo
    git --no-pager diff $PATH_TO_CHECK
    echo
    exit 1
  fi
  echo

# Run all checks (linting, formatting, tests)
check: && ci-checks test
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
