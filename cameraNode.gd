extends Node

signal onSelection(selected_objects, deselected_objects)  		# fires when a user selects something - even if the same thing that is already selected
signal onSelectionChanged(selected_objects, deselected_objects, newly_selected_objects)	# fires when the user selection changes - not if the same thing is selected again
signal onMoveCommand(selected_objects, selected_points)		# fires when the user (typically) right clicks the map
export var ENABLED = true	# Toggle camera control.
export var BOOM_RESET = false	# If RESET button is pressed, reset the boom.
export var DOLLY_RESET = true	# If RESET button is pressed, reset the dolly.
export var ROTATE_DOLLY = false # if true, mouse rotate will rotate the dolly rather than pitching the boom.

export var multi_select_enabled = true # if true, multiple objects can be selected at once (not fully implemented)

# If these actions aren't mapped in the project settings, a warning will be produced.
const ACTION_NAME_CAMERA_MOVE_LEFT = "CameraMoveLeft"
const ACTION_NAME_CAMERA_MOVE_RIGHT = "CameraMoveRight"
const ACTION_NAME_CAMERA_MOVE_UP = "CameraMoveUp"
const ACTION_NAME_CAMERA_MOVE_DOWN = "CameraMoveDown"
const ACTION_NAME_CAMERA_ROTATE = "CameraRotate"
const ACTION_NAME_CAMERA_ZOOM_IN = "CameraZoomIn"
const ACTION_NAME_CAMERA_ZOOM_OUT = "CameraZoomOut"
const ACTION_NAME_CAMERA_RESET = "CameraReset"
const ACTION_NAME_CAMERA_RAISE = "CameraRaise"
const ACTION_NAME_CAMERA_LOWER = "CameraLower"
const ACTION_NAME_UI_SELECT = "ui_select"
const ACTION_NAME_GAME_GO_TO_POINT = 'game_go_to_point'
const ACTION_NAME_UI_SELECT_MODIFIER = "ui_select_multiple_modifier"

const DEFAULT_ACTIONS_PAIRS_LIST_KEY = [
	[ACTION_NAME_CAMERA_MOVE_LEFT, 	KEY_A],
	[ACTION_NAME_CAMERA_MOVE_RIGHT, KEY_D],
	[ACTION_NAME_CAMERA_MOVE_UP, 	KEY_W],
	[ACTION_NAME_CAMERA_MOVE_DOWN,	KEY_D],
	[ACTION_NAME_CAMERA_RESET,		KEY_HOME],
	[ACTION_NAME_CAMERA_RAISE,		KEY_Q],
	[ACTION_NAME_CAMERA_LOWER,		KEY_E],
	[ACTION_NAME_UI_SELECT_MODIFIER,KEY_SHIFT],
]

const DEFAULT_ACTIONS_PAIRS_LIST_MOUSE = [
	[ACTION_NAME_CAMERA_ROTATE,		BUTTON_MIDDLE ],
	[ACTION_NAME_CAMERA_ZOOM_IN,	BUTTON_WHEEL_UP ],
	[ACTION_NAME_CAMERA_ZOOM_OUT,	BUTTON_WHEEL_DOWN ],
	[ACTION_NAME_UI_SELECT,			BUTTON_LEFT],
	[ACTION_NAME_GAME_GO_TO_POINT,	BUTTON_RIGHT],
]

onready var game = get_node('..')
onready var dolly = get_node("Dolly")
onready var boom = dolly.get_node("Boom")
onready var camera = boom.get_node("Camera")

var mouseDelta = Vector2(0,0)	# the 'speed' of the mouse.
var mouseStart = Vector2(0,0)	#remember the location of the mouse to determine the speed of camera rotation
var click_ready = false # when the click is ready for processing. Allows time for raycast to be called during physics process.
var selected_objects = [] # list of objects that are currently selected. When user deselects something, clear list
var deselected_objects = [] # list of objects that were just unselected.
var newly_selected_objects = [] # list of objects that were only just now selected. Does not contain repeats

var move_command = false # true when the player is issuing a move command (typically right click)

func _ready():
	_map_actions()  # make sure the keymap is mapped
	set_process(true)	# make sure we are running the script each frame.
	set_process_input(true) # make sure we are watching for input
	camera.controller_node = self # assign this node to the camera to allow for bidirectional comms
	camera.game = game
	
