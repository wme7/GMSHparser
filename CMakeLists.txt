cmake_minimum_required(VERSION 3.16)

project(GMSHparserRepo LANGUAGES CXX)

option(GMSHPARSER_BUILD_TESTS "Build C++ parser tests" ON)
option(GMSHPARSER_BUILD_PYTHON "Build Python bindings" OFF)

if(GMSHPARSER_BUILD_TESTS)
  enable_testing()
endif()

add_subdirectory(cpp)

if(SKBUILD OR GMSHPARSER_BUILD_PYTHON)
  add_subdirectory(python)
endif()
