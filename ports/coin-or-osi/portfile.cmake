vcpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO "Mizux/Osi"
        REF "ab3d7568384854c7c2bcd53f608c7b4b31a3f033" #0.108.11
        SHA512 7b9e621594c246141b5f9912a19dbc14f95d4d35d9a8d5e47b2b7fa730b3e62aba3a138fb1dd55ff39a63e91318e7a328a02a82fa20185ebaf8f09171010c922
        HEAD_REF master
)
if (VCPKG_TARGET_IS_WINDOWS)
    vcpkg_check_linkage(ONLY_STATIC_LIBRARY)
endif()
vcpkg_cmake_configure(
        SOURCE_PATH "${SOURCE_PATH}"
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/Osi PACKAGE_NAME Osi)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_copy_pdbs()

file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
