#include "fsm/fsm.hpp"

void FSM::handle_state_disarmed() {
    // TODO: gate this on a real arm trigger (service/topic) instead of arming immediately.
    const auto kDisarmSettleDuration = rclcpp::Duration::from_seconds(2.0);

    if (!disarm_settle_started_) {
        RCLCPP_INFO(this->get_logger(), "Disarmed. Settling before requesting arm.");
        disarm_settle_start_ = this->get_clock()->now();
        disarm_settle_started_ = true;
        return;
    }

    if ((this->get_clock()->now() - disarm_settle_start_) < kDisarmSettleDuration) {
        return;
    }

    RCLCPP_INFO(this->get_logger(), "Requesting arm.");
    disarm_settle_started_ = false;
    current_state_ = State::ARMING;
}
