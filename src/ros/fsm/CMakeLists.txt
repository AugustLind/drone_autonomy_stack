cmake_minimum_required(VERSION 3.8)
project(fsm)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# find dependencies
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(px4_msgs REQUIRED)
find_package(navigator REQUIRED)
find_package(drone_interface REQUIRED)

add_executable(
  fsm_node
  src/main.cpp
  src/fsm.cpp
  src/states/state_disarm.cpp
  src/states/state_arming.cpp
  src/states/state_takeoff.cpp
  src/states/state_search.cpp
  src/states/state_return.cpp
  src/states/state_land.cpp)

target_include_directories(
  fsm_node PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
                  $<INSTALL_INTERFACE:include>)

ament_target_dependencies(fsm_node rclcpp px4_msgs navigator drone_interface)

install(TARGETS fsm_node DESTINATION lib/${PROJECT_NAME})

ament_package()
