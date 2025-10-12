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

# Run all tests, or a subset matching a pattern
test:
  @echo "Running unit tests..."
  @nvim --headless --noplugin --clean -l ./spec/runner.lua
