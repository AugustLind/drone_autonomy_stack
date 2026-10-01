#include "fsm/fsm.hpp"

void FSM::handle_state_disarmed() {
  const auto kDisarmSettleDuration = rclcpp::Duration::from_seconds(disarm_settle_time_);

  if (!disarm_settle_started_) {
    RCLCPP_INFO(this->get_logger(), "Disarmed. Settling before requesting arm.");
    disarm_settle_start_ = this->get_clock()->now();
    disarm_settle_started_ = true;
    return;
  }

  if ((this->get_clock()->now() - disarm_settle_start_) < kDisarmSettleDuration) {
    return;
  }

  if (mission_pending_) {
    RCLCPP_INFO(this->get_logger(), "Requesting arm.");
    disarm_settle_started_ = false;
    current_state_ = State::ARMING;
  }
}
