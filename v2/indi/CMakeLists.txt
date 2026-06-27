cmake_minimum_required(VERSION 3.5)
project(seestar-nano-dome CXX)

set(CMAKE_CXX_STANDARD 17)

find_package(INDI REQUIRED)

include_directories(${INDI_INCLUDE_DIR})
include_directories(${CMAKE_CURRENT_SOURCE_DIR})

add_executable(indi_seestar_nano_dome seestar_nano_dome.cpp)
target_link_libraries(indi_seestar_nano_dome ${INDI_LIBRARIES} pthread)

install(TARGETS indi_seestar_nano_dome RUNTIME DESTINATION bin)

# INDI driver XML descriptor
install(FILES indi_seestar_nano_dome.xml
        DESTINATION ${INDI_DATA_DIR})
