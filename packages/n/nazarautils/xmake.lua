package("nazarautils")
    set_kind("library", {headeronly = true})
    set_homepage("https://github.com/NazaraEngine/NazaraUtils")
    set_description("Header-only utility library for Nazara projects")
    set_license("MIT")
    set_policy("package.strict_compatibility", true)

    add_urls("https://github.com/NazaraEngine/NazaraUtils.git")

    add_versions("2023.05.29", "d9fbe4fa4acc10a5b2c20051bd6ab3d20a84cadb")

    on_install(function (package)
        import("package.tools.xmake").install(package)
    end)

    on_test(function (package)
        assert(package:check_cxxsnippets({test = [[
            void test() {
                Nz::Bitset<> bitset;
                bitset.UnboundedSet(42);
                bitset.Reverse();
            }
        ]]}, {configs = {languages = "c++17"}, includes = "NazaraUtils/Bitset.hpp"}))
    end)
