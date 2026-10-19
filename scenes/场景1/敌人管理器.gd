extends Node3D

@onready var 敌人模版: CharacterBody3D = $敌人模版
@onready var 出生地: Node3D = $出生地
@onready var 导航代理: NavigationAgent3D = %导航代理
@onready var 玩家: CharacterBody3D = %玩家
@onready var 血条界面: 血条管理 = %血条界面


@export var 移动速度: float = 1.0

var 目标更新计时: float = 0.0
var 活跃敌人: Array[CharacterBody3D] = []

#敌人伤害参数设定
@export var 敌人最大生命值: int = 100
@export var 攻击伤害: int = 10
@export var 攻击距离: float = 1.5
@export var 攻击间隔: float = 1.0

var 敌人生命值: Dictionary = {}
var 攻击计时: Dictionary = {}

var 敌人死亡: bool = false


func _ready() -> void:
	for 出生点 in 出生地.get_children():
		var 新敌人: CharacterBody3D = 敌人模版.duplicate() #创建实例并复制其子节点
		add_child(新敌人)
		
		新敌人.global_transform = 出生点.global_transform
		活跃敌人.append(新敌人) #把根节点的引用加入数组，并没有创建新节点，元素是指向节点位置的路径名称
		
		敌人生命值[新敌人] = 敌人最大生命值
		攻击计时[新敌人] = 0.0
		
		var 头顶显示: Sprite3D = 新敌人.get_node("Sprite3D")
		var 视口: SubViewport = 新敌人.get_node("Sprite3D/SubViewport")
		var 敌人血条: ProgressBar = 新敌人.get_node("Sprite3D/SubViewport/敌人血条")
		头顶显示.texture = 视口.get_texture()
		敌人血条.max_value = 敌人生命值[新敌人]
		敌人血条.value = 敌人生命值[新敌人]

	敌人模版.hide()
	$敌人模版/CollisionShape3D.set_deferred("disabled", true)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(玩家) or 敌人死亡:
			return
	
	目标更新计时 += delta
	if 目标更新计时 >= 0.2:
		目标更新计时 = 0.0
	
	for 敌人 in 活跃敌人:
		var 敌人导航代理: NavigationAgent3D = 敌人.get_node("导航代理")
		if 目标更新计时 == 0.0 and NavigationServer3D.map_get_iteration_id(敌人导航代理.get_navigation_map()):
			敌人导航代理.target_position = 玩家.global_position
		移动单个敌人(敌人, 敌人导航代理,delta)
		
		攻击计时[敌人] = max(攻击计时[敌人] - delta, 0.0)
		var 距离: float = 敌人.global_position.distance_to(玩家.global_position)
		if 距离 <= 攻击距离 and 攻击计时[敌人] == 0.0:
			if not 玩家.已死亡:
				玩家.受到伤害(攻击伤害)
			攻击计时[敌人] = 攻击间隔
		
		

func 移动单个敌人(敌人: CharacterBody3D, 代理: NavigationAgent3D, delta: float):
	if not 敌人.is_on_floor():
		敌人.velocity += 敌人.get_gravity() * delta #速度 = 重力加速度 x 时间
	
	## 路线走完了就停；否则朝下一个路点走。
	if 代理.is_navigation_finished():
		敌人.velocity = Vector3(0,0,0)
	else:
		敌人.velocity = 敌人.global_position.direction_to(代理.get_next_path_position()) * Vector3(1,0,1) * 移动速度
	敌人.move_and_slide()

func 敌人受到伤害(敌人: CharacterBody3D, 伤害值: int) -> void:
	if not 敌人生命值.has(敌人) or 敌人死亡:
		return
	
	敌人生命值[敌人] = max(敌人生命值[敌人] - 伤害值, 0)
	
	var 敌人血条: ProgressBar = 敌人.get_node("Sprite3D/SubViewport/敌人血条")
	敌人血条.value = 敌人生命值[敌人]
	print("敌人生命值：", 敌人生命值[敌人])
	
	if 敌人生命值[敌人] == 0:
		活跃敌人.erase(敌人)
		敌人生命值.erase(敌人)
		攻击计时.erase(敌人)
		敌人.queue_free()
		
		if 活跃敌人.is_empty():
			敌人死亡 = true
			血条界面.显示结果("成功")
