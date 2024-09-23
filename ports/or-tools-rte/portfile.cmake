vcpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO "google/or-tools"
        REF "b39974ba209d9f5215bdc363bb8ad9625443d618" #9.10
        SHA512 183440e6a2d821a643664bd8ca5e72a0c75adfa5cab76fa2647a3b04f0006ac86761147ae1a7e72edb6c90b626c11b3bc5ea3d5135aa654e3be7b6028ded08a2
        HEAD_REF master
)

vcpkg_from_github(
        OUT_SOURCE_PATH RTE_SOURCE_PATH
        REPO "rte-france/or-tools-rte"
        REF "2c1808ff73511108257c5c9f27f1b710a76a11fa" #9.10-rte1.2
        SHA512 183440e6a2d821a643664bd8ca5e72a0c75adfa5cab76fa2647a3b04f0006ac86761147ae1a7e72edb6c90b626c11b3bc5ea3d5135aa654e3be7b6028ded08a2
        HEAD_REF master
)

vcpkg_find_acquire_program(PYTHON3)
get_filename_component(PYTHON3_DIR "${PYTHON3}" DIRECTORY)
vcpkg_add_to_path("${PYTHON3_DIR}")

FILE(COPY ${RTE_SOURCE_PATH}/ortools DESTINATION ${SOURCE_PATH} USE_SOURCE_PERMISSIONS)
FILE(COPY ${RTE_SOURCE_PATH}/cmake_patches DESTINATION ${SOURCE_PATH} USE_SOURCE_PERMISSIONS)
FILE(COPY_FILE ${RTE_SOURCE_PATH}/patch.py DESTINATION ${SOURCE_PATH} USE_SOURCE_PERMISSIONS)
FILE(COPY_FILE ${RTE_SOURCE_PATH}/patch_utils.py DESTINATION ${SOURCE_PATH} USE_SOURCE_PERMISSIONS)
vcpkg_execute_required_process(COMMAND ${PYTHON3} ${RTE_SOURCE_PATH}/patch.py
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
