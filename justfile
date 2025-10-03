build:
  nvim --cmd "set rtp^=." -l "lua/codesettings/build/init.lua"
clean:
  @echo "Cleaning build artifacts..."
  nvim --cmd "set rtp^=." --cmd "lua require('codesettings.build.schemas').clean()" --cmd "qa!"
