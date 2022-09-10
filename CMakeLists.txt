cmake_minimum_required(VERSION 3.21)
project(metal_3_example)

set(CMAKE_CXX_STANDARD 23)

set(METAL_3_EXAMPLE_INCLUDE_DIR ${CMAKE_SOURCE_DIR}/include)
set(METAL_3_EXAMPLE_SOURCE_DIR ${CMAKE_SOURCE_DIR}/src)

file(GLOB_RECURSE METAL_3_EXAMPLE_CPP_SOURCE_FILES ${METAL_3_EXAMPLE_SOURCE_DIR}/*.c**)
file(GLOB_RECURSE METAL_3_EXAMPLE_HPP_SOURCE_FILES ${METAL_3_EXAMPLE_SOURCE_DIR}/*.h**)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin)

find_package(SDL2 REQUIRED)
include_directories(${METAL_3_EXAMPLE_INCLUDE_DIR} ${SDL2_INCLUDE_DIRS}/../)

add_executable(metal_3_example ${METAL_3_EXAMPLE_CPP_SOURCE_FILES} ${METAL_3_EXAMPLE_HPP_SOURCE_FILES}
        # fastobj
        ${METAL_3_EXAMPLE_INCLUDE_DIR}/fast_obj/fast_obj.c

        # meshoptimizer
        ${METAL_3_EXAMPLE_INCLUDE_DIR}/meshoptimizer/allocator.cpp
        ${METAL_3_EXAMPLE_INCLUDE_DIR}/meshoptimizer/clusterizer.cpp
        ${METAL_3_EXAMPLE_INCLUDE_DIR}/meshoptimizer/indexcodec.cpp
        ${METAL_3_EXAMPLE_INCLUDE_DIR}/meshoptimizer/indexgenerator.cpp
        ${METAL_3_EXAMPLE_INCLUDE_DIR}/meshoptimizer/overdrawanalyzer.cpp
        ${METAL_3_EXAMPLE_INCLUDE_DIR}/meshoptimizer/overdrawoptimizer.cpp
        ${METAL_3_EXAMPLE_INCLUDE_DIR}/meshoptimizer/simplifier.cpp
        ${METAL_3_EXAMPLE_INCLUDE_DIR}/meshoptimizer/spatialorder.cpp
        ${METAL_3_EXAMPLE_INCLUDE_DIR}/meshoptimizer/stripifier.cpp
        ${METAL_3_EXAMPLE_INCLUDE_DIR}/meshoptimizer/vcacheanalyzer.cpp
        ${METAL_3_EXAMPLE_INCLUDE_DIR}/meshoptimizer/vcacheoptimizer.cpp
        ${METAL_3_EXAMPLE_INCLUDE_DIR}/meshoptimizer/vertexcodec.cpp
        ${METAL_3_EXAMPLE_INCLUDE_DIR}/meshoptimizer/vertexfilter.cpp
        ${METAL_3_EXAMPLE_INCLUDE_DIR}/meshoptimizer/vfetchanalyzer.cpp
        ${METAL_3_EXAMPLE_INCLUDE_DIR}/meshoptimizer/vfetchoptimizer.cpp)
target_link_libraries(metal_3_example ${SDL2_LIBRARIES} "-framework Foundation" "-framework QuartzCore" "-framework Metal")