vcpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO "google/or-tools"
        REF "b8e881fbde473a9e33e0dac475e498559eb0459d" #9.12
        SHA512 ac0b5c9870a2b887610540266a5260c6756052ed5a212b0ad78447e8e9651e1fb3b6abe271b7758d4913397000c083b9e4e56297c259c58b8b40562463c63f78
        HEAD_REF master
)

set(VERSION 9.12-rte1.1)
vcpkg_download_distfile(ARCHIVE
        URLS "https://github.com/rte-france/or-tools-rte/archive/refs/tags/v${VERSION}.tar.gz"
        FILENAME "or-tools-v${VERSION}.tar.gz"
        SHA512 64194a126c4b470415c3ca04bd9e8412cdb2b42e891b8584c97dcddca1a5af934ca08f6781f83f10bebba5dc7e58f9948d0656079a4818fc82eb6f0225dd26aa
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
        -DUSE_SIRIUS=ON
)

vcpkg_cmake_install()

file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
