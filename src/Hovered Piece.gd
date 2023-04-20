extends AnimatedSprite

var offsetfrommouse = 0
var offsetoffset = 0
var lastmousepos = Vector2(0, 0)
var last = Vector2(0, 0)

func _ready():
	self.hide()

func _process(_delta):
	var mousepos = get_global_mouse_position()
	var v = pow(((mousepos - lastmousepos)[0]), 2) + pow(((mousepos - lastmousepos)[1]), 2)

	lastmousepos = mousepos
	
	if offsetoffset is Vector2 :
		last = offsetoffset
	
	
	if offsetfrommouse is Vector2:
		self.global_position = offsetfrommouse + mousepos + offsetoffset
		offsetfrommouse = (offsetfrommouse  * pow(1.05, -v))


func _on_Pieces_pickup(positions, pieces, click):
	offsetfrommouse = 0
	offsetoffset = 0
	
	if self.name == "hovered Piece" and len(positions) > 0: 
		self.global_position = positions[0] + Vector2(50, 50)
		offsetfrommouse = click - get_global_mouse_position() + Vector2(50, 50)
		offsetoffset = positions[0] - click
		self.frame = pieces[0]
		self.show()
	
	if self.name == "additional1" and len(positions) > 1:
		self.global_position = positions[1] + Vector2(50, 50)
		offsetfrommouse = click - get_global_mouse_position() + Vector2(50, 50)
		offsetoffset = positions[1] - click
		self.frame = pieces[1]
		self.show()
		
	if self.name == "additional2" and len(positions) > 2:
		self.global_position = positions[2] + Vector2(50, 50)
		offsetfrommouse = click - get_global_mouse_position() + Vector2(50, 50)
		offsetoffset = positions[2] - click  
		self.frame = pieces[2]
		self.show()

	

func _on_Pieces_drop():
	self.hide()
	offsetfrommouse = 0
	offsetoffset = 0
