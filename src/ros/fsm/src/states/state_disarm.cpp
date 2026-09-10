#include "fsm/fsm.hpp"

void FSM::handle_state_disarmed() {
    // TODO: gate this on a real arm trigger (service/topic) instead of arming immediately.
    RCLCPP_INFO(this->get_logger(), "Disarmed. Requesting arm.");
    current_state_ = State::ARMING;
}
