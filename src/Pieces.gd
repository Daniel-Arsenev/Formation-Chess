extends TileMap
	
# add a const variable, 
# that lets you choose the
# max number of pieces
# in a formation
#
# for that, un-hard-code
# the permutation generator 
# from calc moves function 

var mboard = [[4, 3, 2, 5, 0, 2, 3, 4], 
			 [ 1, 1, 1, 1, 1, 1, 1, 1], 
			 [-1,-1,-1,-1,-1,-1,-1,-1],
			 [-1,-1,-1,-1,-1,-1,-1,-1], 
			 [-1,-1,-1,-1,-1,-1,-1,-1], 
			 [-1,-1,-1,-1,-1,-1,-1,-1], 
			 [ 7, 7, 7, 7, 7, 7, 7, 7],
			 [10, 9, 8,11, 6, 8, 9,10]]
var board = mboard.duplicate(true)
var history = []
var antihist = []
			
			
var castlerights = [[true, true, true], [true, true, true]]
var enpassant = 0


var past = 0
var turn = 1

			


signal clicked()
signal pickup()
signal drop()
signal checkmate()
signal play_sound()



func v(a, b):
	return Vector2(a, b)
func wb(sel):
	return 1 if board[sel[1]][sel[0]] > 5 else 0
func check(v):
	return 0 <= v[0] and v[0] < 8 and 0 <= v[1] and v[1] < 8


		
var moves
var formation = []
var select = []
var hold = false

func _input(event):
	var click = Vector2()

	click = world_to_map(get_global_mouse_position())
	#click
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		if check(click) and wb(click) == turn and not (board[click[1]][click[0]] == -1):
			if not click in formation and not click in select:
				select = []
			if  click in select:
				select.erase(click)
			select.append(click)
			moves = check_legal_moves(calc_moves(select))
			formation = check_legal_formations(calc_formation(select), select)
			pickup(click)
			update()
			for i in select:
				set_cellv(i, -1)
	#unclick
	if event is InputEventMouseButton and not event.pressed and event.button_index == BUTTON_LEFT:
		emit_signal("drop")
		if len(select) > 0  and not click == select[-1]:
			select_move(click, moves)
			select = []
			moves = []
			formation = []
			hold = false
		else: 
			hold = false
		update()
		

func update():
	for i in range(8):
		for j in range(8):
			set_cell(i, j, board[j][i])
			
	emit_signal("clicked", select, moves, board, hold, formation, past, check_check())
	if check_checkmate():
		emit_signal("play_sound", 3)
		emit_signal("checkmate", turn, board)
		
func pickup(click):
	var positions = []
	var pieces = []
	for i in select:
		positions.append(map_to_world(i))
		pieces.append(board[i[1]][i[0]])
		
	emit_signal("pickup", positions, pieces, map_to_world(click))
	hold = true	


func select_move(click, movs):
	if len(select) == 1:
		for mov in movs:
			if mov[1] == click:
				make_move(mov)
				return
		return
		
	var possible = []
	for mov in movs:
		var i = 1
		while i < len(mov):
			if mov[i] == click:
				possible.append(mov)
			i = i + 2
	var lens = []
	for mov in possible:
		lens.append((mov[1] - mov[0]).length())
	lens.sort()
	if len(lens) > 1 and lens[0] < lens[-1]:
		for mov in possible:
			if lens[0] == (mov[1] - mov[0]).length():
				make_move(mov)
				return
					
	for mov in movs:
		if not hold:
			if mov[1] == click:
				make_move(mov)
				return
		else:
			var i = 0
			while i < len(mov):
				if mov[i] == select[-1] and mov[i+1] == click:
					make_move(mov)
					return
				i = i + 2	

	
