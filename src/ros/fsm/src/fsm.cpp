#include "fsm/fsm.hpp"

FSM::FSM() : Node("fsm_node"), current_state_(State::DISARMED) {
  cmd_pub_ = this->create_publisher<px4_msgs::msg::VehicleCommand>(
      "/fmu/in/vehicle_command", 10);

  auto qos = rclcpp::QoS(rclcpp::KeepLast(10)).best_effort();
  vehicle_status_sub_ = this->create_subscription<px4_msgs::msg::VehicleStatus>(
      "/fmu/out/vehicle_status_v1", qos,
      std::bind(&FSM::vehicle_status_callback, this, std::placeholders::_1));
  vehicle_local_position_sub_ =
      this->create_subscription<px4_msgs::msg::VehicleLocalPosition>(
          "/fmu/out/vehicle_local_position_v1", qos,
          std::bind(&FSM::vehicle_local_position_callback, this,
                    std::placeholders::_1));

  timer_ = this->create_wall_timer(std::chrono::milliseconds(100),
                                   std::bind(&FSM::fsm_loop, this));
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
  case State::LOITER:
    handle_state_loiter();
    break;
  case State::LANDING:
    handle_state_land();
    break;
  }
}

void FSM::publish_vehicle_command(uint16_t command, float param1, float param2,
                                  float param4, float param5, float param6,
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

void FSM::vehicle_status_callback(
    const px4_msgs::msg::VehicleStatus::SharedPtr msg) {
  arming_state_ = msg->arming_state;
}

void FSM::vehicle_local_position_callback(
    const px4_msgs::msg::VehicleLocalPosition::SharedPtr msg) {
  current_altitude_ = msg->z;
}
