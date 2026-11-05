import yaml
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, OpaqueFunction
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node

DEFAULT_PARAMS = "/workspace/config/ros/drone_params.yaml"


def launch_camera(context):
    params_file = LaunchConfiguration("params_file").perform(context)
    with open(params_file, encoding="utf-8") as stream:
        config = yaml.safe_load(stream) or {}
    camera = config.get("camera_bringup", {}).get("ros__parameters", {})
    source = camera.get("camera_source", "disabled")
    log_level = LaunchConfiguration("log_level").perform(context)

    if source == "disabled":
        return []
    if source == "sim":
        image_topic = camera.get("gz_image_topic")
        info_topic = camera.get("gz_camera_info_topic")
        if not image_topic or not info_topic:
            raise ValueError(
                "Sim camera requires gz_image_topic and gz_camera_info_topic"
            )
        return [
            Node(
                package="ros_gz_bridge",
                executable="parameter_bridge",
                name="camera_bridge",
                output="screen",
                arguments=[
                    f"{image_topic}@sensor_msgs/msg/Image[gz.msgs.Image",
                    f"{info_topic}@sensor_msgs/msg/CameraInfo[gz.msgs.CameraInfo",
                    "--ros-args",
                    "--log-level",
                    log_level,
                ],
                remappings=[
                    (image_topic, "/camera/image_raw"),
                    (info_topic, "/camera/camera_info"),
                ],
            )
        ]
    if source == "hardware":
        return [
            Node(
                package="v4l2_camera",
                executable="v4l2_camera_node",
                name="camera_node",
                output="screen",
                parameters=[params_file],
                arguments=["--ros-args", "--log-level", log_level],
                remappings=[
                    ("image_raw", "/camera/image_raw"),
                    ("camera_info", "/camera/camera_info"),
                ],
            )
        ]
    raise ValueError("camera_source must be sim, hardware, or disabled")


def generate_launch_description():
    return LaunchDescription(
        [
            DeclareLaunchArgument("params_file", default_value=DEFAULT_PARAMS),
            DeclareLaunchArgument("log_level", default_value="info"),
            OpaqueFunction(function=launch_camera),
        ]
    )
