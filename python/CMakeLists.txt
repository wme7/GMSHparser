find_package(Python COMPONENTS Interpreter Development.Module REQUIRED)
find_package(pybind11 CONFIG REQUIRED)

pybind11_add_module(_gmshparser MODULE src/bindings.cpp)
target_link_libraries(_gmshparser PRIVATE GMSHparser::GMSHparser)
target_compile_features(_gmshparser PRIVATE cxx_std_17)

install(TARGETS _gmshparser DESTINATION gmshparser)
