#include "fsm/fsm.hpp"

void FSM::handle_state_loiter() {
    // TODO: define what ends the loiter (timer, mission command, etc.) and transitions to LANDING.
    publish_vehicle_command(px4_msgs::msg::VehicleCommand::VEHICLE_CMD_NAV_LOITER_UNLIM);
}
