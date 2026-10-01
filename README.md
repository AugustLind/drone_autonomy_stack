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