func _process(delta):
	if not ENABLED:
		return
	dolly.coast()	# stop the dolly at the beginning of our movement loop to ensure it will come to a halt if not moved.
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
	var speed_bonus = clamp((boom.current_zoom_level)*.5, 1, 5)
	dolly.move(delta, speed_bonus)
	boom.move(delta)
		
	# rotation
	mouseDelta = Vector2(0,0)
	if InputMap.has_action(ACTION_NAME_CAMERA_ROTATE):
		if(Input.is_action_pressed(ACTION_NAME_CAMERA_ROTATE)):
			var mousePos = get_viewport().get_mouse_position()
			mouseDelta =  mouseStart - mousePos
			#determine how much we should rotate this frame
			mouseStart = mousePos # update the starting position of the mouse
		dolly.rotate(mouseDelta.x , delta)
		# if ROTATE_DOLLY:
		# 	dolly.rotate(mouseDelta.y, delta)
		# else:
		boom.pitch(mouseDelta.y , delta)


	# user click is ready to process. This code is supposed to one exactly once per each time the 
	# player clicks. 
	if click_ready:
		var previously_selected_objects = selected_objects.duplicate()
		# print(get_path(), ': previously_selected_objects :', previously_selected_objects)
		selected_objects = camera.selected_objects.duplicate()
		# print(get_path(), ': selected_objects :', selected_objects)
			
		var selection_changed = false
		if len(selected_objects) == len(previously_selected_objects):
			for x in range(len(selected_objects)):
				if selected_objects[x] != previously_selected_objects[x]:
					selection_changed = true
					break
		else:
			selection_changed = true
		# update the list of newly selected nodes and deselected nodes
		newly_selected_objects = []
		for object in selected_objects:
			# print(get_path(), " : selected_objects :", object)
			if not object in previously_selected_objects:
				# print(get_path(), " : camera adding object ", object, " to newly_selected_objects array")
				newly_selected_objects.append(object)
			# else:
				# print(get_path(), " : camera ignoring object ", object, " to newly_selected_objects array")

		deselected_objects = []
		for object in previously_selected_objects:
			if not object in selected_objects:
				deselected_objects.append(object)

		# emit signals at the end, so that the arrays have had a chance to update
		if selected_objects:
			emit_signal('onSelection', selected_objects, deselected_objects)

		if selection_changed:
			emit_signal('onSelectionChanged', selected_objects, deselected_objects, newly_selected_objects)

		if move_command:
			# send previously selected objects, since as soon as we click to issue a move, whatever we clicked on becomes the selected objects
			emit_signal('onMoveCommand', previously_selected_objects, camera.selected_points)
			
		click_ready = false # set click as processed
		move_command = false

func _input(event):
	#memorize the location of the mouse when the rotate camera button is first pressed	
	if(event.is_action_pressed(ACTION_NAME_CAMERA_ROTATE)):
		mouseStart = event.position
	if(event.is_action_pressed(ACTION_NAME_CAMERA_ZOOM_IN)):
		boom.retract()
	if(event.is_action_pressed(ACTION_NAME_CAMERA_ZOOM_OUT)):
		boom.extend()
	if(event.is_action_pressed(ACTION_NAME_CAMERA_RESET)):
		if BOOM_RESET:
			boom.reset()
		if DOLLY_RESET:
			dolly.reset()
	if event is InputEventMouseButton:
		# do a raycast a see what got clicked
		if Input.is_action_just_pressed(ACTION_NAME_UI_SELECT):
			move_command = false
			camera.get_clicked(event)

		if Input.is_action_just_pressed(ACTION_NAME_GAME_GO_TO_POINT):
			move_command = true
			camera.get_clicked(event)

func get_selected_objects():
	return selected_objects

func get_deselected_objects():
	return deselected_objects

func get_newly_selected_objects():
	return newly_selected_objects

func get_selected_points():
	return camera.selected_points.duplicate()
	
func _map_actions():
	var warn = false
	for pair in DEFAULT_ACTIONS_PAIRS_LIST_KEY:
		var action = pair[0]
		var key = pair[1]
		if not InputMap.has_action(action):
			print(get_path(), " : Adding button keymap : [", action, ", ", key, "]")
			InputMap.add_action(action)
			var ev = InputEventKey.new()
#			var button = InputEventMouseButton.new()
			ev.scancode = key
			InputMap.action_add_event(action, ev)
			warn = true
			
	for pair in DEFAULT_ACTIONS_PAIRS_LIST_MOUSE:
		var action = pair[0]
		var button = pair[1]
		if not InputMap.has_action(action):
			print(get_path(), " : Adding mouse keymap : [", action, ", ", button, "]")
			InputMap.add_action(action)
			var ev = InputEventMouseButton.new()
			ev.button_index = button
			InputMap.action_add_event(action, ev)
			warn = true
			
	if warn:
		print(get_path(), " : Consider adding these keymaps to your project to disable this warning!")