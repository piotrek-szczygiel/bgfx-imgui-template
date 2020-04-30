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
- [xmake](https://xmake.io/)

You can install xmake on your machine using these one-liners:

```bash
# Unix systems
bash <(curl -fsSL https://xmake.io/shget.text)

# Windows Powershell
Invoke-Expression (Invoke-Webrequest 'https://xmake.io/psget.text' -UseBasicParsing).Content
```

## Usage

```bash
# Build game
xmake

# Compile shaders
xmake shaders

# Run
xmake run
```

## Compiling shaders

Shaderc is present as an .exe file in bin directory.  
If you wish to compile shaders on unix platforms you have to compile it first.

```bash
# Build shaderc
xmake -F shaderc.lua
```

It will automatically copy itself to bin directory.
