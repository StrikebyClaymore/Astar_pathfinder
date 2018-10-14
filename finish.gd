extends Area2D

func _ready():
	pass

func _on_finish_body_entered(body):
	if body.is_in_group("mob"):
		var l = Label.new()
		l.rect_position = Vector2(960/2, 640/2)
		l.set_text("YOU WIN")
		get_parent().add_child(l)
