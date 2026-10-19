extends CharacterBody3D

@onready var 角色: Node3D = $角色
@onready var 武器: Node3D = %武器
@onready var animation_tree: AnimationTree = $角色/AnimationTree
@onready var 手臂: MeshInstance3D = $角色/骨_身体/Skeleton3D/手臂
@onready var 命中标记: MeshInstance3D = %命中标记
@onready var fp视角: Camera3D = %FP视角
@onready var 敌人管理器: Node3D = %敌人管理器
@onready var 血条界面: 血条管理 = %血条界面

@export var 鼠标灵敏度 := 0.002
@export var 移动速度 := 8.0

@export var 最大生命值: int = 100
var 当前生命值: int = 100

var 已死亡: bool = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	当前生命值 = 最大生命值
	血条界面.更新玩家血量(当前生命值, 最大生命值)

func _input(event: InputEvent) -> void:
	#鼠标输入向量转为视角旋转值
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		fp视角.rotation.x = clamp(fp视角.rotation.x + event.screen_relative.y * 鼠标灵敏度, -PI/4.0, PI/3.0)
		rotation.y -= event.screen_relative.x * 鼠标灵敏度

func _physics_process(delta: float) -> void:
	if 已死亡:
		return
	# 跳跃下落设置
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = 4

	# WASD输入向量
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	# 输入向量转为移动向量单元
	var direction: Vector3 = ((-fp视角.global_basis.z * -input_dir.y + fp视角.global_basis.x * input_dir.x) * Vector3(1,0,1)).normalized()
	# 调整移动向量单元
	if direction:
		velocity = Vector3( direction.x * 移动速度, velocity.y, direction.z * 移动速度 )
	else:
		velocity = velocity.move_toward(Vector3(0, velocity.y, 0), 移动速度)
	move_and_slide()

	if Input.is_action_just_pressed("射击"):
		射线扫描()

func 射线扫描():
	# 建立射线查询参数，并排除本身物理体
	var 射线查询参数: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(fp视角.global_position, fp视角.global_position - fp视角.global_basis.z * 100,  0xFFFFFFF, [self]) 
	var 相交字典: Dictionary = get_world_3d().direct_space_state.intersect_ray(射线查询参数)
	if 相交字典:
		命中标记.global_position = 相交字典["position"] + 相交字典["normal"] * 0.02
		命中标记.visible = true
		if 相交字典["collider"] is CharacterBody3D:
			敌人管理器.敌人受到伤害(相交字典["collider"] , 20)

func 受到伤害(伤害值: int):
	if 已死亡:
		return
	
	当前生命值 = max(当前生命值 - 伤害值, 0)
	血条界面.更新玩家血量(当前生命值, 最大生命值)
	
	if 当前生命值 == 0:
		#queue_free()
		已死亡 = true
		血条界面.显示结果("失败")
		print("玩家死亡")
