extends SceneTree
const Catalog = preload("res://src/ui/pixel/painted_catalog.gd")
const Painter = preload("res://src/ui/pixel/painted_trainee_compositor.gd")
var failed:=0
var checks:=0
func _initialize()->void:
	var data:=Catalog.data()
	_check((data.get("bodies",{}) as Dictionary).size()==5,"주인공 의상 5종")
	_check((data.get("enemies",{}) as Dictionary).size()==15,"실제 적 ID 15종")
	_check((data.get("backgrounds",{}) as Dictionary).size()==9,"홈과 탐험 배경 9종")
	_check((data.get("gear",{}) as Dictionary).size()==9,"무기·방어구·장신구 9종")
	for id:String in data.get("enemies",{}):
		for clip:String in ["idle","attack","defeat"]:
			var texture:=Catalog.texture(str(data.enemies[id][clip].path))
			_check(texture!=null and texture.get_size()==Vector2(1152,128),"적 아틀라스 %s %s"%[id,clip])
	var compositor:=Painter.new()
	var base:=compositor.compose("balanced",{})
	_check(base!=null and base.get_size()==Vector2i(208,160),"장비 모션 여유를 둔 수련생 캔버스")
	for profile:String in data.get("profiles",[]):
		var image:=compositor.compose(profile,{})
		_check(image!=null and (profile=="balanced" or image.get_data()!=base.get_data()),"성장색 보존 "+profile)
	for id:String in data.get("gear",{}):
		var slot:=str(data.gear[id].slot)
		var image:=compositor.compose("balanced",{slot:id})
		_check(image!=null and image.get_data()!=base.get_data(),"장비 외형 연결 "+id)
	for id:String in data.get("bodies",{}):
		for clip:String in ["idle","walk","attack"]:
			var spec:Dictionary=data.bodies[id][clip]
			var texture:=Catalog.texture(str(spec.path))
			_check(texture!=null and texture.get_size()==Vector2(1152,1024),"의상·성장색·모션 아틀라스 %s %s"%[id,clip])
	_check(Catalog.texture("missing.png")==null,"누락 에셋은 빈 참조로 처리하고 입력·저장을 보존")
	_check((Catalog._textures as Dictionary).size()<=24 and (Catalog._images as Dictionary).size()<=8,"텍스처와 CPU 이미지 캐시 상한")
	print("[PAINTED-ART] checks=%d failed=%d"%[checks,failed])
	quit(0 if failed==0 else 1)
func _check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failed+=1
	print("[%s] %s"%["PASS" if ok else "FAIL",label])
