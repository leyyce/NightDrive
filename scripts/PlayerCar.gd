extends KinematicBody2D

var speed = 0
var _current_speed_in_kmh = 0.0
export(int) var max_speed = 0 # 1500
export(int) var max_speed_equals_kmh = 0
var direction = DIRECTIONS.none
export(float) var backlight_energy = 3.35
export(float) var frontlight_energy = 4.2
export(bool) var lights = true
var can_move = true
enum DIRECTIONS {
  none,
  left,
  right,
  up,
  down,
  up_left,
  up_right,
  down_left,
  down_right
}

func _ready():
	$BackLight.energy = backlight_energy
	$LightLeft.energy = frontlight_energy
	$LightRight.energy = frontlight_energy
	
	_set_lights()
	
func _physics_process(delta):
	var one_px = float(max_speed_equals_kmh) / max_speed
	_current_speed_in_kmh = speed * one_px
	$SpeedLabel.set_text("  " + str(int(_current_speed_in_kmh)) + "\nkm/h")
	_set_lights()
	_check_input(delta)
	
func _check_input(delta):
	if not can_move:
		return
	
	var accel = false
	var damp_per_pixel_move = 0.75 / max_speed
	var steering_damper = damp_per_pixel_move * speed
	# print(steering_damper)
	var rotation_degrees = get_rotation_degrees()
	var accel_multi
	var break_multi = 1.25
	var move = Vector2(0, 0)
	var pos_min = 255 + $AnimatedSprite.frames.get_frame("default", 0).get_size().y / 2
	var pos_max = 650 - $AnimatedSprite.frames.get_frame("default", 0).get_size().y / 2
	
	if speed < max_speed * 0.0086:
		accel_multi = 0.3
	elif speed < max_speed * 0.0428:
		accel_multi = 0.13
	elif speed < max_speed * 0.1714: # 200:
		accel_multi = 0.0075
	elif speed < max_speed * 0.2857: # 400:
		accel_multi = 0.004
	elif speed < max_speed * 0.4: # 600
		accel_multi = 0.003
	elif speed < max_speed * 0.5143: # 800
		accel_multi = 0.0025
	elif speed < max_speed * 0.7429: # 1200
		accel_multi = 0.000995
	elif speed < max_speed * 0.9143: # 1500
		accel_multi = 0.0004
	#if speed < 15:
	#	accel_multi = 0.3
	#elif speed < 75:
	#	accel_multi = 0.13
	#elif speed < 300: # 200:
	#	accel_multi = 0.0075
	#elif speed < 500: # 400:
	#	accel_multi = 0.004
	#elif speed < 700: # 600
	#	accel_multi = 0.003
	#elif speed < 900: # 800
	#	accel_multi = 0.0025
	#elif speed < 1300: # 1200
	#	accel_multi = 0.000995
	#elif speed < 1600: # 1500
	
	# Prev unused
	#	accel_multi = 0.0004
	#elif speed < 1800:
	#	accel_multi = 0.00015
	#elif speed < 2200:
	#	accel_multi = 0.00050
	else:
		accel_multi = 0.00025
	
	if Input.is_action_just_pressed("car_lights"):
		lights = not lights
		
	# Move car in given direction and set rotation degrees coresponding to it
	if Input.is_action_pressed("car_accel"):
		move.x = 1
		direction = DIRECTIONS.right
		rotation_degrees = 0
		accel = true
		
		if Input.is_action_pressed("car_up"):
			rotation_degrees = -45
			move.y = -1 + steering_damper
			direction = DIRECTIONS.up_right
		elif Input.is_action_pressed("car_down"):
			rotation_degrees = 45
			move.y = 1 - steering_damper
			direction = DIRECTIONS.down_right
		
	elif Input.is_action_pressed("car_break"):
		$BackLight.energy = backlight_energy * 2
		$BackLight.set_enabled(true)
		if speed >= 800:
			break_multi = 7.5
		else:
			break_multi = 3.5
	else:
		$BackLight.energy = backlight_energy
	if not accel:
		if Input.is_action_pressed("car_up"):
			rotation_degrees = -45
			move.y = -1 + steering_damper
			direction = DIRECTIONS.up_right
			#if direction != DIRECTIONS.down_right and direction != DIRECTIONS.none:
			#	rotation_degrees = -45
			#	move.y = -1
			#	direction = DIRECTIONS.up_right
			#else:
			#	rotation_degrees = 0
			#	move.y = 0
			#	direction = DIRECTIONS.right
		elif Input.is_action_pressed("car_down"):
			rotation_degrees = 45
			move.y = 1 - steering_damper
			direction = DIRECTIONS.down_right
			#if direction != DIRECTIONS.up_right and direction != DIRECTIONS.none:
			#	rotation_degrees = 45
			#	move.y = 1
			#	direction = DIRECTIONS.down_right
			#else:
			#	rotation_degrees = 0
			#	move.y = 0
			#	direction = DIRECTIONS.right
		else:
			rotation_degrees = 0
			move.y = 0
			direction = DIRECTIONS.right
	# BREAKING LOGIC
	if move.x == 0:
		if speed - speed * accel_multi * break_multi == 0:
			speed = 0
		else:
			speed = clamp(speed - speed * accel_multi * break_multi, 0, max_speed)
		if direction == DIRECTIONS.up_right:
			move = Vector2(1, -1 + steering_damper)
		elif direction == DIRECTIONS.down_right:
			move = Vector2(1, 1 - steering_damper)
		elif direction == DIRECTIONS.right:
			move = Vector2(1, 0)
		#if direction == DIRECTIONS.up_left:
		#	position += (Vector2(-1, -1).normalized() * speed * delta)
		#elif direction == DIRECTIONS.down_left:
		#	position += (Vector2(-1, 1).normalized() * speed * delta)
		#elif direction == DIRECTIONS.down:
		#	position += (Vector2(0, 1).normalized() * speed * delta)
		#elif direction == DIRECTIONS.up:
		#	position += (Vector2(0, -1).normalized() * speed * delta)
		#elif direction == DIRECTIONS.left:
		#	position += (Vector2(-1, 0).normalized() * speed * delta)
	elif accel:
		speed = clamp(speed + (speed + 10) * accel_multi, 1, max_speed)
	if speed <= 1:
		speed = 0
		direction = DIRECTIONS.none
		move.y *= abs(move.x)
	else:
		if move.x != -1:
			move.x = 1
		var pos_y_new = position.y + move.normalized().y * speed * delta
		if  pos_y_new < pos_min or pos_y_new > pos_max:
			rotation_degrees = 0
			move.y = 0
			direction = DIRECTIONS.right
		set_rotation_degrees(rotation_degrees * (1 - steering_damper))
	position.x += move.normalized().x * speed * delta
	position.y = clamp(position.y + move.normalized().y * speed * delta, pos_min, pos_max)
	
	#if Input.is_action_pressed("ui_up") and Input.is_action_pressed("ui_left") \
	#    and not (direction == DIRECTIONS.down or direction == DIRECTIONS.down_right):
	#	speed = clamp(speed + (speed + 10) * accel_multi, 1, max_speed)
	#	position += (Vector2(-1, -1).normalized() * speed * delta)
	#	set_rotation_degrees(-135)
	#	direction = DIRECTIONS.up_left
	#elif Input.is_action_pressed("ui_down") and Input.is_action_pressed("ui_left") \
	#	 and not (direction == DIRECTIONS.up or direction == DIRECTIONS.up_right):
	#	speed = clamp(speed + (speed + 10) * accel_multi, 1, max_speed)
	#	position += (Vector2(-1, 1).normalized() * speed * delta)
	#	set_rotation_degrees(135)
	#	direction = DIRECTIONS.down_left
	#elif Input.is_action_pressed("ui_up") \
	#	 and not (direction == DIRECTIONS.down or direction == DIRECTIONS.down_right or direction == DIRECTIONS.down_left):
	#	speed = clamp(speed + (speed + 10) * accel_multi, 1, max_speed)
	#	position.y -= speed * delta
	#	set_rotation_degrees(270)
	#	direction = DIRECTIONS.up
	#elif Input.is_action_pressed("ui_down") \
	#	 and not (direction == DIRECTIONS.up or direction == DIRECTIONS.up_right or direction == DIRECTIONS.up_left):
	#	speed = clamp(speed + (speed + 10) * accel_multi, 1, max_speed)
	#	position.y += speed * delta
	#	set_rotation_degrees(90)
	#	direction = DIRECTIONS.down
	#elif Input.is_action_pressed("ui_left") \
	#	 and not (direction == DIRECTIONS.right or direction == DIRECTIONS.down_right or direction == DIRECTIONS.up_right):
	#	speed = clamp(speed + (speed + 10) * accel_multi, 1, max_speed)
	#	position.x -= speed * delta
	#	set_rotation_degrees(180)
	#	direction = DIRECTIONS.left

func _set_lights():
	$BackLight.set_enabled(lights)
	$LightLeft.set_enabled(lights)
	$LightRight.set_enabled(lights)

func get_current_speed_in_kmh():
	return _current_speed_in_kmh
