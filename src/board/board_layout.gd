class_name BoardLayout
extends RefCounted
## Screen-size math: a portrait column at most 720 units wide, centred, and a square board as large
## as fits next to the rest of the screen ("chrome": header, tabs, palette, tools, gaps).

const MAX_COLUMN := 720.0


static func column_width(viewport: Vector2) -> float:
	return minf(viewport.x, MAX_COLUMN)


static func column_left(viewport: Vector2) -> float:
	return (viewport.x - column_width(viewport)) / 2.0


static func board_side(viewport: Vector2, chrome_height: float) -> float:
	return maxf(0.0, minf(column_width(viewport), viewport.y - chrome_height))