func make_move(move, test = false, undo = 0):
	var wb = wb(v(move[0][0], move[0][1]))
	var capture = 1
	var captured = []
	var i = 0

	if not test:
		history.append([board.duplicate(true), castlerights.duplicate(true), enpassant, past, turn])
	while i < len(move):
		# if King moves update Kingpos and castlerights
		if board[move[i][1]][move[i][0]] == 0 + 6 * wb and not test:
			castlerights[wb][1] = false

		if not board[move[i+1][1]][move[i+1][0]] == -1:
			capture = 2
		if test and not undo is Array:
			captured.append(board[move[i+1][1]][move[i+1][0]])
		
		# if promotion
		if board[move[i][1]][move[i][0]] == 1 + 6*wb and move[i+1][1] == 7 * (1 - wb)  and not test:
			board[move[i+1][1]][move[i+1][0]]  = 5 + 6*wb
		# not promotion
		else:	
			# change target tile
			board[move[i+1][1]][move[i+1][0]]  = board[move[i][1]][move[i][0]] 
		# change tile youre coming from
		board[move[i][1]][move[i][0]] = -1 if not undo is Array else undo[i/2] 
			
	
		if not test:
			past = move
			
			# if roock is gone update  castlerights
			if not board[7 * wb][0] == 4 + 6*wb:
				castlerights[wb][0] = false
			if not board[7 * wb][7] == 4 + 6*wb:
				castlerights[wb][2] = false
			# if pawn double move allow enpassant	
			
			enpassant = move[i+1] if board[move[i+1][1]][move[i+1][0]] == 1 + 6*wb and abs(move[i+1][1] - move[i][1]) > 1 else 0
		
		i = i + 2
		

	if not test:
		turn = 1 - turn
		emit_signal("play_sound", capture)
	elif not undo: 	
		return captured	
		
