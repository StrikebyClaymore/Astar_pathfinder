extends Node2D

onready var astar_node = AStar.new()
onready var astar_node2 = AStar.new()

var mob = preload("res://Mob.tscn")
var wall = preload("res://wall.tscn")
var finish = preload("res://finish.tscn")

var ts = 32
var width = 960/ts
var height = 640/ts

var offset = Vector2(16, 16)

var map = []

var entity = null
var target = Vector2()

var map_size = Vector2(width, height)
var path_start_position = Vector2() #setget _set_path_start_position
var path_end_position = Vector2() #setget _set_path_end_position

var _point_path = []
var obstacles = []

var blocking_cells = []

func _ready():
	randomize(true)
	create_finish()
	create_mob()
	fill_map()
	generate_lab()
	fill_cells()
	myAstar()
	pass

func myAstar():
	var walkable_cells_list = astar_add_walkable_cells(astar_node, obstacles)
	astar_connect_walkable_cells(astar_node, walkable_cells_list)
	walkable_cells_list = astar_add_walkable_cells(astar_node2)
	astar_connect_walkable_cells(astar_node2, walkable_cells_list)

func fill_cells():
	for i in map.size():
		if map[i] == 1:
			obstacles.append(i)
	pass

func refill_astar(astar, point):
	var pvector = Vector2(point.x, point.y)
	var p_index = calculate_point_index(pvector)
	obstacles = remove_it(obstacles, p_index)
	blocking_cells = remove_it(blocking_cells, point)
	astar.clear()
	var walkable_cells_list = astar_add_walkable_cells(astar, obstacles)
	astar_connect_walkable_cells(astar, walkable_cells_list)

func astar_add_walkable_cells(astar, obst = []):
	var points_array = []
	for y in range(map_size.y):
		for x in range(map_size.x):
			var point = Vector2(x, y)
			if calculate_point_index(point) in obst:
				continue
			points_array.append(point)
			var point_index = calculate_point_index(point)
			astar.add_point(point_index, Vector3(point.x, point.y, 0.0))
	return points_array

func create_point_relative(point):
	var points_relative
	if ((calculate_point_index(point + Vector2(0, 1)) in obstacles) or (calculate_point_index(point + Vector2(0, -1)) in obstacles) or
	(calculate_point_index(point + Vector2(1, 0)) in obstacles) or (calculate_point_index(point + Vector2(-1, 0)) in obstacles) or
	(calculate_point_index(point + Vector2(0, 1)) in obstacles && calculate_point_index(point + Vector2(1, 0)) in obstacles) or
	(calculate_point_index(point + Vector2(0, -1)) in obstacles && calculate_point_index(point + Vector2(1, 0)) in obstacles) or
	(calculate_point_index(point + Vector2(0, 1)) in obstacles && calculate_point_index(point + Vector2(-1, 0)) in obstacles) or
	(calculate_point_index(point + Vector2(0, -1)) in obstacles && calculate_point_index(point + Vector2(-1, 0)) in obstacles)):
		points_relative = PoolVector2Array([
			Vector2(point.x + 1, point.y),
			Vector2(point.x - 1, point.y),
			Vector2(point.x, point.y + 1),
			Vector2(point.x, point.y - 1)])
	else:
		points_relative = PoolVector2Array([
			Vector2(point.x + 1, point.y),
			Vector2(point.x - 1, point.y),
			Vector2(point.x, point.y + 1),
			Vector2(point.x, point.y - 1),
			Vector2(point.x + 1, point.y - 1),
			Vector2(point.x - 1, point.y - 1),
			Vector2(point.x + 1, point.y + 1),
			Vector2(point.x - 1, point.y + 1)])
	return points_relative

func astar_connect_walkable_cells(astar, points_array):
	for point in points_array:
		var point_index = calculate_point_index(point)
		var points_relative = create_point_relative(point)
		for point_relative in points_relative:
			var point_relative_index = calculate_point_index(point_relative)
			if is_outside_map_bounds(point_relative):
				continue
			if not astar.has_point(point_relative_index):
				continue
			astar.connect_points(point_index, point_relative_index, false)


func get_path(world_start, world_end):
	self.path_start_position = global_to_map(world_start)
	self.path_end_position = global_to_map(world_end)
	_set_path_start_position(self.path_start_position)
	_set_path_end_position(self.path_end_position)
	var path_world = []
	for point in _point_path:
		var point_world = map_to_global(Vector2(point.x, point.y)) + offset
		path_world.append(point_world)
	return path_world

func _recalculate_path():
	var start_point_index = calculate_point_index(path_start_position)
	var end_point_index = calculate_point_index(path_end_position)
	_point_path = astar_node.get_point_path(start_point_index, end_point_index)
	if _point_path.size() == 0:
		for point in astar_node2.get_point_path(start_point_index, end_point_index):
			if calculate_point_index(point) in obstacles:
				if !blocking_cells.has(point) && blocking_cells.empty():
					blocking_cells.append(point)
				continue
			var end_point_index2 = calculate_point_index(Vector2(point.x, point.y))
			var _point_path2 = astar_node.get_point_path(start_point_index, end_point_index2)
			if _point_path2.size() != 0:
				_point_path.append(point)

func global_to_map(vec):
	var point = Vector2(floor(vec.x/ts), floor(vec.y/ts))
	return point

func map_to_global(point):
	var vec = Vector2(point.x*ts, point.y*ts)
	return vec

func is_outside_map_bounds(point):
	return point.x < 0 or point.y < 0 or point.x >= map_size.x or point.y >= map_size.y

func is_not_way(pos):
	if calculate_point_index(global_to_map(pos)) in obstacles: return false
	else: return true

func calculate_point_index(point):
	return point.y*map_size.x + point.x

func _set_path_start_position(value):
	if value in obstacles:
		return
	if is_outside_map_bounds(value):
		return
	path_start_position = value
	if path_end_position and path_end_position != path_start_position:
		_recalculate_path()

func _set_path_end_position(value):
	if value in obstacles:
		return
	if is_outside_map_bounds(value):
		return
	path_end_position = value
	if path_start_position != value:
		_recalculate_path()

func get_cell_in_mas(pos):
	return (pos.y/ts)*map_size.x + pos.x/ts

func convert_num_to_cell(num):
	return Vector2(num - floor(num/map_size.x)*map_size.x, floor(num/map_size.x))

func create_mob():
	var m = mob.instance()
	m.position = Vector2(width*ts/2, height*ts/2)
	add_child(m)
	entity = m

func create_finish():
	var f = finish.instance()
	f.position = Vector2(int_rand(560+ts, 960-ts), int_rand(16, 640-ts))
	add_child(f)
	target = f

func fill_map():
	for i in map_size.x*map_size.y:
		map.append(0)
	pass

func generate_lab():
	for y in height:
		var w = wall.instance()
		w.position = Vector2((width/2)*ts +64, y*ts)
		map.remove(get_cell_in_mas(w.position))
		map.insert(get_cell_in_mas(w.position), 1)
		w.position += offset
		add_child(w)
	pass

func int_rand(a, b):
	return int(round(rand_range(a, b)))

func remove_it(mas, item):
	var _mas = mas
	mas = []
	for i in _mas.size():
		if _mas[i] == item:
			continue
		mas.append(_mas[i])
	return mas