## Downloading dependencies

```bash
# Update submodules
git submodule update --init --recursive
```

## Requirements

- C++ compiler
- [xmake](https://xmake.io/)

## Usage

```bash
# Build
xmake

# Then run
xmake run
```

## Compiling shaders

If you don't have shaderc already in your PATH, you have to compile it first.
After compilation, executable should be present inside build directory.

```bash
# Build shaderc
xmake -F shaderc.lua

# Make it available from everywhere
xmake install -o /usr/local -F shaderc.lua
```

Remember to copy the executable to directory that is present in PATH environment variable.  
If you are on Linux you can just install it to something like `/usr/local/`.

Now after you build your game, shaders will be automatically compiled
for every platform specified in xmake.lua `SHADER_TARGETS` variable.
