class_name Animals
extends RefCounted
## The nine animals; digit d is animal d. Each has its own ink (one ink per drawing). Names and facts
## are translation keys: ANIMAL_<ID>_NAME and ANIMAL_<ID>_FACT.

const COUNT := 9
const _IDS: Array[StringName] = [
	&"yaguarete",
	&"lobo_marino",
	&"pinguino",
	&"condor",
	&"hornero",
	&"yacare",
	&"flamenco",
	&"guanaco",
	&"ballena"
]
const _INKS := [
	"#b07d1c",
	"#6b5a4e",
	"#2f4a5c",
	"#5b3f8c",
	"#b5532a",
	"#3d6b4f",
	"#9c3d6b",
	"#7d6b4a",
	"#2a6a6e"
]
## Placeholders until the engraved drawings exist.
const _INITIALS := ["Y", "L", "P", "C", "H", "Yc", "F", "G", "B"]


static func id(digit: int) -> StringName:
	return _IDS[digit - 1]


static func ink(digit: int) -> Color:
	return Color(_INKS[digit - 1])


static func initial(digit: int) -> String:
	return _INITIALS[digit - 1]


static func name_key(digit: int) -> String:
	return "ANIMAL_%s_NAME" % String(id(digit)).to_upper()


static func fact_key(digit: int) -> String:
	return "ANIMAL_%s_FACT" % String(id(digit)).to_upper()
