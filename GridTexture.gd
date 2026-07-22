extends TextureRect

const TILE_SIZE := 24
const GRID_WIDTH := 30
const GRID_HEIGHT := 18

func _ready() -> void:
	var image := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)

	for x in TILE_SIZE:
		for y in TILE_SIZE:
			var color: Color
			if x == TILE_SIZE - 1 and y == TILE_SIZE - 1:
				color = Color(0.227, 0.227, 0.227)
			elif x == TILE_SIZE - 1 or y == TILE_SIZE - 1:
				color = Color(0.165, 0.165, 0.165)
			else:
				var noise := randi() % 7 - 3
				var v := 0.078 + noise * 0.0039
				color = Color(v, v, v)
			image.set_pixel(x, y, color)

	texture = ImageTexture.create_from_image(image)
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_TILE