func calc_single_moves(sel, formationmode = false):	
	if sel is int:
		return []
		
	var mov = []
	var wb = wb(sel)

	# if pawn
	if board[sel[1]][sel[0]] == 1 + 6 * wb : 
		if board[sel[1] + 1 - 2*wb][sel[0]] == -1:
			mov.append([sel, sel + v(0, 1 - 2*wb)])
			if sel[1] == 1 + 5*wb and board[sel[1] + 2 - 4*wb][sel[0]] == -1 and not formationmode:
				mov.append([sel, sel + v(0, 2 - 4*wb)])
		if not sel[0] == 7 and not board[sel[1] + 1 - 2*wb][sel[0]+1] == -1 and not wb == wb(sel + v(1, 1 - 2*wb)):
			mov.append([sel, sel + v(1, 1 - 2*wb)])
		if not sel[0] == 0 and not board[sel[1] + 1 - 2*wb][sel[0]-1] == -1 and not wb == wb(sel + v(-1, 1 - 2*wb)):
			mov.append([sel, sel + v(-1, 1 - 2*wb)])
			
		if enpassant is Vector2 and sel + v(1, 0) == enpassant:
			mov.append([sel, sel + v(1, 1 - 2*wb), enpassant, enpassant])
		if enpassant is Vector2 and sel + v(-1, 0) == enpassant:
			mov.append([sel, sel + v(-1, 1 - 2*wb), enpassant, enpassant])
			
	#if knight
	if board[sel[1]][sel[0]] == 3 + 6 * wb :
		for i in [v(1, 2), v(1, -2), v(-1, 2), v(-1, -2), v(2, 1), v(2, -1), v(-2, 1), v(-2, -1)]:
			var jump = sel + i
			if check(jump) and (board[jump[1]][jump[0]] == -1 or not wb == wb(jump)):
				mov.append([sel, jump])
			
	#if bishop
	if board[sel[1]][sel[0]] == 2 + 6 * wb:
		for dir in [v(1, 1), v(1,-1), v(-1, 1), v(-1, -1)]:
			var jump = sel + dir
			while check(jump) and board[jump[1]][jump[0]] == -1:
				mov.append([sel, jump])
				jump = jump + dir 
			if check(jump) and not wb == wb(jump):
				mov.append([sel, jump])
	#if roock
	if board[sel[1]][sel[0]] == 4 + 6 * wb:
		for dir in [v(1, 0), v(-1, 0), v(0, 1), v(0,-1)]:
			var jump = sel + dir
			while check(jump) and board[jump[1]][jump[0]] == -1:
				mov.append([sel, jump])
				jump = jump + dir 
			if check(jump) and not wb == wb(jump):
				mov.append([sel, jump])
				
	#if king or queen
	if board[sel[1]][sel[0]] == 5 + 6 * wb or board[sel[1]][sel[0]] == 0 + 6 * wb:
		for dir in [v(1, 0), v(-1, 0), v(0, 1), v(0,-1), v(1, 1), v(1,-1), v(-1, 1), v(-1, -1)]:
			var jump = sel + dir
			var cont = true
			while cont and check(jump) and board[jump[1]][jump[0]] == -1:
				mov.append([sel, jump])
				if board[sel[1]][sel[0]] == 0 + 6 * wb:
					cont = false
				jump = jump + dir 
			if cont and check(jump) and not wb == wb(jump):
				mov.append([sel, jump])
	#Casteling
	if not formationmode and board[sel[1]][sel[0]] == 0 + 6 * wb and castlerights[wb][1]:
		if castlerights[wb][2] and board[7*wb][5] == -1 and board[7*wb][6] == -1:
			make_move([sel, sel + v(1, 0)], true)
			if not check_check():
				mov.append([sel, sel + v(2, 0), sel + v(3, 0), sel + v(1, 0)])
			make_move([sel + v(1, 0), sel], true)
		if castlerights[wb][0] and board[7*wb][3] == -1 and board[7*wb][2] == -1 and board[7*wb][1] == -1:
			make_move([sel, sel + v(-1, 0)], true)
			if not check_check():
				make_move([sel + v(-1, 0), sel + v(-2, 0)], true)
				if not check_check():
					mov.append([sel, sel + v(-2, 0), sel + v(-4, 0), sel + v(-1, 0)])
				make_move([sel + v(-2, 0), sel + v(-1, 0)], true)		
			make_move([sel + v(-1, 0), sel], true)		
			
				
	return mov
			

func check_legal_moves(move):
	var legal = []

	for mov in move:
		var mem  = make_move(mov, true)
		
		var selfcapture = false
		for i in mem:
			if not i == -1 and (1 if i > 5 else 0) == turn:
				selfcapture = true

		if not selfcapture and (check_check() is int):
			legal.append(mov)

		var reversemov = mov.duplicate(true)
		reversemov.invert()
		mem.invert()
		make_move(reversemov, true, mem)
		
		
	return legal
	

func check_check():
	var wb = turn
	var KingPos = [0, 0]

	for i in range(8):
		for j in range(8):
			if board[j][i] == 0 or board[j][i] == 6:
				KingPos[0 if board[j][i] == 0 else 1] = v(i, j)
	
	# check by bishop or queen
	for dir in [v(1, 1), v(1,-1), v(-1, 1), v(-1, -1)]:
		var check = KingPos[wb] + dir
		while check(check) and board[check[1]][check[0]] == -1:
			check = check + dir
		if check(check) and (board[check[1]][check[0]] == 8 - 6 * wb or board[check[1]][check[0]] == 11 - 6 * wb):
			return  KingPos[wb]
	#check by roock or queen
	for dir in [v(0, 1), v(0,-1), v(-1, 0), v(1, 0)]:
		var check = KingPos[wb] + dir
		while check(check) and board[check[1]][check[0]] == -1:
			check = check + dir
		if check(check) and (board[check[1]][check[0]] == 10 - 6 * wb or board[check[1]][check[0]] == 11 - 6 * wb):
			return KingPos[wb]
	#check by knight
	for dir in [v(1, 2), v(1, -2), v(-1, 2), v(-1, -2), v(2, 1), v(2, -1), v(-2, 1), v(-2, -1)]:
		var check = KingPos[wb] + dir
		if check(check) and board[check[1]][check[0]] == 9 - 6 * wb:
			return  KingPos[wb]
	#check by pawn
	for dir in [v(1, 1 - 2*wb), v(-1, 1 - 2*wb)]:
		var check = KingPos[wb] + dir
		if check(check) and board[check[1]][check[0]] == 7 - 6 * wb:
			return  KingPos[wb]
	#check by king
	if not pow((KingPos[0]-KingPos[1])[0],2) + pow((KingPos[0]-KingPos[1])[1],2) > 2:
		return  KingPos[wb]
	
	return 0
	
	
