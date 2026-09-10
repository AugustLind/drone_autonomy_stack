#pragma once
#include "rclcpp/rclcpp.hpp"
#include <px4_msgs/msg/vehicle_command.hpp>
#include <px4_msgs/msg/vehicle_status.hpp>
#include <px4_msgs/msg/vehicle_local_position.hpp>

enum class State {DISARMED, ARMING, TAKEOFF, LOITER, LANDING};

class FSM : public rclcpp::Node {
public:
    FSM();

private:
    void fsm_loop();
    void publish_vehicle_command(uint16_t command, float param1 = 0.0f, float param2 = 0.0f, float param4 = 0.0f,
                                 float param5 = 0.0f, float param6 = 0.0f, float param7 = 0.0f);

    void handle_state_disarmed();
    void handle_state_arming();
    void handle_state_takeoff();
    void handle_state_loiter();
    void handle_state_land();

    void vehicle_status_callback(const px4_msgs::msg::VehicleStatus::SharedPtr msg);
    void vehicle_local_position_callback(const px4_msgs::msg::VehicleLocalPosition::SharedPtr msg);

    // Shared variables
    State current_state_;
    uint8_t arming_state_{px4_msgs::msg::VehicleStatus::ARMING_STATE_DISARMED};
    float current_altitude_{0.0f};
    float target_takeoff_alt_{2.5f};

    rclcpp::TimerBase::SharedPtr timer_;
    rclcpp::Publisher<px4_msgs::msg::VehicleCommand>::SharedPtr cmd_pub_;
    rclcpp::Subscription<px4_msgs::msg::VehicleStatus>::SharedPtr vehicle_status_sub_;
    rclcpp::Subscription<px4_msgs::msg::VehicleLocalPosition>::SharedPtr vehicle_local_position_sub_;
};
