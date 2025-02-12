vcpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO "Mizux/Cbc"
        REF "61358ddd277362186547caff464f2266c26ced10" #2.10.12
        SHA512 04c51775b03a8c537545b4fa6b19eaa4a8722f89965528a91d05f8bb73d73d23dfb29aa24956be49d537668e2074016785601d3323d293b48da52354a302c14d
        HEAD_REF master
)
if (VCPKG_TARGET_IS_WINDOWS)
    vcpkg_check_linkage(ONLY_STATIC_LIBRARY)
endif()
vcpkg_cmake_configure(
        SOURCE_PATH "${SOURCE_PATH}"
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/Cbc PACKAGE_NAME Cbc)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_copy_pdbs()

file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