func check_checkmate():
	for i in range(8):
		for j in range(8):
			if wb(v(i, j)) == turn and not board[j][i] == -1 and check_legal_moves(calc_moves([v(i, j)])):
				return false
	for i in range(8):
		for j in range(8):			
			for f in check_legal_formations(calc_formation([v(i, j)]), [v(i, j)]):
				if wb(v(i, j)) == turn and not board[j][i] == -1 and check_legal_moves(calc_moves([v(i, j), f])):
					return false
					
	for i in range(8):
		for j in range(8):			
			for f in check_legal_formations(calc_formation([v(i, j)]), [v(i, j)]):
				for g in check_legal_formations(calc_formation([v(i, j), f]), [v(i, j), f]):
					if wb(v(i, j)) == turn and not board[j][i] == -1 and check_legal_moves(calc_moves([v(i, j), f, g])):
						return false
	
	return true
	

func calc_formation(selects):
	if len(selects) < 3:
		var form = []
		for sel in selects:
			for dir in 	[v(1, 1), v(1,-1), v(-1, 1), v(-1, -1), v(0, 1), v(0,-1), v(1, 0), v(-1, 0)]:
				var search = sel + dir
				if check(search) and not board[search[1]][search[0]] == -1 and wb(search) == turn and not search in form:
					form.append(search)
		return form
	else:
		return []
	
	
func check_legal_formations(forms, sel):
	var legal_form = []
	for form in forms:
		if not form in sel:
			var test = sel.duplicate(true)
			test.append(form)
			if check_legal_moves(calc_moves(test)) and not form in legal_form:
				legal_form.append(form)

	return legal_form
	
	
func calc_moves(sel):	
	if len(sel) == 1:
		return calc_single_moves(sel[0])
		
	var movs = []
	for piece in sel:
		var ghost = []
		for g in sel:
			if not g == piece:
				ghost.append(g)
				ghost.append(g)
		var mem = make_move(ghost, true)
		movs.append(calc_single_moves(piece, true))
		make_move(ghost, true, mem)
		
	
	var calced_moves = []
	for i in movs[0]:
		for j in movs[1]:
			if i[1] - i[0] == j[1] - j[0]:
				if len(movs) == 2:
					calced_moves.append(i + j)
					calced_moves.append(j + i)
				else:
					for k in movs[2]:
						if i[1] - i[0] == j[1] - j[0] and i[1] - i[0] == k[1] - k[0]:
							calced_moves.append(i + j + k)
							calced_moves.append(i + k + j)
							calced_moves.append(j + i + k)
							calced_moves.append(j + k + i)
							calced_moves.append(k + j + i)
							calced_moves.append(k + i + j)

	return calced_moves




func _on_Button_pressed():
	if history: 
		var temp = history.pop_back()
		board = temp[0]
		castlerights = temp[1]
		enpassant = temp[2]
		past = temp[3]
		turn = temp[4]
		
		var out = ""
		for i in board:
			for j  in i: 
				out += str(j) + " "
				
		print(out)
		update()
		


func _on_Sprite_out(new_pos):
	print(new_pos)



#TODO: fix castle in check.
