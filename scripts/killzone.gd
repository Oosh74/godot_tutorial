extends Area2D

@onready var timer: Timer = $Timer
@onready var death: AudioStreamPlayer2D = $Death


func _on_body_entered(body):
	print("DEAD")
	death.play()
	Engine.time_scale = .5
	body.get_node("CollisionShape2D").queue_free()
	
	timer.start()


func _on_timer_timeout() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
