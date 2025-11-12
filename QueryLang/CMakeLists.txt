cmake_minimum_required(VERSION 3.17)
project(QueryLang)

set (CMAKE_CXX_STANDARD 20)

include(FetchContent)

set (DBUILD_TESTS=OFF)
# peg-cpp
FetchContent_Declare(
	cpppeglib
	GIT_REPOSITORY https://github.com/yhirose/cpp-peglib.git
    TAG 1.9.1
)
FetchContent_MakeAvailable(cpppeglib)

include_directories(source)
include_directories(${CMAKE_CURRENT_BINARY_DIR})

add_executable(query_lang 
	src/main.cpp
)

target_link_libraries(query_lang peglib)

