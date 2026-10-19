extends Control
class_name 血条管理

@onready var 玩家血条: ProgressBar = $玩家血条
@onready var 失败or成功: Label = $失败or成功
@onready var 血量百分比: Label = $血量百分比

var 已结束: bool = false

func _ready() -> void:
	失败or成功.hide()

func 更新玩家血量(当前值: int, 最大值: int):
	玩家血条.max_value = 最大值
	玩家血条.value = 当前值
	血量百分比.text = "%d / %d" % [当前值, 最大值]

func 显示结果(结果: String):
	if 已结束:
		return
	已结束 = true
	失败or成功.text = 结果
	失败or成功.show()
