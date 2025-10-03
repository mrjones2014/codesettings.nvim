build:
  nvim --cmd "set rtp^=." -l "lua/codesettings/build/init.lua"
clean:
  nvim --cmd "set rtp^=." --cmd "lua require('codesettings.build').clean()" --cmd "qa!"
