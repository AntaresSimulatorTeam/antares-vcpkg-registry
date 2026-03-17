vcpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO "google/or-tools"
        REF "7c52f28d700bd4f9f3048372a58d38ff291ee6e1" #9.13
        SHA512 e0a962972f692d4c4e0169a6f33c977ba3b9fdbac7a82d7439c7d2c21e9765203076f89e79c8b4a043589f79d858fda3ac8d7e1991f13618e7ddf47f88b6605a
        HEAD_REF master
)

set(VERSION 9.13-rte1.3)
vcpkg_download_distfile(ARCHIVE
        URLS "https://github.com/rte-france/or-tools-rte/archive/refs/tags/v${VERSION}.tar.gz"
        FILENAME "or-tools-v${VERSION}.tar.gz"
        SHA512 9918d998752b3a002c7a041fa68e8120dfdf8276363b87cdff7d6742044f45c93ea3e9c0ab1aa724b2db1a4917d3313e1e8ec020a26ea21885977193f7c706fa
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
        -DUSE_SCIP=OFF #Can't find libscip, don't know why
        -DUSE_GLPK=ON
        -DBUILD_FLATZINC=OFF
        -DBUILD_EXAMPLES=OFF
        -DBUILD_ZLIB=OFF
        -DUSE_HIGHS=ON
        -DBUILD_TESTING=OFF
        -DUSE_SIRIUS=ON
)

vcpkg_cmake_install()

file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
