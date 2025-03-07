vcpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO "rte-france/sirius-solver"
        REF "antares-integration-v1.7"
        SHA512 39c5935a3b96d58fa35e7b20ef0bc65d78fca0f6ba9c01824e121c5d309d27b9c77b4fc4976c28f18e835596fb598355aee21bd524541bd01a26846973fd8ca4
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
