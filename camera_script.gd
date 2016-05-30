extends Camera
var distance_from_origin = 0 setget , _calc_distance

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