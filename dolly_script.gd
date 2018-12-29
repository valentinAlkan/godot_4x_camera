extends Spatial

# speed adjustments.
export var speed = .5 # max dolly speed
export var rotationalSpeed = .25
export var acceleration = 6.0
export var MIN_RAISE = 0	#minimum height to which the dolly can be lowered
export var MAX_RAISE = 100 # maximum height ot which the dolly can be raised

# Keep track of how fast we're moving in whatever direction so we can do linear interpolation and smooth out the movement.
var currentspeed = Vector3(0,0,0)
var targetspeed = Vector3(0,0,0)
var default_orientation = null
var targetRotation = 1 # currently only used for resetting. Otherwise is always 1.
var mouseStart = null	#keeps track of where the mouse was during the last frame. By subtracting where it is from where it was, we can
						#calculate the delta, which corresponds to how fast the mouse was moved.


func _ready():
	# remember the default position of the dolly
	default_orientation = get_transform()

func coast():
	targetspeed.x = 0
	targetspeed.y = 0
	targetspeed.z = 0

func stop():
	# come to a dead stop
	currentspeed.x = 0
	currentspeed.y = 0
	currentspeed.z = 0

func move_left():
	targetspeed.x = -speed
func move_right():
	targetspeed.x = speed
func move_forward():
	targetspeed.z = -speed
func move_backward():
	targetspeed.z = speed
func raise():
	targetspeed.y = speed
func lower():
	targetspeed.y = -speed
func move(dt, zoomModifier):
	# calculate the linear interpolation target velocity vector
	if targetspeed.x > 0 and currentspeed.x < 0 or targetspeed.x < 0 and currentspeed.x > 0:
		currentspeed.x = 0
	if targetspeed.y > 0 and currentspeed.y < 0 or targetspeed.y < 0 and currentspeed.y > 0:
		currentspeed.y = 0
	if targetspeed.z > 0 and currentspeed.z < 0 or targetspeed.z < 0 and currentspeed.z > 0:
		currentspeed.z = 0
	currentspeed.x = Approach(targetspeed.x * zoomModifier, currentspeed.x, dt * acceleration)
	currentspeed.y = Approach(targetspeed.y * zoomModifier, currentspeed.y, dt * acceleration)
	currentspeed.z = Approach(targetspeed.z * zoomModifier, currentspeed.z, dt * acceleration)
	
	if (get_translation().y + currentspeed.y < MIN_RAISE) and currentspeed.y<0:
		currentspeed.y = 0
	if (get_translation().y - currentspeed.y > MAX_RAISE) and currentspeed.y>0:
		currentspeed.y=0
	
	translate(Vector3(currentspeed.x, currentspeed.y, currentspeed.z))


var offset = 0 # lets us know how many radians away from 0 we are.
func rotate(target, dt):
	# rotate the dolly's entire coordinate system, rather than just the dolly.
	# this makes the forward vector relative to the camera, rather than the world.
	# If you don't do this, the 'forward' vector will always point in the same direction (North, so to speak)
	# and will ignore the direction it is pointing.
	# set_transform(get_transform().rotated(vector, -dt * rotationalSpeed * target))
	rotate_y(target*PI/180*rotationalSpeed)


	
	# here we are memorizing how many radians we have ever rotated the camera, in order to be able to reset the camera back to our original position
	# not the best way to do this, because it technically uses 'dead reckoning' (ie a relative value as opposed to an absolute one).
	# So, in theory, if there was even the slightest amount of error, it would stack up and when you reset the camera, it goes to some random position.
	# Also, technically, this value could overflow eventually if you kept rotating it. That could be fixed by never letting the absolute value
	# be more than some value. At any rate, it works well enough in testing and if it presents a problem it could just be changed to something more...clever.
	# Not a big deal, just thought I'd mention it.
	offset += fmod(-dt * rotationalSpeed * target, 2*PI) # take modulus of 2pi radians, otherwise camera tries to completely unwind.

func reset():
	set_transform(get_transform().rotated(Vector3(0,1,0), -offset))
	offset = 0

func Approach(targetSpeed, currentSpeed, delta):
	# smoothly approach our target speed
	var diff = targetSpeed-currentSpeed
	if diff>delta:
		return currentSpeed+delta
	if diff < -delta:
		return currentSpeed-delta
	return targetSpeed

