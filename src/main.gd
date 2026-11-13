extends Node3D
## Boot scene. Prints a marker the smoke test greps for, then hands over to the sandbox arena
## once M1 lands. Launch flags: `--bridge` enables the playtest bridge in release builds.

const BOOT_MARKER := "SOULVESSELS_BOOT_OK"


func _ready() -> void:
	print("%s version=%s renderer=%s physics=%s" % [
		BOOT_MARKER,
		ProjectSettings.get_setting("application/config/version"),
		RenderingServer.get_current_rendering_method(),
		ProjectSettings.get_setting("physics/3d/physics_engine"),
	])
