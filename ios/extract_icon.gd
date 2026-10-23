extends SceneTree
## Saves the game's icon from a copy of the game (.exe or .pck) as a PNG:
##   godot --headless --script ios/extract_icon.gd -- <game.exe> <icon.png>

const ICON_PATHS := ["res://graphic/image/cv_temp_preview_icon.png"]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if not ProjectSettings.load_resource_pack(args[0]):
		printerr("Can't read the game from ", args[0])
		quit(1)
		return
	for path in ICON_PATHS:
		if ResourceLoader.exists(path):
			var image: Image = load(path).get_image()
			if image.is_compressed():
				image.decompress()
			image.resize(1024, 1024, Image.INTERPOLATE_LANCZOS)
			image.save_png(args[1])
			print("Saved the game's icon to ", args[1])
			quit()
			return
	printerr("No icon found in this version of the game")
	quit(1)
