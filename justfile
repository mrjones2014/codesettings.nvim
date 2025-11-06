# Fetch updated VS Code schemas
build:
  @nvim --cmd "set rtp^=." -l "lua/codesettings/build/init.lua"

# Delete all VS Code schemas
clean:
  @echo "Cleaning build artifacts..."
  @nvim --cmd "set rtp^=." --cmd "lua require('codesettings.build.schemas').clean()" --cmd "qa!"

# Run all checks (linting, formatting, tests)
check: && test
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
