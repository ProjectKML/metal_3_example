cmake_minimum_required(VERSION 3.21)
project(metal_3_example)

set(CMAKE_CXX_STANDARD 23)

set(METAL_3_EXAMPLE_SOURCE_DIR ${CMAKE_SOURCE_DIR}/src)
file(GLOB_RECURSE METAL_3_EXAMPLE_MM_SOURCE_FILES ${METAL_3_EXAMPLE_SOURCE_DIR}/*.mm)
file(GLOB_RECURSE METAL_3_EXAMPLE_CPP_SOURCE_FILES ${METAL_3_EXAMPLE_SOURCE_DIR}/*.c**)
file(GLOB_RECURSE METAL_3_EXAMPLE_HPP_SOURCE_FILES ${METAL_3_EXAMPLE_SOURCE_DIR}/*.h**)

find_package(SDL2 REQUIRED)
include_directories(${SDL2_INCLUDE_DIRS}/../)

add_executable(metal_3_example ${METAL_3_EXAMPLE_MM_SOURCE_FILES} ${METAL_3_EXAMPLE_CPP_SOURCE_FILES} ${METAL_3_EXAMPLE_HPP_SOURCE_FILES})
target_link_libraries(metal_3_example ${SDL2_LIBRARIES} "-framework Foundation" "-framework QuartzCore" "-framework Metal")