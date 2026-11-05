# drone_autonomy_stack

A base frame for testing your own drone autonomy code against PX4 SITL + Gazebo. It ships a simple FSM that, on request, runs arm → takeoff → search → return → land, and a coverage path planner and velocity path follower used by the search state.

## Packages

- [`src/ros/fsm`](src/ros/fsm/README.md) — the flight state machine node that talks to PX4.
- [`src/ros/navigator`](src/ros/navigator/README.md) — lawnmower coverage path generation and the velocity path follower used by the FSM's search state.
- `src/ros/drone_interface` — custom interfaces, currently the `StartSearch` service.
- `src/ros/bringup` — `drone.launch.py`, which starts the drone nodes with their parameters.

## Config

```
config/
├── colcon/   colcon_defaults.yaml (build defaults)
├── docker/   compose files (base, nvidia, dri)
├── ros/      drone_params.yaml (ROS node parameters)
└── sim/      sim.env (PX4 SITL settings)
```

## Running the sim

Build, start, and run the sim via `./stack`, a Docker Compose wrapper (repo is bind-mounted at `/workspace`):

```
./stack image    # build the Docker image (slow; only after Dockerfile changes)
./stack up       # create/start sim_container, with GPU accel auto-detected
./stack shell    # open a shell in sim_container
./stack sim      # run PX4 SITL + Gazebo + Micro XRCE-DDS Agent inside sim_container
./stack build    # colcon build the workspace inside sim_container
./stack launch   # launch the drone stack (bringup) inside sim_container
./stack mission  # send a search mission to the FSM
./stack lint     # run clang-tidy inside sim_container
./stack format   # run the pre-commit clang-format hook on all files
./stack gpu      # print the detected GPU mode (nvidia|dri|none)
./stack down     # stop and remove sim_container
```

For the Gazebo GUI (rather than headless), run:

```
HEADLESS=0 ./stack sim
```

The vehicle model, Micro XRCE-DDS Agent port and PX4 parameters are set in [`config/sim/sim.env`](config/sim/sim.env). Add a PX4 parameter as `PX4_PARAM_<NAME>=<value>`. Changes apply on the next `./stack sim`, no rebuild or restart needed.

ROS 2 uses Cyclone DDS (`RMW_IMPLEMENTATION=rmw_cyclonedds_cpp`, set in the `Dockerfile`). The Micro XRCE-DDS Agent uses Fast DDS internally and talks to the ROS 2 nodes over standard DDS.

GPU acceleration is auto-detected, nvidia (via the NVIDIA Container Toolkit), dri (Intel/AMD, via `/dev/dri`), or software rendering as a fallback. Override with e.g. `SIM_GPU=dri ./stack up`. GPU access is assigned when the container is created, so run `./stack down` then `./stack up` again after changing modes.

Once the sim is running, build the ROS packages, launch the stack, and start a mission (each in its own terminal):

```
./stack build
./stack launch
./stack mission
```

`./stack mission` calls `/fsm_node/start_search` with a 20 × 20 m area (see [`scripts/container/mission_launch.sh`](scripts/container/mission_launch.sh)). Node parameters live in [`config/ros/drone_params.yaml`](config/ros/drone_params.yaml); pass another file with `./stack launch params_file:=/workspace/<file>.yaml`.

Builds use [`config/colcon/colcon_defaults.yaml`](config/colcon/colcon_defaults.yaml) (symlink install, and `compile_commands.json` for `./stack lint`).

## Camera

`./stack launch` also starts the camera source selected in `config/ros/drone_params.yaml`:

```yaml
camera_bringup:
  ros__parameters:
    camera_source: sim
```

Set `camera_source` to `sim`, `hardware`, or `disabled`, then restart the launch. This value is read by bringup at startup; it is not a runtime-switchable node parameter. Parameter files without a `camera_bringup` section leave the camera disabled.

Both sources publish `/camera/image_raw` (`sensor_msgs/msg/Image`) and `/camera/camera_info` (`sensor_msgs/msg/CameraInfo`). The sim source bridges the RGB camera already included in `gz_x500_depth`. The configured Gazebo topics assume the `default` world and vehicle instance `x500_depth_0`; change `gz_image_topic` and `gz_camera_info_topic` for another world or instance. Inspect available topics with `gz topic -l` inside the sim container.

The hardware source starts `v4l2_camera` for a compatible USB/V4L2 camera. Configure its `video_device`, `image_size`, `pixel_format`, and `output_encoding` under `camera_node.ros__parameters`. The process must have permission to open the device. Docker does not pass cameras through by default; hardware use inside a container also requires a device mapping and access to the device's group. Cameras requiring a vendor-specific driver need another source implementation.

After pulling this camera change, rebuild the image and bringup package:

```bash
./stack image
./stack down
./stack up
./stack build --packages-select bringup
```

Run `./stack sim` and `./stack launch` in separate terminals. Inspect the feed from `./stack shell`:

```bash
ros2 topic hz /camera/image_raw
ros2 topic echo /camera/camera_info --once
```

To launch only the camera from a sourced ROS workspace:

```bash
ros2 launch bringup camera.launch.py params_file:=/absolute/path/to/drone_params.yaml
```
