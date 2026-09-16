# fsm

The flight state machine node. Drives a PX4-controlled vehicle through a fixed mission loop by publishing `VehicleCommand`/`OffboardControlMode`/`TrajectorySetpoint` messages over `px4_msgs`, and reacting to `VehicleStatus`/`VehicleLocalPosition` feedback.

## States

- `DISARMED` — settles briefly after landing, then requests arm.
- `ARMING` — sends `VEHICLE_CMD_COMPONENT_ARM_DISARM` until PX4 reports armed.
- `TAKEOFF` — sends `VEHICLE_CMD_NAV_TAKEOFF` in place, up to `target_takeoff_alt_` meters above home, until the altitude is reached.
- `SEARCH` — generates a lawnmower coverage path (via the `navigator` package) over a fixed area, switches to OFFBOARD mode, and flies the path waypoint by waypoint.
- `LANDING` — sends `VEHICLE_CMD_NAV_LAND` until PX4 reports disarmed.

The loop runs at 10 Hz (`fsm_loop`, a 100 ms wall timer) and currently re-arms automatically after every landing — there's no external arm trigger yet.

## Topics

Publishes: `/fmu/in/vehicle_command`, `/fmu/in/offboard_control_mode`, `/fmu/in/trajectory_setpoint`
Subscribes: `/fmu/out/vehicle_status_v1`, `/fmu/out/vehicle_local_position_v1`

## Run

```
ros2 run fsm fsm_node
```
