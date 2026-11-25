class_name Fireworks
extends Control
## The win's fanfare: a few bursts of sparks in the animals' inks over the whole screen, then the
## node frees itself. Seeded, so the same game always gets the same show. Never takes a tap.

signal burst(index: int)

const BURSTS := 6
const BURST_EVERY := 0.28
const SPARKS := 36
const SPARK_LIFE := 1.0
## Canvas units per second², on the 720-wide base canvas.
const GRAVITY := 260.0
const FLASH := 0.14
## The brighter inks (yaguareté, cóndor, hornero, yacaré, flamenco, ballena); the charcoal and dark
## blue read as grey sparks.
const DIGITS := [1, 4, 5, 6, 7, 9]

var _time := 0.0
var _fired := 0
## Per burst: {"at": Vector2 (fraction of the size), "ink": Color, "sparks": Array[Vector2]}.
var _bursts: Array[Dictionary] = []


func _init(seed_value: int = 0) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var digits := DIGITS.duplicate()
	for i in BURSTS:
		var sparks: Array[Vector2] = []
		var turn := rng.randf() * TAU
		for k in SPARKS:
			var a := turn + TAU * k / SPARKS + rng.randf_range(-0.08, 0.08)
			# Two rings: a fast outer one and a slower inner one, so a burst looks full.
			var speed := (
				rng.randf_range(230.0, 300.0) if k % 2 == 0 else rng.randf_range(120.0, 190.0)
			)
			sparks.append(Vector2.from_angle(a) * speed)
		var digit: int = digits[rng.randi() % digits.size()]
		digits.erase(digit)
		var at := Vector2(rng.randf_range(0.18, 0.82), rng.randf_range(0.14, 0.5))
		_bursts.append({"at": at, "ink": Animals.ink(digit), "sparks": sparks})


## How long the show lasts, from the first burst until the last spark fades.
static func length() -> float:
	return BURST_EVERY * (BURSTS - 1) + SPARK_LIFE


## Where a spark is, relative to its burst, age seconds after it: thrown out, then falling.
static func spark_offset(velocity: Vector2, age: float) -> Vector2:
	return velocity * age + Vector2(0, GRAVITY * age * age / 2.0)


static func spark_alpha(age: float) -> float:
	return pow(clampf(1.0 - age / SPARK_LIFE, 0.0, 1.0), 0.6)


func burst_color(index: int) -> Color:
	return _bursts[index].ink


## Moves the show on by dt seconds (called every frame; tests call it directly).
func advance(dt: float) -> void:
	_time += dt
	while _fired < BURSTS and _fired * BURST_EVERY <= _time:
		burst.emit(_fired)
		_fired += 1
	queue_redraw()
	if _time >= length():
		queue_free()


func _process(delta: float) -> void:
	advance(delta)


func _draw() -> void:
	var scale := size.x / 720.0 if size.x > 0 else 1.0
	for i in _fired:
		var b := _bursts[i]
		var age := _time - i * BURST_EVERY
		if age < 0 or age >= SPARK_LIFE:
			continue
		var origin: Vector2 = b.at * size
		var ink: Color = b.ink
		if age < FLASH:
			draw_circle(origin, 44.0 * scale * (1.0 - age / FLASH), Color(ink, 0.5), true, -1, true)
		var alpha := spark_alpha(age)
		var tail := maxf(age - 0.09, 0.0)
		for v: Vector2 in b.sparks:
			var head := origin + spark_offset(v, age) * scale
			var back := origin + spark_offset(v, tail) * scale
			draw_line(back, head, Color(ink, alpha * 0.8), 5.0 * scale, true)
			draw_circle(head, 4.0 * scale, Color(ink.lightened(0.25), alpha), true, -1, true)
