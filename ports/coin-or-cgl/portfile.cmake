vcpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO "Mizux/Cgl"
        REF "75d3994612b992a48574d297479d8aede41611a2" #0.60.9
        SHA512 63a637016c5f6463d580f1de017872f3e4b2e617bbdb761582c1ec3bda24df974a09020782db7d8187db00d66775e4c4d1caa1a450f06b7d7e14fc84b9b0dc6b
        HEAD_REF master
)
if (VCPKG_TARGET_IS_WINDOWS)
    vcpkg_check_linkage(ONLY_STATIC_LIBRARY)
endif()
vcpkg_cmake_configure(
        SOURCE_PATH "${SOURCE_PATH}"
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/Cgl PACKAGE_NAME Cgl)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_copy_pdbs()

file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
