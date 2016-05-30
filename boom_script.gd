extends Spatial
# When the boom retracts and extends, it moves the camera in its local coordinate sytsem.
# Pitching the boom moves the camera while keeping the focal point of the screen the same.

# exports
export var MIN_LENGTH = 5
export var MAX_LENGTH = 100
export var MIN_PITCH = -25
export var MAX_PITCH = 25
export var steps = 5
export var acceleration = 10
export var zoom = [100, 80, 60, 40, 0]
export var DEFAULT_ZOOM_LEVEL = 3
# /exports

var filter = 2	# camera will continue to try to move until it gets to this distance from the target. prevents jitter.
var targetSpeed = 0
var distance_from_target = 0
var percent_zoom = 0
var current_zoom_level = 0
onready var camera = get_node("Camera")
onready var default_rotation = get_rotation()
func _ready():
	# convert degrees to radians
	MIN_PITCH = MIN_PITCH * PI/180
	MAX_PITCH = MAX_PITCH * PI/180
	
	#set the default zoom level. Ensure it's a valid value.
	if DEFAULT_ZOOM_LEVEL>zoom.size() or DEFAULT_ZOOM_LEVEL < 0:
		DEFAULT_ZOOM_LEVEL = floor(zoom.size())
	current_zoom_level = DEFAULT_ZOOM_LEVEL
		
func retract():
	# switch to a closer zoom level
	current_zoom_level = clamp(current_zoom_level + 1, 0, zoom.size()-1)
func extend():
	# switch to a further zoom level
	current_zoom_level = clamp(current_zoom_level - 1, 0, zoom.size()-1)
func move(dt):
	var theta = zoom[current_zoom_level]
	var target_distance = theta * (MAX_LENGTH - MIN_LENGTH) / 100
	distance_from_target = target_distance - camera.distance_from_origin
	
	# don't try to move the camera if it's within a certain distance of it's target. Prevents jitter and slowness.
	if abs(distance_from_target) > filter:
		camera.move(Approach(0,distance_from_target/acceleration, dt))
func pitch(target, dt):
	# pitch the boom, according to the mouse input
	var rotation = Vector3(1,0,0) * dt * target * .2

	# before actually adjusting the boom, ensure that pitching the boom doesn't put us out of bounds
	# if it does, pre-emtpively cancel the rotation before it happens (so as to eliminate stutter)
	if get_rotation().x - rotation.x < MIN_PITCH and rotation.x > 0:
		rotation.x = 0
	if get_rotation().x - rotation.x > MAX_PITCH and rotation.x < 0:
		rotation.x = 0
	rotate_x(rotation.x)

func reset():
	# reset the boom to it's default position
	set_rotation(default_rotation)
	current_zoom_level = DEFAULT_ZOOM_LEVEL

func Approach(target, current, delta):
	# smoothly approach our target speed
	var diff = target-current
	if diff>delta:
		return current+delta * acceleration
	if diff < -delta:
		return current-delta * acceleration
	return target