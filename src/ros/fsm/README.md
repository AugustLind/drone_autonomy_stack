# fsm

The flight state machine node. Waits for a search mission on its `start_search` service, then flies it by publishing `VehicleCommand`/`OffboardControlMode`/`TrajectorySetpoint` messages over `px4_msgs` and reacting to `VehicleStatus`/`VehicleLocalPosition` feedback.

## States

- `DISARMED` — waits `disarm_settle_time`, then requests arm once a mission has been accepted.
- `ARMING` — sends `VEHICLE_CMD_COMPONENT_ARM_DISARM` until PX4 reports armed.
- `TAKEOFF` — sends `VEHICLE_CMD_NAV_TAKEOFF` in place, up to the mission altitude above home, until the altitude is reached.
- `SEARCH` — generates a lawnmower coverage path (via the `navigator` package) over the requested area, with an extra first leg from the current position to the first corner. It switches to OFFBOARD mode in velocity control and flies each segment with `follow_segment` (see the [navigator README](../navigator/README.md#path-follower-math) for the math). If `VehicleLocalPosition` is older than `local_position_timeout`, it commands zero velocity until fresh data arrives.
- `RETURN` — flies back to home at `return_altitude` using a position setpoint, then lands.
- `LANDING` — sends `VEHICLE_CMD_NAV_LAND` until PX4 reports disarmed, then goes back to `DISARMED` to wait for the next mission.

The loop runs every `loop_period_ms` (`fsm_loop`, a wall timer).

## Starting a mission

`~/start_search` (`drone_interface/srv/StartSearch`):

| Field | Description |
| --- | --- |
| `corners` | 4 search area corners in local NED [m], ordered bottom_left, bottom_right, top_left, top_right; `z` ignored |
| `swath_width` | spacing between lawnmower legs [m], > 0 |
| `altitude` | takeoff and search altitude above home [m], > 0 |

The request is rejected while a mission is running or pending. `./stack mission` sends an example request.

## Offboard control modes

`publish_offboard_control_mode(ControlMode)` selects what PX4 tracks in OFFBOARD mode. Pair it with the matching setpoint publisher:

| Mode | Setpoint publisher | Used by |
| --- | --- | --- |
| `ControlMode::POSITION` (default) | `publish_trajectory_setpoint(Waypoint)` | `RETURN` |
| `ControlMode::VELOCITY` | `publish_velocity_setpoint(VelocityCmd)`, with position fields set to NaN | `SEARCH` |

## Parameters

Set in [`config/ros/drone_params.yaml`](../../../config/ros/drone_params.yaml).

| Parameter | Default | Description |
| --- | --- | --- |
| `loop_period_ms` | 100 | FSM loop period [ms] |
| `disarm_settle_time` | 2.0 | wait after disarm before arming again [s] |
| `acceptance_radius` | 1.5 | distance at which the return waypoint counts as reached [m] |
| `local_position_timeout` | 0.2 | local position age after which search holds [s] |
| `return_altitude` | 10.0 | altitude for the return flight [m] |
| `follower.*` | | path follower settings, see `FollowerParams` in the [navigator README](../navigator/README.md#api) |

## Interfaces

Publishes: `/fmu/in/vehicle_command`, `/fmu/in/offboard_control_mode`, `/fmu/in/trajectory_setpoint`
Subscribes: `/fmu/out/vehicle_status_v1`, `/fmu/out/vehicle_local_position_v1`
Services: `/fsm_node/start_search`

## Run

```
./stack launch
```

or inside the container, `ros2 launch bringup drone.launch.py`.
