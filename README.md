# drone_autonomy_stack

A base frame for testing your own drone autonomy code against PX4 SITL + Gazebo. It ships a simple FSM for arm → takeoff → search → land, and a coverage path planner and velocity path follower used by the search state.

## Packages

- [`src/ros/fsm`](src/ros/fsm/README.md) — the flight state machine node that talks to PX4.
- [`src/ros/navigator`](src/ros/navigator/README.md) — lawnmower coverage path generation and the velocity path follower used by the FSM's search state.

## Running the sim

Build, start, and run the sim via `./scripts/dev.sh`, a Docker Compose wrapper (repo is bind-mounted at `/workspace`):

```
./scripts/dev.sh build   # build the sim image
./scripts/dev.sh up      # create/start sim_container, with GPU accel auto-detected
./scripts/dev.sh shell   # open a shell in sim_container
./scripts/dev.sh sim     # run PX4 SITL + Gazebo + Micro XRCE-DDS Agent inside sim_container
./scripts/dev.sh gpu     # print the detected GPU mode (nvidia|dri|none)
./scripts/dev.sh down    # stop and remove sim_container
```

For the Gazebo GUI (rather than headless), run:

```
HEADLESS=0 ./scripts/dev.sh sim
```

The vehicle model, Micro XRCE-DDS Agent port and PX4 parameters are set in [`config/sim.env`](config/sim.env). Add a PX4 parameter as `PX4_PARAM_<NAME>=<value>`. Changes apply on the next `dev.sh sim`, no rebuild or restart needed.

GPU acceleration is auto-detected, nvidia (via the NVIDIA Container Toolkit), dri (Intel/AMD, via `/dev/dri`), or software rendering as a fallback. Override with e.g. `SIM_GPU=dri ./scripts/dev.sh up`. GPU access is assigned when the container is created, so run `dev.sh down` then `dev.sh up` again after changing modes.

Once the sim is running, build and run the ROS packages inside the container:

```
./scripts/dev.sh shell
colcon build --packages-select navigator fsm
source install/setup.sh
ros2 run fsm fsm_node
```
