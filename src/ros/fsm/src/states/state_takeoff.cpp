#include "fsm/fsm.hpp"
#include <cmath>

void FSM::handle_state_takeoff() {
    // param4 (yaw), param5 (lat), param6 (lon) must be NaN so PX4 takes off in place
    // using the current heading/position instead of navigating to yaw 0 / lat 0 / lon 0.
    publish_vehicle_command(px4_msgs::msg::VehicleCommand::VEHICLE_CMD_NAV_TAKEOFF, 0.0f, 0.0f, NAN, NAN, NAN,
                            target_takeoff_alt_);

    if (std::abs(current_altitude_) >= (target_takeoff_alt_ - 0.2f)) {
        RCLCPP_INFO(this->get_logger(), "Altitude reached. Loitering.");
        current_state_ = State::LOITER;
    }
}
