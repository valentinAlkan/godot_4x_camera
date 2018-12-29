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

func get_clicked(mouseinputevent):
	controller_node.click_ready = false	
	var camera = self
	from = camera.project_ray_origin(mouseinputevent.position)
	to = from + camera.project_ray_normal(mouseinputevent.position) * RAY_LENGTH
	user_did_click = true

func do_raycast(from, to, raycast_exclusions):
	return get_world().direct_space_state.intersect_ray(from, to, raycast_exclusions)

func _physics_process(delta):
	if user_did_click:
		user_did_click = false
		var ignore = []
		var hits = [do_raycast(from, to, ignore)]
		var i = 0
		while hits[-1]:
			i += 1
			# we got one hit. Keep hitting until we don't get anymore hits.
#			print(get_path(), " : preliminary_hits = ", hits)
			ignore.append(hits[-1].collider) # add the collider from the latest hit to the exclusions array, so that we dont hit it again
#			print(get_path(), " : ignore : ", ignore)
			var new_hit = do_raycast(from, to, ignore)
			if new_hit:
				hits.append(new_hit)
			else:
				break
		var result = hits[0]
		for hit in hits:
			# this needs to be changed out for some type of priority system
			if hit and hit.collider.get_node("..") is game.MeshInstanceSelectable:
				result = hit
		if not result:
			print(get_path(), ': nothing')
			if not Input.is_action_pressed(controller_node.ACTION_NAME_UI_SELECT_MODIFIER):
				selected_objects = []
				selected_points = []
		else:
			# now that we have an array of hits, order them
#			print(get_path(), " : hits = ", hits)
			var game_object = result.collider.get_node('..')
#			print(get_path(), " : result : ", result)
			print(get_path(), ": hit location = ", result.position)
			var selected_point = result.position
			print(get_path(), ": hit object = ", game_object.get_name())
			if controller_node.multi_select_enabled && Input.is_action_pressed(controller_node.ACTION_NAME_UI_SELECT_MODIFIER):
				selected_points.append(selected_point)  # add points to array no matter if the object has been selected again
				if not game_object in selected_objects:
					# only allow unique items in multi-selects
					selected_objects.append(game_object)
				else:
					# if a selected item is selected again, remove it
					selected_objects.remove(selected_objects.find(game_object))
			else:
				selected_objects = [game_object]
				selected_points = [selected_point]
		controller_node.click_ready = true