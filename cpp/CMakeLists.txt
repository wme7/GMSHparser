cmake_minimum_required(VERSION 3.16)

project(GMSHparser VERSION 0.1.0 LANGUAGES CXX)

add_library(GMSHparser INTERFACE)
add_library(GMSHparser::GMSHparser ALIAS GMSHparser)

target_include_directories(GMSHparser
  INTERFACE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

target_compile_features(GMSHparser INTERFACE cxx_std_17)

if(GMSHPARSER_BUILD_TESTS)
  if(EXISTS "${CMAKE_SOURCE_DIR}/meshes")
    set(_GMSHPARSER_DEFAULT_MESH_DIR "${CMAKE_SOURCE_DIR}/meshes")
  else()
    set(_GMSHPARSER_DEFAULT_MESH_DIR "${CMAKE_SOURCE_DIR}/../meshes")
  endif()

  set(GMSHPARSER_MESH_DIR "${_GMSHPARSER_DEFAULT_MESH_DIR}" CACHE PATH
      "Directory containing test .msh files")

  foreach(test_target IN ITEMS TestGMSHparserV2 TestGMSHparserV4 TestElementTypes)
    add_executable(${test_target} tests/${test_target}.cpp)
    target_include_directories(${test_target} PRIVATE tests)
    target_link_libraries(${test_target} PRIVATE GMSHparser::GMSHparser)
    target_compile_definitions(${test_target} PRIVATE
      GMSHPARSER_MESH_DIR="${GMSHPARSER_MESH_DIR}"
    )
    add_test(NAME ${test_target} COMMAND ${test_target})
  endforeach()
endif()

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

install(TARGETS GMSHparser EXPORT GMSHparserTargets)
install(DIRECTORY include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

install(EXPORT GMSHparserTargets
  FILE GMSHparserTargets.cmake
  NAMESPACE GMSHparser::
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/GMSHparser
)

configure_package_config_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/cmake/GMSHparserConfig.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/GMSHparserConfig.cmake
  INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/GMSHparser
)

write_basic_package_version_file(
  ${CMAKE_CURRENT_BINARY_DIR}/GMSHparserConfigVersion.cmake
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY SameMajorVersion
)

install(FILES
  ${CMAKE_CURRENT_BINARY_DIR}/GMSHparserConfig.cmake
  ${CMAKE_CURRENT_BINARY_DIR}/GMSHparserConfigVersion.cmake
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/GMSHparser
)
