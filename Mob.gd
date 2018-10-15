extends KinematicBody2D

var world

var speed = 100
var velocity = Vector2()

enum STATES { IDLE, FOLLOW }
var _state = null

var path = []
var target_point_world = Vector2()
var target_position = Vector2()

func _ready():
	world = get_parent()
	_change_state(IDLE)
	pass

func _input(event):
	if event.is_action_pressed("left_click"):
		if Input.is_key_pressed(KEY_SHIFT):
			global_position = get_global_mouse_position()
		else:
			target_position = get_global_mouse_position()
		if world.is_not_way(target_position):
			_change_state(FOLLOW)

func _physics_process(delta):
	if not _state == FOLLOW:
		return
	var arrived_to_next_point = move_to(target_point_world)
	if arrived_to_next_point:
		path.remove(0)
		if len(path) == 0:
			if !world.blocking_cells.empty():
				destroy_blocking_cells()
				_change_state(FOLLOW)
			else:
				_change_state(IDLE)
			return
		target_point_world = path[0]

func _change_state(new_state):
	if new_state == FOLLOW:
		path = world.get_path(position, target_position)
		if not path or len(path) == 1:
			_change_state(IDLE)
			return
		target_point_world = path[1]
	_state = new_state

func move_to(world_position):
	var ARRIVE_DISTANCE = 1.0
	var desired_velocity = (world_position - position).normalized() * speed
	var steering = desired_velocity - velocity
	velocity += steering
	position += velocity * get_process_delta_time()
	#rotation = velocity.angle()
	return position.distance_to(world_position) < ARRIVE_DISTANCE

func destroy_blocking_cells():
	for c in world.get_children():
		for b in world.blocking_cells:
			if c.is_in_group("wall") && c.position == world.map_to_global(Vector2(b.x, b.y))+world.offset:
				world.refill_astar(world.astar_node, b)
				c.queue_free()
