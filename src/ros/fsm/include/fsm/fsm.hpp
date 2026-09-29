#pragma once
#include <cstdint>
#include <px4_msgs/msg/offboard_control_mode.hpp>
#include <px4_msgs/msg/trajectory_setpoint.hpp>
#include <px4_msgs/msg/vehicle_command.hpp>
#include <px4_msgs/msg/vehicle_local_position.hpp>
#include <px4_msgs/msg/vehicle_status.hpp>
#include <vector>

#include "navigator/lawnmower.hpp"
#include "navigator/path_follower.hpp"
#include "rclcpp/rclcpp.hpp"

enum class State : std::uint8_t { DISARMED, ARMING, TAKEOFF, SEARCH, RETURN, LANDING };
enum class ControlMode : std::uint8_t { POSITION, VELOCITY };

class FSM : public rclcpp::Node {
public:
  FSM();

private:
  void fsm_loop();
  void publish_vehicle_command(
      uint16_t command, float param1 = 0.0f, float param2 = 0.0f, float param4 = 0.0f,
      float param5 = 0.0f, float param6 = 0.0f, float param7 = 0.0f);
  void publish_offboard_control_mode(ControlMode mode = ControlMode::POSITION);
  void publish_trajectory_setpoint(const Waypoint& target);
  void publish_velocity_setpoint(const VelocityCmd& cmd);
  bool local_position_fresh() const;
  bool reached_waypoint(const Waypoint& target) const;

  void handle_state_disarmed();
  void handle_state_arming();
  void handle_state_takeoff();
  void handle_state_search();
  void handle_state_return();
  void handle_state_land();

  void vehicle_status_callback(const px4_msgs::msg::VehicleStatus::ConstSharedPtr& msg);
  void vehicle_local_position_callback(
      const px4_msgs::msg::VehicleLocalPosition::ConstSharedPtr& msg);

  // Shared variables
  State current_state_{State::DISARMED};
  uint8_t arming_state_{px4_msgs::msg::VehicleStatus::ARMING_STATE_DISARMED};
  uint8_t nav_state_{px4_msgs::msg::VehicleStatus::NAVIGATION_STATE_MANUAL};
  float current_x_{0.0f};
  float current_y_{0.0f};
  float current_altitude_{0.0f};
  float ref_alt_{0.0f};
  rclcpp::Time last_local_position_time_;
  float target_takeoff_alt_{2.5f};

  // Search state
  std::vector<Waypoint> search_path_;
  size_t search_waypoint_idx_{0};

  // Disarmed state: settle briefly after landing before requesting arm
  // again, so PX4's post-landing health checks have time to clear.
  bool disarm_settle_started_{false};
  rclcpp::Time disarm_settle_start_;

  rclcpp::TimerBase::SharedPtr timer_;
  rclcpp::Publisher<px4_msgs::msg::VehicleCommand>::SharedPtr cmd_pub_;
  rclcpp::Publisher<px4_msgs::msg::OffboardControlMode>::SharedPtr offboard_control_mode_pub_;
  rclcpp::Publisher<px4_msgs::msg::TrajectorySetpoint>::SharedPtr trajectory_setpoint_pub_;
  rclcpp::Subscription<px4_msgs::msg::VehicleStatus>::SharedPtr vehicle_status_sub_;
  rclcpp::Subscription<px4_msgs::msg::VehicleLocalPosition>::SharedPtr vehicle_local_position_sub_;
};
