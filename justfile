cli_script := "lua/codesettings/build/cli.lua"
nvim_run := "nvim --headless --noplugin --clean --cmd 'set rtp^=.' -l "
nvim_build := nvim_run + cli_script

# Fetch updated VS Code schemas and generate Lua type annotations
build target="":
    @{{ nvim_build }} build {{ target }}

# Delete all JSON schemas and other generated files
clean target="":
    @{{ nvim_build }} clean {{ target }}

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
