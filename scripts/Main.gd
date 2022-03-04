extends Node2D

# OBSTACLES ##############################################################
# -- TRUCKS --
var volvo_f12_o = preload("../scenes/obstacles/VolvoF12Obstacle.tscn")
# -- CARS --
var lamborghini_countach_o = preload("../scenes/obstacles/LamborghiniCountachObstacle.tscn")
var ford_mustang_boss_o = preload("../scenes/obstacles/FordMustangBossObstacle.tscn")
var abarth_stilo_o = preload("../scenes/obstacles/AbarthStiloObstacle.tscn")
var subaru_impreza_wrx_o = preload("../scenes/obstacles/SubaruImprezaWRX.tscn")
# -- CONTAINERS --
var car_pool = [lamborghini_countach_o, ford_mustang_boss_o, abarth_stilo_o, subaru_impreza_wrx_o]
var truck_pool = [volvo_f12_o]
var traffic_pool = Array()
###########################################################################
# Spawn points that allow only cars to spawn
var spawns = Array()
# Spawn points that allow all obstacles including trucks to spawn
var truck_spawns = Array()

# The start and reset position of the car
# car_offset.x:
# controls how far away from the left screen side the car will stay while driving
export var car_offset = Vector2(250, 360)

var current_score = 0.0 # The current rounds score
var prev_player_position_x = 0.0 # x position of the player in the last frame

func _ready():
	randomize()
	spawns = [$ObstacleSpawn]
	truck_spawns = [$ObstacleSpawn2, $ObstacleSpawn3, $ObstacleSpawn4]
	spawns.append_array(truck_spawns)
	
	traffic_pool.append_array(car_pool)
	traffic_pool.append_array(truck_pool)
	_reset()
	$ObstacleTimer.start(rand_range(1, 2))
	$CounterTrafficTimer.start(rand_range(3, 7))

