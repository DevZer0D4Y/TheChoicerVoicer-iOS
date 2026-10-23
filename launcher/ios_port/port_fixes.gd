extends Node
## Layout fixes for running the game full screen on iPhone and iPad.
##
## The game is laid out for 16:9. On wider screens the port uses the "expand"
## stretch aspect, which widens every full-width container. This autoload is
## added to the game by the engine (see engine/0002) and keeps the widening
## from distorting the game's videos and its dub mode TV.

## Containers with fixed side margins that must keep their 16:9 width. Their
## siblings placed at a fixed position (like dub mode's remote) move with them.
const KEEP_DESIGN_WIDTH := ["_TelevisionBorderSqueezer"]

var design_width: float = ProjectSettings.get_setting("display/window/size/viewport_width", 1152)
## Pack videos drawn at their own aspect ratio, by player.
var fitted_videos := {}


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	get_viewport().size_changed.connect(_refit_containers)


func _on_node_added(node: Node) -> void:
	if node is MarginContainer and node.name in KEEP_DESIGN_WIDTH:
		node.set_meta("ios_port_margins", Vector2(
				node.get_theme_constant("margin_left"), node.get_theme_constant("margin_right")))
		_fit_container.call_deferred(node)
	elif node is VideoStreamPlayer:
		fitted_videos[node] = null
		node.tree_exiting.connect(fitted_videos.erase.bind(node))


func _refit_containers() -> void:
	for name in KEEP_DESIGN_WIDTH:
		for node in get_tree().root.find_children(name, "MarginContainer", true, false):
			_fit_container(node)


## Adds the width beyond the 16:9 design to the side margins, and moves the
## siblings laid out from the left edge by as much as the container moved.
func _fit_container(node: MarginContainer) -> void:
	if not is_instance_valid(node) or not node.has_meta("ios_port_margins"):
		return
	var margins: Vector2 = node.get_meta("ios_port_margins")
	var extra := maxf(0.0, (get_viewport().get_visible_rect().size.x - design_width) / 2.0)
	node.add_theme_constant_override("margin_left", int(margins.x + extra))
	node.add_theme_constant_override("margin_right", int(margins.y + extra))
	for sibling in node.get_parent().get_children():
		if sibling is Control and sibling != node and sibling.get_anchor(SIDE_RIGHT) == 0.0 and sibling.get_anchor(SIDE_BOTTOM) == 0.0:
			if not sibling.has_meta("ios_port_x"):
				sibling.set_meta("ios_port_x", sibling.position.x)
			sibling.position.x = sibling.get_meta("ios_port_x") + extra


func _process(_delta: float) -> void:
	for player: VideoStreamPlayer in fitted_videos:
		_fit_video(player)


## Pack videos (outside res://) are drawn by a TextureRect at the video's own
## aspect ratio: covering the screen as a background, fitting inside otherwise.
## The game's own clips, like the TV static, keep their stretched look.
func _fit_video(player: VideoStreamPlayer) -> void:
	var view: TextureRect = fitted_videos[player]
	var stream := player.stream as VideoStreamTheora
	if not player.expand or stream == null or stream.file.begins_with("res://"):
		if view:
			view.hide()
			player.self_modulate.a = 1.0
		return
	if view == null:
		view = TextureRect.new()
		view.set_anchors_preset(Control.PRESET_FULL_RECT)
		view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		player.add_child(view, false, Node.INTERNAL_MODE_FRONT)
		fitted_videos[player] = view
	var covers_screen := player.size.x >= get_viewport().get_visible_rect().size.x - 1.0
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if covers_screen else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.clip_contents = covers_screen
	player.clip_contents = covers_screen
	view.texture = player.get_video_texture()
	view.show()
	player.self_modulate.a = 0.0
