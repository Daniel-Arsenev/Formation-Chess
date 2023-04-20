extends AudioStreamPlayer2D


signal sound1()
signal sound2()
signal sound3()



func _on_Pieces_play_sound(index):
	if index == 1:
		emit_signal("sound1")
	if index == 2:
		emit_signal("sound2") 
	if index == 3:
		emit_signal("sound3")  
