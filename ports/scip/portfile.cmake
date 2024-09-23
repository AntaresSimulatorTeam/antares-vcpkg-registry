vcpkg_download_distfile(ARCHIVE
        URLS "https://www.scipopt.org/download/release/scip-9.1.0.tgz"
        FILENAME "scip-9.1.0.tgz"
        SHA512 fa44545665bcdd371051c565f4bb437225e87b6448b67c728bacc4bbc5104d57a5d3a6e3d1628410b0760862e495b5fbb0c5311bcba725dd43308bc39b6c5006
)

#Replicate part of vcpkg_extract_archive
# Hash the archive hash along with the patches. Take the first 10 chars of the hash
file(SHA512 "${ARCHIVE}" patchset_hash)
set(working_directory "${CURRENT_BUILDTREES_DIR}/src")
string(SUBSTRING "${patchset_hash}" 0 10 patchset_hash)
cmake_path(APPEND working_directory "scip_9_1_0-${patchset_hash}"
        OUTPUT_VARIABLE SOURCE_PATH
)
message(STATUS "SOURCE_PATH: ${SOURCE_PATH}")
file(MAKE_DIRECTORY "${SOURCE_PATH}")
vcpkg_execute_required_process(COMMAND tar xzvf "${ARCHIVE}" --strip-components=1 -C "${SOURCE_PATH}"
        WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}
        LOGNAME "scip-untar"
)

vcpkg_cmake_configure(
        SOURCE_PATH "${SOURCE_PATH}"
        OPTIONS
        -DSHARED=OFF
        -DREADLINE=OFF
        -DGMP=OFF
        -DPAPILO=OFF
        -DZIMPL=OFF
        -DIPOPT=OFF
        -DAMPL=OFF
        -DTPI="tny"
        -DEXPRINT="none"
        -DLPS="none"
        -DSYM="none"
)

vcpkg_cmake_install()

file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
