extends Node

export var ENABLED = true	# Toggle camera control.

export var BOOM_RESET = false	# If RESET button is pressed, reset the boom.
export var DOLLY_RESET = true	# If RESET button is pressed, reset the dolly.

# You must define these actions in your Input Map. If yout don't, nothing will happen. 
# You don't have to call them what is listed here, but if you don't then you have to change the definitions below
# to match what you label them in the input Map. Probably best to just use these names, unless you
# really want them to be called something different.

export var ACTION_NAME_CAMERA_MOVE_LEFT = "CameraMoveLeft"
export var ACTION_NAME_CAMERA_MOVE_RIGHT = "CameraMoveRight"
export var ACTION_NAME_CAMERA_MOVE_UP = "CameraMoveUp"
export var ACTION_NAME_CAMERA_MOVE_DOWN = "CameraMoveDown"
export var ACTION_NAME_CAMERA_ROTATE = "CameraRotate"
export var ACTION_NAME_CAMERA_ZOOM_IN = "CameraZoomIn"
export var ACTION_NAME_CAMERA_ZOOM_OUT = "CameraZoomOut"
export var ACTION_NAME_CAMERA_RESET = "CameraReset"
export var ACTION_NAME_CAMERA_RAISE = "CameraRaise"
export var ACTION_NAME_CAMERA_LOWER = "CameraLower"


onready var dolly = get_node("Dolly")
onready var boom = dolly.get_node("Boom")
onready var camera = boom.get_node("Camera")
var mouseDelta = Vector2(0,0)	# the 'speed' of the mouse.
var mouseStart = Vector2(0,0)	#remember the location of the mouse to determine the speed of camera rotation

func _ready():
	set_process(true)	# make sure we are running the script each frame.
	set_process_input(true) # make sure we are watching for input
	
func _process(delta):
	if not ENABLED:
		return
	dolly.stop()	# stop the dolly at the beginning of our movement loop to ensure it will come to a halt if not moved.
	if InputMap.has_action(ACTION_NAME_CAMERA_MOVE_LEFT):	#make sure the actions exist in the input map to avoid stuttering
		if(Input.is_action_pressed(ACTION_NAME_CAMERA_MOVE_LEFT)):
			dolly.move_left()
	if InputMap.has_action(ACTION_NAME_CAMERA_MOVE_RIGHT):
		if(Input.is_action_pressed(ACTION_NAME_CAMERA_MOVE_RIGHT)):
			dolly.move_right()
	if InputMap.has_action(ACTION_NAME_CAMERA_MOVE_UP):
		if(Input.is_action_pressed(ACTION_NAME_CAMERA_MOVE_UP)):
			dolly.move_forward()
	if InputMap.has_action(ACTION_NAME_CAMERA_MOVE_DOWN):
		if(Input.is_action_pressed(ACTION_NAME_CAMERA_MOVE_DOWN)):
			dolly.move_backward()
	if InputMap.has_action(ACTION_NAME_CAMERA_RAISE):
		if(Input.is_action_pressed(ACTION_NAME_CAMERA_RAISE)):
			dolly.raise()
	if InputMap.has_action(ACTION_NAME_CAMERA_LOWER):
		if(Input.is_action_pressed(ACTION_NAME_CAMERA_LOWER)):
			dolly.lower()
	
	# we need to pass the frame delta to the moving functions, so we do it here with a command to move.
	# we also calculate a speed bonus based on the zoom level. This makes the dolly move faster when zoomed
	# further out, as one would most likely expect.
	var speed_bonus= clamp((boom.zoom.size()-boom.current_zoom_level)*.5, 1, 5)
	dolly.move(delta, speed_bonus)
	boom.move(delta)
		
	# rotation
	mouseDelta = Vector2(0,0)
	if InputMap.has_action(ACTION_NAME_CAMERA_ROTATE):
		if(Input.is_action_pressed(ACTION_NAME_CAMERA_ROTATE)):
			var mousePos = get_viewport().get_mouse_pos()
			mouseDelta =  mouseStart - mousePos
			#determine how much we should rotate this frame
			mouseStart = mousePos # update the starting position of the mouse
		boom.pitch(-mouseDelta.y , delta)
		dolly.rotate(mouseDelta.x , delta)
func _input(event):
	#memorize the location of the mouse when the rotate camera button is first pressed
	if(event.type == InputEvent.MOUSE_BUTTON):
		if(event.button_index == 3):
			mouseStart = event.pos
	if InputMap.has_action(ACTION_NAME_CAMERA_ZOOM_IN):
		if(event.is_action_pressed(ACTION_NAME_CAMERA_ZOOM_IN)):
			boom.retract()
	if InputMap.has_action(ACTION_NAME_CAMERA_ZOOM_OUT):
		if(event.is_action_pressed(ACTION_NAME_CAMERA_ZOOM_OUT)):
			boom.extend()
	if InputMap.has_action(ACTION_NAME_CAMERA_RESET):
		if(event.is_action_pressed(ACTION_NAME_CAMERA_RESET)):
			if BOOM_RESET:
				boom.reset()
			if DOLLY_RESET:
				dolly.reset()