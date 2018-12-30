extends Camera

export var RAY_LENGTH = 10000
var from = null # raycast start
var to = null # raycast endpoint
var user_did_click = false #True when the user does a click. Check the raycast result and then set to false.

var distance_from_origin = 0 setget , _calc_distance
var controller_node = null # set by cameraNode
var selected_objects = [] # holds the objects that have been selected by the user.
var selected_points = []  # holds the points that have been selected by the user. Not objects, just vector3s.

var game = null # must be set by game node

func _calc_distance():
	# calculate distance from origin
	var loc = get_translation()
	
	# distance is always positive, so we need to know if we're below the xz plane.
	var invert = 1
	if loc.y < 0:
		invert = -1
	return invert * sqrt(loc.x * loc.x + loc.y*loc.y + loc.z * loc.z)

func move(speed):
	translate(Vector3(0,0, speed))