func _process(delta):
	_sync_to_player_pos()
	
	_update_score(delta)
	
	var to_process = Array()
	if $ObstacleContainer.get_child_count() != 0:
		to_process.append_array($ObstacleContainer.get_children())
	if $PropsContainer.get_child_count() != 0:
		to_process.append_array($PropsContainer.get_children())
		
	for child in to_process:
		# Clean up of objects that are no longer needed...
		if child.is_in_group("obstacle"):
			if child.position.x < $Car.position.x - car_offset.x - 1280 * 2 \
			   or child.position.x > $Car.position.x - car_offset.x + 1280 * 4:
				child.queue_free()
			else:
				# ... and prevent near crashes...
				var rc = child.get_node("RayCast2D")
				if rc.is_colliding():
					var coliding_object = rc.get_collider()
					if child == null or coliding_object == null:
						continue
					# ... trough setting the speed of the offending vehicle to
					# match the other vehicles speed
					child.speed = clamp(coliding_object.speed - 50 - randi() % 100, 0, child.speed_range.y)
				#if child.position.x < $Car.position.x - car_offset.x - 1280 * 4 \
				 #  or child.position.x > $Car.position.x - car_offset.x + 1280 * 4:
				#	child.queue_free()
	
	# Fullscreen toggle on key input
	if Input.is_action_just_pressed("ui_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
	
	# Resets game state on key input
	if Input.is_action_just_pressed("car_reset"):
		_reset()

func _sync_to_player_pos():
	# Move the cam forward with the car
	$Cam.position.x = $Car.position.x - car_offset.x
	
	# Move obstacle spawn points forward in sync to car
	for spawn in spawns:
		spawn.position.x = 1950 + $Car.position.x
	
	# Move fog forward with car
	$Fog.position.x = $Car.position.x - car_offset.x + 640
	
	# Move counter traffic spawn points forward in sync to car
	$CounterTraficSpawnUp.position.x = 1950 + $Car.position.x
	$CounterTraficSpawnDown.position.x = 1950 + $Car.position.x

func _update_score(delta):
	# Calculate the point multiplier for the current game.
	# A speed of 100 km/h equals a multiplier of 1.00
	# while a speed of 50 or 150 km/h would yield a multiplier of .5 or 1.5
	var score_multi = ($Car.get_current_speed_in_kmh() / 100)
	
	# Makes the player lose points if he drives on the emergency lane
	if $Car.position.y >= 575:
		score_multi *= -1
		
	# Calculates the players score and updates UI labels
	# Score is updated based on the distance driven 
	# multiplied by the score multiplier
	current_score += (($Cam.position.x - prev_player_position_x) * score_multi * delta)
	$UILayer/ScoreCountLabel.text = str(int(current_score))
	$UILayer/MPCountLabel.text = " x" + str(stepify(score_multi, 0.01))
	
	# Update the previous player position with the new one
	prev_player_position_x = $Cam.position.x
	
	# Increase highscore label if a new highscore is reached during the run
	if int($UILayer/HighScoreCountLabel.text) < current_score:
		$UILayer/HighScoreCountLabel.text = str(int(current_score))

func _add_obstacles():
	var obstacles_existing = 0
	var spawns_available = spawns.duplicate()
	var truck_spawns_available = truck_spawns.duplicate()
	
	for child in $ObstacleContainer.get_children():
		if child.position.x > $Car.position.x:
			obstacles_existing += 1
	if obstacles_existing >= 4:
		return
	
	var new_c = clamp(randi() % (spawns.size() + 1 - obstacles_existing), 0, traffic_pool.size())
	for _i in range(new_c):
		var o
		var s
		if truck_spawns_available.size() > 0:
			o = traffic_pool[randi() % traffic_pool.size()].instance()
			if o.is_in_group("truck"):
				s = truck_spawns_available[randi() % truck_spawns_available.size()]
				truck_spawns_available.erase(s)
				spawns_available.erase(s)
			else:
				s = spawns_available[randi() % spawns_available.size()]
				spawns_available.erase(s)
				truck_spawns_available.erase(s)
				# cos_available.erase(s)
		else:
			o = car_pool[randi() % car_pool.size()].instance()
			s = spawns_available[randi() % spawns_available.size()]
			spawns_available.erase(s)
		o.position = s.position
		if $Car.speed < 769: # Spawn obstacle behind car if car is not moving
			o.position.x = $Car.position.x - car_offset.x - (randi() % 1000 + 500)
		else:
			o.position.x += randi() % 500 # 1281
		o.connect("game_over", self, "_reset")
		o.speed = clamp(o.speed, o.speed_range.x, $Car.speed - 100)
		$ObstacleContainer.add_child(o)

func _reset():
	if int($UILayer/HighScoreCountLabel.text) < current_score:
		$UILayer/HighScoreCountLabel.text = str(int(current_score))
	current_score = 0
	prev_player_position_x = 0
	
	var to_process = Array()
	if $ObstacleContainer.get_child_count() != 0:
		to_process.append_array($ObstacleContainer.get_children())
	if $PropsContainer.get_child_count() != 0:
		to_process.append_array($PropsContainer.get_children())
		
	for child in to_process:
		if child.is_in_group("obstacle"):
			child.queue_free()
	$Cam.position.x = 0
	$Fog.position.x = 0
	$Car.speed = 0
	$Car.position = car_offset
	$MiddleStreetLight.position.x = 0
	$MiddleStreetLight2.position.x = 1280

# --- SIGNALS ---
func _on_Timer_timeout():
	_add_obstacles()
	$ObstacleTimer.start(rand_range(1, 2))

func _on_Cam_body_exited(body):
	if body.is_in_group("streetlight") and body.position.x < $Car.position.x:
		body.position.x += 1280 * 2
		

func _on_CounterTrafficTimer_timeout():
	var t = traffic_pool[randi() % traffic_pool.size()].instance()
	t.set_rotation_degrees(180)
	# t.speed = t.max_speed + randi() % 101
	match randi() % 3:
		0:
			t.position = $CounterTraficSpawnUp.position
			t.position.x += randi() % 1281
		1:
			t.position = $CounterTraficSpawnDown.position
			t.position.x += randi() % 1281
		2:
			t.position = $CounterTraficSpawnUp.position
			t.position.x += randi() % 1281
			var t2 = traffic_pool[randi() % traffic_pool.size()].instance()
			t2.position = $CounterTraficSpawnDown.position
			t2.position.x += randi() % 1281
			t2.set_rotation_degrees(180)
			# t2.speed = t2.max_speed + randi() % 101
			$PropsContainer.add_child(t2)
	$PropsContainer.add_child(t)
	$CounterTrafficTimer.start(rand_range(3, 7))
# --- SIGNALS END ---
