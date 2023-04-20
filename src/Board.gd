extends TileMap

var selected = []
var moves = []
var board = []
var hold = false
var formation = []
var check

func v(a, b):
	return Vector2(a, b)
func wb(pos):
	return (int((pos[0] + pos[1]) + 1) % 2)

func _on_Pieces_clicked(sel, mov, brd, hld, form, past, checked):
	for i in range(8):
		for j in range(8):
			set_cell(i, j, wb(v(i, j)))
			
				
	if checked is Vector2:
		set_cellv(checked, 14 + wb(checked) + (2 if checked in form else 0))

	for sl in sel:
		set_cellv(sl, 12 + wb(sl))

	if past:
		for cell in past:
			set_cellv(cell, 2 + wb(cell))
	


	selected = sel
	moves = mov
	board = brd
	hold = hld
	formation = form
	check = checked
	
func _on_Pieces_checkmate(turn, board):
	for i in range(8):
		for j in range(8):
			if (not board[i][j] == -1) and (board[i][j] > 5) == bool(turn):
				set_cell(j, i, 14 + wb(v(i, j)))

var time = 0
func _process(delta):
	var update = false
	var mousepos = world_to_map(get_global_mouse_position())
	if moves is Array:
		for move in moves:
			for mov in move:
				if mov == mousepos:
					update = true
	if update or time > 0.075:
		time = 0
		update()
	else:
		time += delta
		
	
func update():
	if formation is Array:
		for form in formation:
			if form == world_to_map(get_global_mouse_position()):
				 set_cellv(form, 12 + wb(form))
			else:
				 set_cellv(form, 8 + wb(form) + (8 if check is Vector2 and check == form else 0))
	
	if moves is Array:
		for wheres in moves:
			if not ((wheres[0] == v(4, 7) and board[7][4] == 6 and (wheres[1] == v(2, 7) or wheres[1] == v(6, 7))) or (wheres[0] == v(4, 0) and board[0][4] == 0 and (wheres[1] == v(2, 0) or wheres[1] == v(6, 0)))):
				for where in wheres:
					if not where in selected:
						set_cellv(where, (4 if board[where[1]][where[0]] == -1 else 8) + wb(where))
			else:
				set_cellv(wheres[1], (4 if board[wheres[1][1]][wheres[1][0]] == -1 else 8) + wb(wheres[1]))		

		var mousepos = world_to_map(get_global_mouse_position())
		if len(selected) == 1:
			for mov in moves:
				if mov[1] == mousepos:
					colour(mov)
					return
			
		var possible = []
		for mov in moves:
			var i = 1
			while i < len(mov):
				if mov[i] == mousepos:
					possible.append(mov)
				i = i + 2
		var lens = []
		for mov in possible:
			lens.append((mov[1] - mov[0]).length())
		lens.sort()
		
		if len(lens) > 1 and lens[0] < lens[-1]:
			for mov in possible:
				if lens[0] == (mov[1] - mov[0]).length():
					colour(mov)
					return

		for mov in moves:
			if not hold:
				if mov[1] == mousepos:
					colour(mov)
					return
			else:
				var i = 0
				while i < len(mov):
					if mov[i] == selected[-1] and mov[i+1] == mousepos:
						colour(mov)
						return
					i = i + 2	
		
		
func colour(mov):
	if not ((mov[0] == v(4, 7) and board[7][4] == 6 and (mov[1] == v(2, 7) or mov[1] == v(6, 7))) or (mov[0] == v(4, 0) and board[0][4] == 0 and (mov[1] == v(2, 0) or mov[1] == v(6, 0)))):
		for mo in mov:
			set_cellv(mo, 12 + wb(mo))
	else:
		set_cellv(mov[0], 12 + wb(mov[0]))
		set_cellv(mov[1], 12 + wb(mov[1]))
	


