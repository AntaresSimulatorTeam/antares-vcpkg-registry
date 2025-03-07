vcpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO "google/or-tools"
        REF "b39974ba209d9f5215bdc363bb8ad9625443d618" #9.10
        SHA512 183440e6a2d821a643664bd8ca5e72a0c75adfa5cab76fa2647a3b04f0006ac86761147ae1a7e72edb6c90b626c11b3bc5ea3d5135aa654e3be7b6028ded08a2
        HEAD_REF master
)

set(VERSION 9.11-rte1.2)
vcpkg_download_distfile(ARCHIVE
        URLS "https://github.com/rte-france/or-tools-rte/archive/refs/tags/v${VERSION}.tar.gz"
        FILENAME "or-tools-v${VERSION}.tar.gz"
        SHA512 a2a03b11112e0f966e9f75d3b729f28cf3dd0e9273b45083ce92c18bccff0694278d8f552818e7a23b1a3c3ceb3555cb0768b879ed776aa51dcadd20db108e15
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
