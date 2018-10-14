extends Area2D

var win = false

func _ready():
	pass

func _on_finish_body_entered(body):
	if body.is_in_group("mob") && !win:
		var l = Label.new()
		l.rect_position = Vector2(960/2, 640/2)
		l.set_text("YOU WIN")
		get_parent().add_child(l)
		win = true
