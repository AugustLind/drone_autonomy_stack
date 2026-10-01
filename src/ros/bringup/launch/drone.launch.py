"""Launch the drone stack so it is ready to accept a mission via /fsm_node/start_search."""

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node

# Repo-root config/, as bind-mounted in sim_container (see config/docker/compose.yaml).
DEFAULT_PARAMS = "/workspace/config/ros/drone_params.yaml"


def generate_launch_description():
    params_file = LaunchConfiguration("params_file")
    log_level = LaunchConfiguration("log_level")

    return LaunchDescription(
        [
            DeclareLaunchArgument(
                "params_file",
                default_value=DEFAULT_PARAMS,
                description="Full path to the parameter file for the drone nodes",
            ),
            DeclareLaunchArgument(
                "log_level",
                default_value="info",
                description="Logging level for the drone nodes",
            ),
            Node(
                package="fsm",
                executable="fsm_node",
                name="fsm_node",
                output="screen",
                parameters=[params_file],
                arguments=["--ros-args", "--log-level", log_level],
            ),
        ]
    )
