extends RefCounted
## Original, translucent energy ribbons. No stock image or sprite copies are used.
const COLORS={
	"red":Color("ed5b68"),"orange":Color("ee8651"),"amber":Color("dea23c"),"gold":Color("edba59"),
	"yellow":Color("ffe275"),"lime":Color("bce179"),"green":Color("63c889"),"mint":Color("9ae6c5"),
	"teal":Color("35b6a9"),"cyan":Color("54e0e5"),"blue":Color("538fff"),"indigo":Color("7771dc"),
	"purple":Color("a477d8"),"violet":Color("ce7ee6"),"pink":Color("ee97c6"),"white":Color("e2edef")}
const NAMES={"red":"Vermelho","orange":"Laranja","amber":"Âmbar","gold":"Dourado","yellow":"Amarelo","lime":"Lima","green":"Verde","mint":"Menta","teal":"Turquesa","cyan":"Ciano","blue":"Azul","indigo":"Índigo","purple":"Roxo","violet":"Violeta","pink":"Rosa","white":"Branco"}
const ALIASES={"vermelho":"red","laranja":"orange","ambar":"amber","âmbar":"amber","dourado":"gold","amarelo":"yellow","lima":"lime","verde":"green","menta":"mint","turquesa":"teal","ciano":"cyan","azul":"blue","indigo":"indigo","índigo":"indigo","roxo":"purple","violeta":"violet","rosa":"pink","branco":"white"}
const THEMES={"red":"flame","orange":"flame","amber":"flame","gold":"flame","yellow":"flame","lime":"orbit","green":"orbit","mint":"orbit","teal":"orbit","cyan":"tide","blue":"tide","indigo":"spiral","purple":"spiral","violet":"spiral","pink":"spiral","white":"tide"}
const STYLES=["flame","orbit","spiral","tide"]
const BODY_ALPHA=.24
const CORE_ALPHA=.18
const GLOW_ALPHA=.035
const SAMPLES=24
static func canonical(value:String) -> String:
	var key:=value.strip_edges().to_lower()
	return key if COLORS.has(key) else str(ALIASES.get(key,"purple"))
static func style_for(palette:String,requested:="") -> String:
	return requested if requested in STYLES else str(THEMES[canonical(palette)])
static func _shape(path:PackedVector2Array,width:float) -> PackedVector2Array:
	var left:=PackedVector2Array()
	var right:=PackedVector2Array()
	for at in path.size():
		var tangent:=path[mini(path.size()-1,at+1)]-path[maxi(0,at-1)]
		var normal:=Vector2(-tangent.y,tangent.x).normalized()
		var t:=at/float(path.size()-1)
		var taper:=pow(maxf(0,sin(PI*t)),.72)
		var radius:=width*.5*taper
		left.append(path[at]+normal*radius)
		right.append(path[at]-normal*radius)
	for at in range(right.size()-1,-1,-1):left.append(right[at])
	return left
static func _ribbon(canvas:CanvasItem,path:PackedVector2Array,width:float,color:Color,weight:=1.0) -> void:
	if path.size()<3:return
	canvas.draw_polyline(path,Color(color,GLOW_ALPHA*weight),width*1.65,true)
	canvas.draw_colored_polygon(_shape(path,width),Color(color,BODY_ALPHA*weight))
	var light:=color.lerp(Color.WHITE,.42)
	canvas.draw_colored_polygon(_shape(path,width*.36),Color(light,CORE_ALPHA*weight))
static func _floor(canvas:CanvasItem,feet:Vector2,h:float,color:Color,time:float) -> void:
	var points:=PackedVector2Array()
	for at in SAMPLES:
		var angle:=time*.75+at/float(SAMPLES-1)*TAU*.79
		points.append(feet+Vector2(cos(angle)*h*.33,sin(angle)*h*.057))
	_ribbon(canvas,points,h*.027,color,.70)
static func _flame(canvas:CanvasItem,feet:Vector2,h:float,color:Color,time:float) -> void:
	for side in [-1,1]:
		var points:=PackedVector2Array()
		for at in SAMPLES:
			var t:=at/float(SAMPLES-1)
			var bend:=sin(t*TAU*1.10-time*1.6+side*.9)*.045
			var x:float=side*(.28-.13*t+bend+sin(t*PI)*.065)
			points.append(feet+Vector2(x,-.015-t*1.04)*h)
		_ribbon(canvas,points,h*.125,color)
		var curl:=PackedVector2Array()
		for at in SAMPLES:
			var t:=at/float(SAMPLES-1)
			var phase:float=t*TAU*.68+time*1.1+side
			curl.append(feet+Vector2(side*(.22+sin(phase)*.075),-.10-t*.53)*h)
		_ribbon(canvas,curl,h*.058,color,.70)
static func _spiral(canvas:CanvasItem,feet:Vector2,h:float,color:Color,time:float) -> void:
	for strand in 2:
		var points:=PackedVector2Array()
		for at in SAMPLES:
			var t:=at/float(SAMPLES-1)
			var angle:=t*TAU*.95-time*1.2+strand*PI
			var spread:=.26+sin(t*PI)*.08
			points.append(feet+Vector2(sin(angle)*spread,-t*1.03)*h)
		_ribbon(canvas,points,h*.082,color,.88)
static func _orbit(canvas:CanvasItem,feet:Vector2,h:float,color:Color,time:float) -> void:
	for ring in 2:
		var points:=PackedVector2Array()
		for at in SAMPLES:
			var t:=at/float(SAMPLES-1)
			var angle:=time*(.92 if ring==0 else -.72)+t*TAU*.82+ring*PI
			var center:=Vector2(0,-.33-ring*.34)
			var orbit:=Vector2(cos(angle)*.34,sin(angle)*.14)
			orbit.x+=sin(angle*2+time)*.035
			points.append(feet+(center+orbit)*h)
		_ribbon(canvas,points,h*.070,color,.88)
	var mote:=feet+Vector2(cos(time*.9)*h*.28,-h*.94+sin(time)*h*.025)
	canvas.draw_circle(mote,h*.050,Color(color,.20),true,-1,true)
	canvas.draw_arc(mote,h*.065,0,TAU*.78,16,Color(color,.19),h*.012,true)
static func _tide(canvas:CanvasItem,feet:Vector2,h:float,color:Color,time:float) -> void:
	for strand in 2:
		var points:=PackedVector2Array()
		for at in SAMPLES:
			var t:=at/float(SAMPLES-1)
			var phase:=t*TAU*.82-time*1.08+strand*PI
			var x:=sin(phase)*(.23+.08*sin(t*PI))
			points.append(feet+Vector2(x,-t*1.05)*h)
		_ribbon(canvas,points,h*(.10 if strand==0 else .055),color,.90 if strand==0 else .65)
static func draw_tinted(canvas:CanvasItem,feet:Vector2,height:float,color:Color,clock:float,reduced:bool,style:="flame") -> void:
	var h:=maxf(12,height)
	var time:=0.0 if reduced else clock
	_floor(canvas,feet,h,color,time)
	match style:
		"orbit":_orbit(canvas,feet,h,color,time)
		"spiral":_spiral(canvas,feet,h,color,time)
		"tide":_tide(canvas,feet,h,color,time)
		_:_flame(canvas,feet,h,color,time)
static func draw(canvas:CanvasItem,feet:Vector2,height:float,palette:String,clock:float,reduced:=false,style:="") -> void:
	var key:=canonical(palette)
	draw_tinted(canvas,feet,height,COLORS[key],clock,reduced,style_for(key,style))
