extends Camera2D

onready var tween = $"tween"

var default_limits = {}  # This does not change once set

var speed = 0
var target
var target_pos

var zoom_time
var zoom_target

# This is needed to adjust dialog positions and such, see dialog_instance.gd
var zoom_transform

func set_limits(kwargs=null):
	if not kwargs:
		kwargs = {
			"limit_left": -10000,
			"limit_right": 10000,
			"limit_top": -10000,
			"limit_bottom": 10000,
			"set_default": false,
		}
		print_stack()

	self.limit_left = kwargs["limit_left"]
	self.limit_right = kwargs["limit_right"]
	self.limit_top = kwargs["limit_top"]
	self.limit_bottom = kwargs["limit_bottom"]

	if "set_default" in kwargs and kwargs["set_default"] and not default_limits:
		default_limits = kwargs

func resolve_target_pos():
	if typeof(target) == TYPE_VECTOR2:
		target_pos = target
	elif typeof(target) == TYPE_ARRAY:
		var count = 0

		for obj in target:
			target_pos += obj.get_camera_pos()
			count += 1

		# Let the error in if an empty array was passed (divzero)
		target_pos = target_pos / count
	else:
		target_pos = target.get_camera_pos()

	return target_pos

func set_target(p_speed, p_target):
	speed = p_speed
	target = p_target

	resolve_target_pos()

	if speed == 0:
		self.global_position = target_pos
	else:
		var time = self.global_position.distance_to(target_pos) / speed

		if tween.is_active():
			tween.stop_all()

		tween.interpolate_property(self, "global_position", self.global_position, target_pos, time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)

		tween.start()

func set_zoom(p_zoom_level, p_time):
	if p_zoom_level <= 0.0:
		vm.report_errors("camera", ["Tried to set negative or zero zoom level"])

	zoom_time = p_time
	zoom_target = Vector2(1, 1) * p_zoom_level

	if zoom_time == 0:
		self.zoom = zoom_target
	else:
		if tween.is_active():
			tween.stop_all()

		tween.interpolate_property(self, "zoom", self.zoom, zoom_target, zoom_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)

		tween.start()

func target_reached(obj, key):
	tween.stop_all()

func _process(time):
	zoom_transform = self.get_canvas_transform()

	if target and not tween.is_active():
		self.global_position = resolve_target_pos()

func _ready():
	# Init some kind of target if there is none
	if not target:
		target = vm.get_object("player")
	if not target:
		target = Vector2(0, 0)

	tween.connect("tween_completed", self, "target_reached")

