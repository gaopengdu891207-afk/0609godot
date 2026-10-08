extends CharacterBody3D

@onready var 角色: Node3D = $角色
@onready var 武器: Node3D = %武器
@onready var animation_tree: AnimationTree = $角色/AnimationTree
@onready var 手臂: MeshInstance3D = $角色/骨_身体/Skeleton3D/手臂
@onready var 命中标记: MeshInstance3D = %命中标记
@onready var fp视角: Camera3D = %FP视角

@export var 鼠标灵敏度 := 0.002
@export var 移动速度 := 8.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
func _input(event: InputEvent) -> void:
	#鼠标输入向量转为视角旋转值
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		fp视角.rotation.x = clamp(fp视角.rotation.x + event.screen_relative.y * 鼠标灵敏度, -PI/4.0, PI/3.0)
		rotation.y -= event.screen_relative.x * 鼠标灵敏度

func _physics_process(delta: float) -> void:
	# 跳跃下落设置
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = 4

	# WASD输入向量
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	# 输入向量转为移动向量单元
	var direction := ((-fp视角.global_basis.z * -input_dir.y + fp视角.global_basis.x * input_dir.x) * Vector3(1,0,1)).normalized()
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
	var 射线查询 := PhysicsRayQueryParameters3D.create(fp视角.global_position, fp视角.global_position - fp视角.global_basis.z * 100,  0xFFFFFFF, [self]) 
	var 射线结果 = get_world_3d().direct_space_state.intersect_ray(射线查询)
	if 射线结果:
		命中标记.global_position = 射线结果["position"] + 射线结果["normal"] * 0.02
		命中标记.visible = true
		print("命中对象：", 射线结果["collider"])
		print("命中位置：", 射线结果["position"])
