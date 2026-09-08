#drone_autonomy_stack

This project is ment to be a base frame for testing your own drone code. In the codebase you will find a simple fsm logic for mapping aswell as takeoff and land.

You will also have a simple object avoidance based on the input from the gazeboo. This module should also be easy to swithc if you have another avoidance sensor.

Build, start, and run the sim via ./scripts/dev.sh, a Docker Compose wrapper
(repo is bind-mounted at /workspace):

./scripts/dev.sh build   # build the sim image
./scripts/dev.sh up      # create/start sim_container, with GPU accel auto-detected
./scripts/dev.sh shell   # open a shell in sim_container
./scripts/dev.sh sim     # run PX4 SITL + Gazebo + Micro XRCE-DDS Agent inside sim_container
./scripts/dev.sh gpu     # print the detected GPU mode (nvidia|dri|none)
./scripts/dev.sh down    # stop and remove sim_container

For the Gazebo GUI (rather than headless), run:

HEADLESS=0 ./scripts/dev.sh sim

GPU acceleration is auto-detected - nvidia (via the NVIDIA Container Toolkit),
dri (Intel/AMD, via /dev/dri), or software rendering as a fallback. Override
with e.g. `SIM_GPU=dri ./scripts/dev.sh up`. GPU access is assigned when the
container is created, so run `dev.sh down` then `dev.sh up` again after
changing modes.
