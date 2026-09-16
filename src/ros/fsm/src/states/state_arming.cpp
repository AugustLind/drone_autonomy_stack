#include "fsm/fsm.hpp"

void FSM::handle_state_arming() {
  publish_vehicle_command(px4_msgs::msg::VehicleCommand::VEHICLE_CMD_COMPONENT_ARM_DISARM, 1.0f);

  if (arming_state_ == px4_msgs::msg::VehicleStatus::ARMING_STATE_ARMED) {
    RCLCPP_INFO(this->get_logger(), "Armed! Moving to Takeoff.");
    current_state_ = State::TAKEOFF;
  }
}
