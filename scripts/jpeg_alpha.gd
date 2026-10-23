extends RefCounted
## JPEG RGB + lossless PNG alpha. Composed once and shared by effect/portrait users.
static var cache: Dictionary = {}
static func texture(path: String) -> Texture2D:
	if cache.has(path): return cache[path]
	var source: Texture2D = load(path)
	var alpha_path := path.get_basename()+"_alpha.png"
	if not path.ends_with(".jpg") or not ResourceLoader.exists(alpha_path): return source
	var rgb := source.get_image()
	rgb.convert(Image.FORMAT_RGBA8)
	var mask: Image = load(alpha_path).get_image()
	mask.convert(Image.FORMAT_L8)
	var bytes := rgb.get_data()
	var alpha := mask.get_data()
	var effect_sheet:=path.ends_with("/effects.jpg")
	var width:=rgb.get_width()
	var cell:=Vector2(width/6.0,rgb.get_height()/2.0)
	for at in alpha.size():
		var opacity:float=alpha[at]
		if effect_sheet:
			# Soft spell glows touch adjacent cells in the authored atlas. Fade only
			# the outer fringe so enlarging a spell never exposes a hard tile seam.
			var u:=fposmod(float(at%width)+0.5,cell.x)/cell.x
			var v:=fposmod(float(at/width)+0.5,cell.y)/cell.y
			var edge:=minf(minf(u,1-u),minf(v,1-v))
			opacity*=smoothstep(0.0,0.08,edge)
		bytes[at*4+3]=int(opacity)
	cache[path]=ImageTexture.create_from_image(Image.create_from_data(rgb.get_width(),rgb.get_height(),false,Image.FORMAT_RGBA8,bytes))
	return cache[path]
