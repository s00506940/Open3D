include(ExternalProject)

if (WIN32)
    set(LIBDIR "lib")
else()
    include(GNUInstallDirs)
    set(LIBDIR ${CMAKE_INSTALL_LIBDIR})
endif()

# TODO: don't build samples

set(FILAMENT_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/filament/filament)
set(FILAMENT_TMP_INSTALL_DIR ${CMAKE_BINARY_DIR}/filament-install)
set(FILAMENT_TMP_LIB_DIR ${FILAMENT_TMP_INSTALL_DIR}/lib/x86_64)

ExternalProject_Add(
    ext_filament
    PREFIX filament
    SOURCE_DIR ${FILAMENT_SOURCE_DIR}
    UPDATE_COMMAND ""
    CMAKE_ARGS
        -DCMAKE_C_COMPILER=${FILAMENT_CC_PATH}
        -DCMAKE_CXX_COMPILER=${FILAMENT_CXX_PATH}
        -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
        -DCMAKE_C_FLAGS=${DCMAKE_C_FLAGS}
        -DCMAKE_C_FLAGS_RELEASE=${CMAKE_C_FLAGS_RELEASE}
        -DCMAKE_C_FLAGS_DEBUG=${CMAKE_C_FLAGS_DEBUG}
        -DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}
        -DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG}
        -DCMAKE_INSTALL_PREFIX=${FILAMENT_TMP_INSTALL_DIR}
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
        -DFILAMENT_SUPPORTS_VULKAN=${USE_VULKAN}
        -DUSE_STATIC_CRT=${STATIC_WINDOWS_RUNTIME}
)

set(filament_INCLUDE_DIRS ${3RDPARTY_INSTALL_PREFIX}/include/filament)

if (WIN32)
    add_custom_target(filament_copy
        COMMAND xcopy /s /i /y /q \"include\" \"${filament_INCLUDE_DIRS}\"
        COMMAND xcopy /s /i /y /q \"lib/x86_64\" \"${3RDPARTY_INSTALL_PREFIX}/lib\"
        COMMAND xcopy /s /i /y /q \"bin\" \"${3RDPARTY_INSTALL_PREFIX}/bin\"
        WORKING_DIRECTORY ${FILAMENT_TMP_INSTALL_DIR}
        DEPENDS ext_filament
        )
else()
    add_custom_target(filament_copy
        COMMAND cp -a include ${filament_INCLUDE_DIRS}
        COMMAND cp -a lib/${CMAKE_SYSTEM_PROCESSOR}/* ${3RDPARTY_INSTALL_PREFIX}/lib
        COMMAND cp -a bin/* ${3RDPARTY_INSTALL_PREFIX}/bin
        WORKING_DIRECTORY ${FILAMENT_TMP_INSTALL_DIR}
        DEPENDS ext_filament
        )
endif()

add_library(filament_combined INTERFACE)
add_dependencies(filament_combined filament_copy)

set(filament_LIB_FILES filament_combined)

set(filament_COMBINED_LIBS filameshio filament filamat_lite filaflat filabridge geometry backend bluegl ibl image meshoptimizer smol-v utils)
if (USE_VULKAN)
    set(filament_COMBINED_LIBS ${filament_COMBINED_LIBS} bluevk)
endif()

target_link_libraries(filament_combined INTERFACE ${filament_COMBINED_LIBS})

## If MSVC, the OUTPUT_NAME was set to filament-static
#if(MSVC)
#    set(lib_name "filament-static")
#else()
#    set(lib_name "filament")
#endif()

# For linking with Open3D after installation
set(filament_LIBRARIES ${filament_LIB_FILES} ${FREETYPE_LIBRARIES})

#target_include_directories(filament SYSTEM INTERFACE
#target_include_directories(filament SYSTEM INTERFACE
#    ${3RDPARTY_INSTALL_PREFIX}/include/filament
#)

#if (NOT BUILD_SHARED_LIBS)
#    install(FILES ${filament_LIB_FILES} libfilament_all.a
#            DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)
#endif()

add_dependencies(build_all_3rd_party_libs filament_combined)

if (WIN32)
elseif (APPLE)
    find_library(CORE_VIDEO CoreVideo)
    find_library(QUARTZ_CORE QuartzCore)
    find_library(OPENGL_LIBRARY OpenGL)
    find_library(METAL_LIBRARY Metal)
    find_library(APPKIT_LIBRARY AppKit)
    list(APPEND filament_LIBRARIES ${CORE_VIDEO} ${QUARTZ_CORE} ${OPENGL_LIBRARY} ${METAL_LIBRARY} ${APPKIT_LIBRARY})

    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fobjc-link-runtime")
else ()
    # These are needed by Clang on Linux
    list(APPEND filament_LIBRARIES pthread dl c++)
endif()
