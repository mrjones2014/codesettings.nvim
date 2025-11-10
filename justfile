cli_script := "lua/codesettings/build/cli.lua"
nvim_build := "nvim --cmd 'set rtp^=.' -l " + cli_script

# Fetch updated VS Code schemas and generate Lua type annotations
build target="":
  @{{nvim_build}} build {{target}}

# Delete all JSON schemas and other generated files
clean target="":
  @{{nvim_build}} clean {{target}}

ci-checks:
  #!/usr/bin/env bash
  if [ "$CI" != "true" ]; then
    exit 0
  fi
  echo "Checking if config type annotations are up to date..."
  just build config >/dev/null 2>&1
  path_to_check="lua/codesettings/generated/codesettings-config-schema.lua"
  if ! git diff --quiet "$path_to_check"; then
    echo "Error: Generated configuration schema is out of date. Please run 'just build config' to update it and commit the results to your PR."
    echo
    git --no-pager diff "$path_to_check"
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
