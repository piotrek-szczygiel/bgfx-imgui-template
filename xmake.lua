
-- add modes: debug and release
add_rules("mode.debug", "mode.release")

local IMGUI = "third_party/imgui/"
local BGFX = "third_party/bgfx/"
local BIMG = "third_party/bimg/"
local BX = "third_party/bx/"
local GLFW = "third_party/glfw/"

function bx_compat()
    if is_os("windows") then
        add_includedirs(BX .. "include/compat/msvc")
    elseif is_os("macosx") then
        add_includedirs(BX .. "include/compat/osx")
    end
end

target("game")
    set_kind("binary")
    add_files("src/*.cpp")
    add_deps("bgfx", "bimg", "bx", "glfw", "imgui")
    add_includedirs(
        BGFX .. "include",
        BX .. "include",
        GLFW .. "include",
        IMGUI
    )
    add_links("bgfx", "bimg", "bx", "glfw", "imgui")
    if is_os("windows") then
        -- add_links("gdi32", "kernel32", "user32", "shell32", "psapi")
        add_links("gdi32", "user32", "shell32")
    elseif is_os("linux") then
        add_links("dl", "GL", "pthread", "X11")
    elseif is_os("macosx") then
        add_links("QuartzCore.framework", "Metal.framework", "Cocoa.framework", "IOKit.framework", "CoreVideo.framework")
    end
    bx_compat()

target("bgfx")
    set_kind("static")
    add_defines("__STDC_FORMAT_MACROS")
    add_files(BGFX .. "src/*.cpp")
    del_files(BGFX .. "src/amalgamated.cpp")
    add_includedirs(
        BX .. "include",
        BIMG .. "include",
        BGFX .. "include",
        BGFX .. "3rdparty",
        BGFX .. "3rdparty/dxsdk/include",
        BGFX .. "3rdparty/khronos"
    )
    if is_mode("debug") then
        add_defines("BGFX_CONFIG_DEBUG=1")
    end
    if is_os("windows") then
        add_defines("_CRT_SECURE_NO_WARNINGS")
        del_files(
            BGFX .. "src/glcontext_glx.cpp",
            BGFX .. "src/glcontext_egl.cpp"
        )
    elseif is_os("macosx") then
        add_files(BGFX .. "src/*.mm")
    end
    bx_compat()

target("bimg")
    set_kind("static")
    add_files(
        BIMG .. "src/image.cpp",
        BIMG .. "src/image_gnf.cpp",
        BIMG .. "3rdparty/astc-codec/src/decoder/*.cc"
    )
    add_includedirs(
        BX .. "include",
        BIMG .. "include",
        BIMG .. "3rdparty/astc-codec",
        BIMG .. "3rdparty/astc-codec/include"
    )
    bx_compat()

target("bx")
    set_kind("static")
    add_defines("__STDC_FORMAT_MACROS")
    add_files(BX .. "src/*.cpp")
    del_files(
        BX .. "src/amalgamated.cpp",
        BX .. "src/crtnone.cpp"
    )
    add_includedirs(
        BX .. "3rdparty",
        BX .. "include"
    )
    if is_os("windows") then
        add_defines("_CRT_SECURE_NO_WARNINGS")
    end
    bx_compat()

target("glfw")
    set_kind("static")
    add_files(
        GLFW .. "src/context.c",
        GLFW .. "src/egl_context.c",
        GLFW .. "src/init.c",
        GLFW .. "src/input.c",
        GLFW .. "src/monitor.c",
        GLFW .. "src/osmesa_context.c",
        GLFW .. "src/vulkan.c",
        GLFW .. "src/window.c"
    )
    add_includedirs(GLFW .. "include")
    if is_os("windows") then
        add_defines("_GLFW_WIN32", "_CRT_SECURE_NO_WARNINGS")
        add_files(
            GLFW .. "src/win32_*.c",
            GLFW .. "src/wgl_context.c"
        )
    elseif is_os("linux") then
        add_defines("_GLFW_X11")
        add_files(
            GLFW .. "src/glx_context.c",
            GLFW .. "src/linux*.c",
            GLFW .. "src/posix*.c",
            GLFW .. "src/x11*.c",
            GLFW .. "src/xkb*.c"
        )
    elseif is_os("macosx") then
        add_defines("_GLFW_COCOA")
        add_files(
            GLFW .. "src/cocoa_*.c",
            GLFW .. "src/cocoa_*.m",
            GLFW .. "src/posix_thread.c",
            GLFW .. "src/nsgl_context.m",
            GLFW .. "src/egl_context.c",
            GLFW .. "src/nsgl_context.m",
            GLFW .. "src/osmesa_context.c"
        )
    end

target("imgui")
    set_kind("static")
    add_files(IMGUI .. "*.cpp")

--
-- FAQ
--
-- You can enter the project directory firstly before building project.
--
--   $ cd projectdir
--
-- 1. How to build project?
--
--   $ xmake
--
-- 2. How to configure project?
--
--   $ xmake f -p [macosx|linux|iphoneos ..] -a [x86_64|i386|arm64 ..] -m [debug|release]
--
-- 3. Where is the build output directory?
--
--   The default output directory is `./build` and you can configure the output directory.
--
--   $ xmake f -o outputdir
--   $ xmake
--
-- 4. How to run and debug target after building project?
--
--   $ xmake run [targetname]
--   $ xmake run -d [targetname]
--
-- 5. How to install target to the system directory or other output directory?
--
--   $ xmake install
--   $ xmake install -o installdir
--
-- 6. Add some frequently-used compilation flags in xmake.lua
--
-- @code
--    -- add debug and release modes
--    add_rules("mode.debug", "mode.release")
--
--    -- add macro defination
--    add_defines("NDEBUG", "_GNU_SOURCE=1")
--
--    -- set warning all as error
--    set_warnings("all", "error")
--
--    -- set language: c99, c++11
--    set_languages("c99", "c++11")
--
--    -- set optimization: none, faster, fastest, smallest
--    set_optimize("fastest")
--
--    -- add include search directories
--    add_includedirs("/usr/include", "/usr/local/include")
--
--    -- add link libraries and search directories
--    add_links("tbox")
--    add_linkdirs("/usr/local/lib", "/usr/lib")
--
--    -- add system link libraries
--    add_syslinks("z", "pthread")
--
--    -- add compilation and link flags
--    add_cxflags("-stdnolib", "-fno-strict-aliasing")
--    add_ldflags("-L/usr/local/lib", "-lpthread", {force = true})
--
-- @endcode
--
-- 7. If you want to known more usage about xmake, please see https://xmake.io
--
