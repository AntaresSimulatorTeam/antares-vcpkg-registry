vcpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO "Mizux/CoinUtils"
        REF "6fc9606ffd6b2120ba211bfec6fe99ab3db5dfd6" #2.11.12
        SHA512 9a7c27aff86be7fb403c7c48b269cd03c81452bd38bf32ae9c697f967b6dabeb7cd27d5ba1437fd6c8ab372f87ae5198dc537c4064bdc4bf8d220a6bc228689a
        HEAD_REF master
)

if (VCPKG_TARGET_IS_WINDOWS)
    vcpkg_check_linkage(ONLY_STATIC_LIBRARY)
endif()

vcpkg_cmake_configure(
        SOURCE_PATH "${SOURCE_PATH}"
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/CoinUtils)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_copy_pdbs()

file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
