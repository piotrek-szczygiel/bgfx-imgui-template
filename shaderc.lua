add_rules("mode.debug", "mode.release")

local BGFX  = "third_party/bgfx/"
local BIMG  = "third_party/bimg/"
local BX    = "third_party/bx/"

local SHADERC        = BGFX .. "tools/shaderc/"
local GLSL_OPTIMIZER = BGFX .. "3rdparty/glsl-optimizer/"
local FCPP           = BGFX .. "3rdparty/fcpp/"
local GLSLANG        = BGFX .. "3rdparty/glslang/"
local SPIRV_HEADERS  = BGFX .. "3rdparty/spirv-headers/"
local SPIRV_CROSS    = BGFX .. "3rdparty/spirv-cross/"
local SPIRV_HEADERS  = BGFX .. "3rdparty/spirv-headers/"
local SPIRV_TOOLS    = BGFX .. "3rdparty/spirv-tools/"


target("shaderc")
    set_kind("binary")
    set_default(true)
    add_deps("fcpp", "glsl-optimizer", "glslang", "spirv-cross", "spirv-tools")

    add_defines("__STDC_FORMAT_MACROS")

    add_files(
        SHADERC .. "*.cpp",
        BX      .. "src/*.cpp|amalgamated.cpp|crtnone.cpp",
        BGFX    .. "src/shader_spirv.cpp",
        BGFX    .. "src/vertexlayout.cpp"
    )
    add_includedirs(
        BX   .. "include",
        BX   .. "3rdparty",
        BGFX .. "include",
        BIMG .. "include",
        FCPP,
        GLSL_OPTIMIZER .. "src/glsl",
        GLSLANG,
        GLSLANG .. "glslang/Include",
        GLSLANG .. "glslang/Public",
        SPIRV_TOOLS .. "include",
        SPIRV_CROSS,
        SPIRV_CROSS .. "include"
    )

    if is_os("windows") then
        add_links("user32", "gdi32")
        add_includedirs(BX .. "include/compat/msvc")
    elseif is_os("linux") then
        add_links("dl", "pthread")
    elseif is_os("macosx") then
        add_includedirs(BX .. "include/compat/osx")
    end


target("fcpp")
    set_kind("static")

    add_defines(
        "NINCLUDE=64",
        "NWORK=65536",
        "NBUFF=65536",
        "OLD_PREPROCESSOR=0"
    )

    add_files(FCPP .. "*.c|usecpp.c")
    add_includedirs(FCPP)



target("glsl-optimizer")
    set_kind("static")

    add_files(
        GLSL_OPTIMIZER .. "src/glsl/glcpp/*.c",
        GLSL_OPTIMIZER .. "src/util/*.c",
        GLSL_OPTIMIZER .. "src/mesa/program/*.c",
        GLSL_OPTIMIZER .. "src/mesa/main/*.c",
        GLSL_OPTIMIZER .. "src/glsl/*.cpp|main.cpp",
        GLSL_OPTIMIZER .. "src/glsl/*.c"
    )
    add_includedirs(
        GLSL_OPTIMIZER .. "include",
        GLSL_OPTIMIZER .. "src/mesa",
        GLSL_OPTIMIZER .. "src/mapi",
        GLSL_OPTIMIZER .. "src/glsl",
        GLSL_OPTIMIZER .. "src"
    )

    if is_os("windows") then
        add_defines(
            "__STDC__",
            "__STDC_VERSION__=199901L",
            "strdup=_strdup",
            "alloca=_alloca",
            "isascii=__isascii"
        )
    end


target("glslang")
    set_kind("static")

    add_defines(
        "ENABLE_OPT=1",
        "ENABLE_HLSL=1"
    )

    add_files(
        GLSLANG .. "glslang/GenericCodeGen/*.cpp",
        GLSLANG .. "glslang/MachineIndependent/*.cpp",
        GLSLANG .. "glslang/MachineIndependent/preprocessor/*.cpp",
        GLSLANG .. "hlsl/*.cpp",
        GLSLANG .. "SPIRV/*.cpp",
        GLSLANG .. "OGLCompilersDLL/*.cpp"
    )
    add_includedirs(
        GLSLANG,
        GLSLANG     .. "glslang/Include",
        GLSLANG     .. "glslang/Public",
        SPIRV_TOOLS .. "include",
        SPIRV_TOOLS .. "source"
    )

    if is_os("windows") then
        add_files(GLSLANG .. "glslang/OSDependent/Windows/ossource.cpp")
    else
        add_files(GLSLANG .. "glslang/OSDependent/Unix/ossource.cpp")
    end


target("spirv-cross")
    set_kind("static")

    add_defines("SPIRV_CROSS_EXCEPTIONS_TO_ASSERTIONS")

    add_files(SPIRV_CROSS .. "*.cpp")
    add_includedirs(
        SPIRV_CROSS,
        SPIRV_CROSS .. "include"
    )


target("spirv-tools")
    set_kind("static")

    add_files(
        SPIRV_TOOLS .. "source/*.cpp",
        SPIRV_TOOLS .. "source/opt/*.cpp",
        SPIRV_TOOLS .. "source/reduce/*.cpp",
        SPIRV_TOOLS .. "source/util/*.cpp",
        SPIRV_TOOLS .. "source/val/*.cpp"
    )
    add_includedirs(
        SPIRV_TOOLS,
        SPIRV_TOOLS   .. "include",
        SPIRV_TOOLS   .. "include/generated",
        SPIRV_TOOLS   .. "source",
        SPIRV_HEADERS .. "include"
    )

