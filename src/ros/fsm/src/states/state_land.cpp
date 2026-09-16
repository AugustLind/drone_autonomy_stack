#include "fsm/fsm.hpp"

void FSM::handle_state_land() {
  publish_vehicle_command(px4_msgs::msg::VehicleCommand::VEHICLE_CMD_NAV_LAND);

  if (arming_state_ == px4_msgs::msg::VehicleStatus::ARMING_STATE_DISARMED) {
    RCLCPP_INFO(this->get_logger(), "Landed and disarmed.");
    current_state_ = State::DISARMED;
  }
}
