extends CharacterBody3D

@onready var 导航代理: NavigationAgent3D = $NavigationAgent3D
@onready var 玩家: CharacterBody3D = %玩家

@export var 移动速度: float = 1.0

var 目标更新计时: float = 0.0


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	目标更新计时 += delta
	if  目标更新计时 >= 0.2 and NavigationServer3D.map_get_iteration_id(导航代理.get_navigation_map()):
		目标更新计时 = 0.0
		导航代理.target_position = 玩家.global_position

	## 路线走完了就停；否则朝下一个路点走。
	if 导航代理.is_navigation_finished():
		velocity = Vector3(0,0,0)
	else:
		velocity = global_position.direction_to(导航代理.get_next_path_position()) * Vector3(1,0,1) * 移动速度
	move_and_slide()
