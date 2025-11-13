cmake_minimum_required(VERSION 3.20.0)
project(tool)

find_package(LLVM REQUIRED CONFIG)
find_package(Clang REQUIRED CONFIG)

add_executable(tool main.cpp)
set_target_properties(tool PROPERTIES CXX_STANDARD 23)
target_compile_options(tool PRIVATE -fno-rtti)

target_include_directories(tool SYSTEM PRIVATE ${LLVM_INCLUDE_DIRS})
separate_arguments(LLVM_DEFINITIONS_LIST NATIVE_COMMAND ${LLVM_DEFINITIONS})
target_compile_definitions(tool PRIVATE ${LLVM_DEFINITIONS_LIST})

llvm_map_components_to_libnames(llvm_libs support core irreader frontendOpenMP)

target_link_libraries(tool PRIVATE
  ${llvm_libs}
  clangBasic clangFrontend clangTooling clangSerialization
  clangASTMatchers clangAST)