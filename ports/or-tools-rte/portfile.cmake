vcpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO "google/or-tools"
        REF "ed94162b910fa58896db99191378d3b71a5313af" #9.11
        SHA512 92fa365a0d309896cffd56e000d7e0711311890290358e5c1132b340d9216e55e7d412ccd735baa0f8ddc2127e0f0a68725350ad432ae80467fed7c6a6729eda
        HEAD_REF master
)

set(VERSION 9.11-rte1.3)
vcpkg_download_distfile(ARCHIVE
        URLS "https://github.com/rte-france/or-tools-rte/archive/refs/tags/v${VERSION}.tar.gz"
        FILENAME "or-tools-v${VERSION}.tar.gz"
        SHA512 13bd1177c8a46b496ac94dac41c10bbacf3353eab02be6222c75878fb063935ed103c7c90af8f66d36478fd3c2b425a391ee673f5621c973eb4229d76387f6b4
)

vcpkg_execute_required_process(COMMAND tar xzvf "${ARCHIVE}" --strip-components=1 -C "${SOURCE_PATH}" --exclude "CMakeLists.txt"
        WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}
        LOGNAME "ortools-untar"
)

vcpkg_find_acquire_program(PYTHON3)
get_filename_component(PYTHON3_DIR "${PYTHON3}" DIRECTORY)
vcpkg_add_to_path("${PYTHON3_DIR}")

vcpkg_execute_required_process(COMMAND ${PYTHON3} patch.py
        WORKING_DIRECTORY "${SOURCE_PATH}"
        LOGNAME "patch-install"
)

vcpkg_execute_required_process(COMMAND ls
        WORKING_DIRECTORY "${SOURCE_PATH}"
        LOGNAME "patch-install"
)

vcpkg_cmake_configure(
        SOURCE_PATH "${SOURCE_PATH}"
        OPTIONS
        -DBUILD_DEPS=OFF #All dependencies should be provided by user or through vcpkg
        -DBUILD_SAMPLES=OFF
        -DBUILD_SHARED_LIBS=OFF
        -DUSE_SCIP=ON
        -DUSE_GLPK=ON
        -DBUILD_FLATZINC=OFF
        -DBUILD_EXAMPLES=OFF
        -DBUILD_ZLIB=OFF
        -DUSE_HIGHS=OFF
        -DBUILD_TESTING=OFF
        -DBUILD_SIRIUS=OFF
        -DUSE_SIRIUS=ON
)

vcpkg_cmake_install()

file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
