extends SceneTree

# 품질 게이트의 compile 단계. 메인 장면을 실제처럼 띄워 모든 스크립트를 불러오되, 저장은 격리 경로에만 쓴다.
# 저장 경로 없이 메인 장면을 띄우면(`--quit-after`) 사용자의 기본 저장을 읽고 다시 쓸 수 있다.
const SAVE_PATH := "user://qa_compile_check_save.json"


func _initialize() -> void:
	_cleanup()
	ProjectSettings.set_setting("princess_tycoon/testing/save_path", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("[COMPILE] main.tscn load failed")
		quit(1)
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.queue_free()
	await process_frame
	_cleanup()
	print("[COMPILE] PASS main scene loaded with isolated save")
	quit(0)


func _cleanup() -> void:
	for path: String in [SAVE_PATH, SAVE_PATH + ".bak", SAVE_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
