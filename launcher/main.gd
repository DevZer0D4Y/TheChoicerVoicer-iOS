extends Control
## Shown when no game file was found in the app's folder. The engine looks for
## the game at startup (see engine/0002), so the player restarts after copying it.

const GAME_PAGE := "https://yeahmaybe.itch.io/the-choicer-voicer"
const PACK_MAGIC := 0x43504447 # "GDPC"


func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color(0.08, 0.08, 0.1)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	add_child(margin)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 20)
	margin.add_child(column)

	column.add_child(_label("The Choicer Voicer for iOS", 40))
	column.add_child(_label(_message(), 22))

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	column.add_child(buttons)
	buttons.add_child(_button("Open the app's folder", func(): OS.shell_open(OS.get_user_data_dir())))
	buttons.add_child(_button("Get the game", func(): OS.shell_open(GAME_PAGE)))


func _message() -> String:
	var text := "This app runs the game from your own copy of it.\n\n" \
			+ "1. Buy and download the Windows version of The Choicer Voicer from its itch.io page, then unzip it (tap the .zip in Files).\n" \
			+ "2. Copy the game's .exe into Files > On My iPhone > The Choicer Voicer.\n" \
			+ "3. Close this app completely (swipe it away) and open it again."
	var rejected := _rejected_files()
	if not rejected.is_empty():
		text += "\n\nThese files can't be used: " + ", ".join(rejected) \
				+ ". The file must be the game's own .exe or .pck, made with Godot 4.0 to 4.4."
	return text


## Game-like files in the folder that the engine skipped at startup.
func _rejected_files() -> PackedStringArray:
	var rejected := PackedStringArray()
	for file in DirAccess.get_files_at(OS.get_user_data_dir()):
		if file.get_extension().to_lower() in ["exe", "pck"] and not file.begins_with("."):
			if not _has_pack(OS.get_user_data_dir().path_join(file)):
				rejected.append(file)
	return rejected


func _has_pack(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var start := 0
	if f.get_32() != PACK_MAGIC:
		var end := f.get_length()
		if end < 16:
			return false
		f.seek(end - 12)
		var size := f.get_64()
		if f.get_32() != PACK_MAGIC or size + 12 > end:
			return false
		start = end - 12 - size
	f.seek(start)
	var magic := f.get_32()
	var format := f.get_32()
	var major := f.get_32()
	var minor := f.get_32()
	return magic == PACK_MAGIC and format == 2 and major == 4 and minor <= 4


func _label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	return label


func _button(text: String, pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 64)
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(pressed)
	return button
