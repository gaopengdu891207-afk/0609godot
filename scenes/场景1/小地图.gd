extends Control

const 世界宽度 := 50         # Blender 正交比例 = 渲染框覆盖多少米
const 雷达直径 := 300.0          # 雷达圆大小（像素）
const 地图中心世界坐标 := Vector3(0, 0, 0)  # Blender 相机对准的世界点

@onready var 底图: TextureRect = %底图
@onready var 玩家: CharacterBody3D = $"../../玩家"
@onready var 敌人管理器: Node3D = %敌人管理器

var 比例: float

func _ready() -> void:
	比例 = 底图.size.x / 世界宽度
	

func _process(_delta: float) -> void:
	#if not is_instance_valid(玩家):
			#return
	
	#统一2D坐标系为小地图的局部原点,与底图的局部原点重合
	var 玩家相对地图中心世界坐标偏移: Vector3 = 玩家.global_position - 地图中心世界坐标
	var 底图中心位置: Vector2 = Vector2(底图.size.x / 2.0, 底图.size.y / 2.0)
	var 玩家像素位置: Vector2 = Vector2(玩家相对地图中心世界坐标偏移.x, 玩家相对地图中心世界坐标偏移.z) * 比例 + 底图中心位置
	var 雷达中心位置: Vector2 = Vector2(雷达直径 / 2.0, 雷达直径 / 2.0)

	# 移动底图，把玩家像素位置移到与雷达中心位置重合
	底图.position = 雷达中心位置 - 玩家像素位置

	# 底图围绕玩家位置旋转，先定枢纽点到玩家像素位置，再把玩家绕Y旋转值赋值给底图的旋转
	底图.pivot_offset = 玩家像素位置
	底图.rotation = 玩家.global_rotation.y

	# 圆形裁切：传玩家像素坐标和雷达半径
	底图.material.set_shader_parameter("center_pixel", 玩家像素位置)
	底图.material.set_shader_parameter("radius_pixel", 雷达直径 / 2.0)

	queue_redraw()

func _draw() -> void:
	var 圆心: Vector2 = Vector2(雷达直径 / 2.0, 雷达直径 / 2.0)

	# 底盘 绘制雷达底盘及轮廓
	draw_circle(圆心, 雷达直径 / 2.0, Color(0.05, 0.08, 0.1, 0.5))
	draw_arc(圆心, 雷达直径 / 2.0 - 1, 0, TAU, 64, Color(0.4, 0.7, 1.0, 0.8), 4.0)

	# 玩家箭头，相对圆心的位置，围绕圆心对称
	var 箭头:PackedVector2Array = PackedVector2Array([
		圆心 + Vector2(0, -9),
		圆心 + Vector2(-5, 7),
		圆心 + Vector2(0, 3),
		圆心 + Vector2(5, 7),])
	draw_colored_polygon(箭头, Color(0.3, 1, 0.3))

	# 敌人红点，敌人相对玩家位置，对应敌人标记在相对圆心的位置
	for e in 敌人管理器.活跃敌人: 
		var 敌偏移: Vector3 = e.global_position - 玩家.global_position
		var 像素: Vector2 = Vector2(敌偏移.x, 敌偏移.z) * 比例
		像素 = 像素.rotated(玩家.global_rotation.y)
		if 像素.length() > 雷达直径 / 2.0:
			continue
		draw_circle(圆心 + 像素, 4.0, Color(1, 0.25, 0.2))
