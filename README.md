# Cloning

```bash
# Clone with dependencies
git clone --recurse-submodules -j8 https://github.com/piotrek-szczygiel/bgfx-imgui-template
```

## Updating dependencies

```bash
# Update submodules
git submodule update --init --recursive
```

# Building

## Requirements

- C++ compiler
- xmake

You can install [xmake](https://xmake.io/) on your machine using these one-liners:

```bash
# Unix systems
bash <(curl -fsSL https://xmake.io/shget.text)

# Windows Powershell
Invoke-Expression (Invoke-Webrequest 'https://xmake.io/psget.text' -UseBasicParsing).Content
```

If you are on Linux you may also need OpenGL and X11 development libraries.

## Usage

```bash
# Optionally: use debug mode
xmake config -m debug

# Build game
xmake

# Compile shaders
xmake shaders

# Run
xmake run
```

## Compiling shaders

Shaderc is present as an .exe file in the bin directory.  
If you wish to compile shaders on unix platforms you have to build the compiler first.

```bash
# Build shaderc
xmake -F shaderc.lua
```

It will automatically copy itself to bin directory.
