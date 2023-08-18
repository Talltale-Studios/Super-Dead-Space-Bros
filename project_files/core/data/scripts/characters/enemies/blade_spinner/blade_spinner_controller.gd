extends BladeSpinner


@export var speed: float


@onready var wall_detector: RayCast2D = $WallDetector


func _physics_process(_delta: float) -> void:
	move_and_slide()
