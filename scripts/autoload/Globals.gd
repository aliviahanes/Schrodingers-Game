extends Node

# Constants
const DIALOGUE_DATA_PATH = "res://data/dialogue/"
const DIALOGUE_SPRITE_PATH = "res://sprites/"
const INPUT_GLYPH_PATH = "res://sprites/glyphs/"
const ICONS_PATH = "res://sprites/icons/"
const DIALOGUE_DEFAULT_SPEED = 19
const DIALOGUE_DESATURATION_TIME = 0.2
const DIALOGUE_DESATURATION_LOWER_BY = 150

# Dynamic Globals
var loaded_dialogue = {}
var loaded_speakers = {}
var auto_wait_time = 1.5
