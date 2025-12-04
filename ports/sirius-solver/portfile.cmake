vcpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO "rte-france/sirius-solver"
        REF "antares-integration-v1.9"
        SHA512 22eb724c5b04b81a633aeb38e34647187a04d100ec183672d0069a764f0cb5bda0a6350553e0ace43ad44437ba517ad563fe34b29bab4b250f419c25e4300b8f
        HEAD_REF main
)

vcpkg_cmake_configure(
        SOURCE_PATH "${SOURCE_PATH}/src"
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(PACKAGE_NAME sirius_solver CONFIG_PATH cmake)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_copy_pdbs()

file(INSTALL "${SOURCE_PATH}/LICENSE.TXT" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
