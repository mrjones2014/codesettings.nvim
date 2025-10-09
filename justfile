build:
  nvim --cmd "set rtp^=." -l "lua/codesettings/build/init.lua"
clean:
  @echo "Cleaning build artifacts..."
  nvim --cmd "set rtp^=." --cmd "lua require('codesettings.build.schemas').clean()" --cmd "qa!"
check: && test
  @echo "Checking formatting with Stylua..."
  @stylua --check ./lua/ ./spec/
  @echo
  @echo "Checking lints with Selene..."
  @selene ./lua/ ./spec/
  @echo
test:
  @echo "Running unit tests..."
  @nvim --headless --noplugin --clean -l ./spec/runner.lua
