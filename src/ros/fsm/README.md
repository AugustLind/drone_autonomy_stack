# fsm

The flight state machine node. Drives a PX4-controlled vehicle through a fixed mission loop by publishing `VehicleCommand`/`OffboardControlMode`/`TrajectorySetpoint` messages over `px4_msgs`, and reacting to `VehicleStatus`/`VehicleLocalPosition` feedback.

## States

- `DISARMED` — settles briefly after landing, then requests arm.
- `ARMING` — sends `VEHICLE_CMD_COMPONENT_ARM_DISARM` until PX4 reports armed.
- `TAKEOFF` — sends `VEHICLE_CMD_NAV_TAKEOFF` in place, up to `target_takeoff_alt_` meters above home, until the altitude is reached.
- `SEARCH` — generates a lawnmower coverage path (via the `navigator` package) over a fixed area, with an extra first leg from the current position to the first corner. It switches to OFFBOARD mode in velocity control and flies each segment with `follow_segment` (see the [navigator README](../navigator/README.md#path-follower-math) for the math). If `VehicleLocalPosition` is older than 200 ms, it commands zero velocity until fresh data arrives.
- `RETURN` — flies back to home at 10 m using a position setpoint, then lands.
- `LANDING` — sends `VEHICLE_CMD_NAV_LAND` until PX4 reports disarmed.

The loop runs at 10 Hz (`fsm_loop`, a 100 ms wall timer) and currently re-arms automatically after every landing — there's no external arm trigger yet.

## Offboard control modes

`publish_offboard_control_mode(ControlMode)` selects what PX4 tracks in OFFBOARD mode. Pair it with the matching setpoint publisher:

| Mode | Setpoint publisher | Used by |
| --- | --- | --- |
| `ControlMode::POSITION` (default) | `publish_trajectory_setpoint(Waypoint)` | `RETURN` |
| `ControlMode::VELOCITY` | `publish_velocity_setpoint(VelocityCmd)`, with position fields set to NaN | `SEARCH` |

## Topics

Publishes: `/fmu/in/vehicle_command`, `/fmu/in/offboard_control_mode`, `/fmu/in/trajectory_setpoint`
Subscribes: `/fmu/out/vehicle_status_v1`, `/fmu/out/vehicle_local_position_v1`

## Run

```
ros2 run fsm fsm_node
```
