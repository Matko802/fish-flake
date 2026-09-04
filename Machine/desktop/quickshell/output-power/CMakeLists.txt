cmake_minimum_required(VERSION 3.20)
project(quickshell-output-power LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml)
find_package(PkgConfig REQUIRED)
pkg_check_modules(WAYLAND_CLIENT REQUIRED IMPORTED_TARGET wayland-client)

find_program(WAYLAND_SCANNER NAMES wayland-scanner REQUIRED)

set(PROTOCOL_FILE "${CMAKE_CURRENT_SOURCE_DIR}/protocol/wlr-output-power-management-unstable-v1.xml")
set(GEN_DIR "${CMAKE_CURRENT_BINARY_DIR}/protocol")
file(MAKE_DIRECTORY "${GEN_DIR}")

set(PROTOCOL_BASE "${GEN_DIR}/wlr-output-power-management-unstable-v1-client-protocol")
execute_process(
  COMMAND "${WAYLAND_SCANNER}" client-header "${PROTOCOL_FILE}" "${PROTOCOL_BASE}.h"
  RESULT_VARIABLE scanner_header_result)
if(scanner_header_result)
  message(FATAL_ERROR "wayland-scanner client-header failed")
endif()
execute_process(
  COMMAND "${WAYLAND_SCANNER}" private-code "${PROTOCOL_FILE}" "${PROTOCOL_BASE}.c"
  RESULT_VARIABLE scanner_code_result)
if(scanner_code_result)
  message(FATAL_ERROR "wayland-scanner private-code failed")
endif()

add_library(quickshelloutputpower MODULE
  src/plugin.cpp
  src/output_power.cpp
  "${PROTOCOL_BASE}.c"
)

target_include_directories(quickshelloutputpower PRIVATE "${GEN_DIR}")
target_link_libraries(quickshelloutputpower PRIVATE
  Qt6::Core
  Qt6::Qml
  PkgConfig::WAYLAND_CLIENT
)

install(TARGETS quickshelloutputpower
  LIBRARY DESTINATION lib/qt-6/qml/Quickshell/Power
)
install(FILES qmldir
  DESTINATION lib/qt-6/qml/Quickshell/Power
)