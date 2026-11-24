class_name Shape
extends RefCounted
## A sudoku shape: cells plus houses. A house holds every digit 1..size once. The solver and
## generator know nothing else about the shape.

var size: int
var cell_count: int
var houses: Array[PackedInt32Array] = []
## For each cell, the houses it belongs to.
var cell_houses: Array[PackedInt32Array] = []
## For each cell, the other cells that share a house with it, ascending.
var peers: Array[PackedInt32Array] = []


func _init(shape_size: int, count: int, shape_houses: Array[PackedInt32Array]) -> void:
	size = shape_size
	cell_count = count
	houses = shape_houses
	for c in count:
		cell_houses.append(PackedInt32Array())
	for h in houses.size():
		for c in houses[h]:
			cell_houses[c].append(h)
	for c in count:
		var seen := {}
		for h in cell_houses[c]:
			for p in houses[h]:
				if p != c:
					seen[p] = true
		var list := PackedInt32Array(seen.keys())
		list.sort()
		peers.append(list)


## The classic 9x9: cell r * 9 + c; houses in the web order: rows, columns, then boxes row-major.
static func classic9() -> Shape:
	var list: Array[PackedInt32Array] = []
	for r in 9:
		var row := PackedInt32Array()
		for c in 9:
			row.append(r * 9 + c)
		list.append(row)
	for c in 9:
		var col := PackedInt32Array()
		for r in 9:
			col.append(r * 9 + c)
		list.append(col)
	for br in range(0, 9, 3):
		for bc in range(0, 9, 3):
			var box := PackedInt32Array()
			for r in range(br, br + 3):
				for c in range(bc, bc + 3):
					box.append(r * 9 + c)
			list.append(box)
	return Shape.new(9, 81, list)
