#include "fsm/fsm.hpp"

#include <cmath>

FSM::FSM() : Node("fsm_node") {
  cmd_pub_ = this->create_publisher<px4_msgs::msg::VehicleCommand>("/fmu/in/vehicle_command", 10);
  offboard_control_mode_pub_ = this->create_publisher<px4_msgs::msg::OffboardControlMode>(
      "/fmu/in/offboard_control_mode", 10);
  trajectory_setpoint_pub_ =
      this->create_publisher<px4_msgs::msg::TrajectorySetpoint>("/fmu/in/trajectory_setpoint", 10);

  auto qos = rclcpp::QoS(rclcpp::KeepLast(10)).best_effort();
  vehicle_status_sub_ = this->create_subscription<px4_msgs::msg::VehicleStatus>(
      "/fmu/out/vehicle_status_v1", qos,
      std::bind(&FSM::vehicle_status_callback, this, std::placeholders::_1));
  vehicle_local_position_sub_ = this->create_subscription<px4_msgs::msg::VehicleLocalPosition>(
      "/fmu/out/vehicle_local_position_v1", qos,
      std::bind(&FSM::vehicle_local_position_callback, this, std::placeholders::_1));

  timer_ = this->create_wall_timer(std::chrono::milliseconds(100), std::bind(&FSM::fsm_loop, this));
}

void FSM::fsm_loop() {
  switch (current_state_) {
    case State::DISARMED:
      handle_state_disarmed();
      break;
    case State::ARMING:
      handle_state_arming();
      break;
    case State::TAKEOFF:
      handle_state_takeoff();
      break;
    case State::SEARCH:
      handle_state_search();
      break;
    case State::LANDING:
      handle_state_land();
      break;
  }
}

void FSM::publish_vehicle_command(
    uint16_t command, float param1, float param2, float param4, float param5, float param6,
    float param7) {
  px4_msgs::msg::VehicleCommand msg{};
  msg.param1 = param1;
  msg.param2 = param2;
  msg.param4 = param4;
  msg.param5 = param5;
  msg.param6 = param6;
  msg.param7 = param7;
  msg.command = command;
  msg.target_system = 1;
  msg.target_component = 1;
  msg.source_system = 1;
  msg.source_component = 1;
  msg.from_external = true;
  msg.timestamp = this->get_clock()->now().nanoseconds() / 1000;
  cmd_pub_->publish(msg);
}

void FSM::vehicle_status_callback(const px4_msgs::msg::VehicleStatus::SharedPtr &msg) {
  arming_state_ = msg->arming_state;
  nav_state_ = msg->nav_state;
}

void FSM::vehicle_local_position_callback(
    const px4_msgs::msg::VehicleLocalPosition::SharedPtr &msg) {
  current_x_ = msg->x;
  current_y_ = msg->y;
  current_altitude_ = msg->z;
  ref_alt_ = msg->ref_alt;
}

void FSM::publish_offboard_control_mode() {
  px4_msgs::msg::OffboardControlMode msg{};
  msg.position = true;
  msg.timestamp = this->get_clock()->now().nanoseconds() / 1000;
  offboard_control_mode_pub_->publish(msg);
}

void FSM::publish_trajectory_setpoint(const Waypoint &target) {
  px4_msgs::msg::TrajectorySetpoint msg{};
  msg.position = {
      static_cast<float>(target.x), static_cast<float>(target.y), static_cast<float>(-target.z)};
  msg.timestamp = this->get_clock()->now().nanoseconds() / 1000;
  trajectory_setpoint_pub_->publish(msg);
}

bool FSM::reached_waypoint(const Waypoint &target) const {
  constexpr float kAcceptanceRadius = 1.5f;
  float dx = current_x_ - static_cast<float>(target.x);
  float dy = current_y_ - static_cast<float>(target.y);
  float dz = current_altitude_ - static_cast<float>(-target.z);
  return std::sqrt(dx * dx + dy * dy + dz * dz) < kAcceptanceRadius;
}
