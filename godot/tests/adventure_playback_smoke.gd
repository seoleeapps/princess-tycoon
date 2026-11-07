extends SceneTree
const SOURCE := "res://src/ui/adventure_playback.gd"
var failed := 0
var checks := 0
func _initialize() -> void:
	if not ResourceLoader.exists(SOURCE):
		_check(false, "AD-01 실제 원정 기록 재생기가 있어야 함")
		quit(1)
		return
	var player: RefCounted = (load(SOURCE) as GDScript).new()
	var outcome := {"won": true, "nodes": [{"node": 1, "type": "exploration", "event": "지도 조각 발견", "remainingHp": 100}], "presentation": {"version": 1, "maxPlayerHp": 100, "nodes": [{"node": 1, "type": "exploration", "event": "지도 조각 발견", "remainingHp": 100}, {"node": 2, "type": "encounter", "enemyId": "EN_FOREST_VINE", "enemyMaxHp": 40, "initialPlayerHp": 100, "won": true, "remainingHp": 93, "turns": [{"actor": "trainee", "damage": 20, "playerHp": 100, "enemyHp": 20}, {"actor": "enemy", "damage": 7, "playerHp": 93, "enemyHp": 20}, {"actor": "trainee", "damage": 20, "playerHp": 93, "enemyHp": 0}]}]}}
	var before := JSON.stringify(outcome)
	player.call("set_outcome", "first", outcome)
	_check(str((player.call("current") as Dictionary).type) == "exploration", "AD-01 탐색부터 시작")
	player.call("advance", 0.5, true, false)
	var elapsed := float(player.get("elapsed"))
	player.call("advance", 1.0, false, false)
	_check(float(player.get("elapsed")) == elapsed, "AD-05 정지·비활성 중 시간 고정")
	player.call("advance", 1.0, true, true)
	_check(float(player.get("elapsed")) == elapsed, "AD-05 모션 줄이기에서 시간 고정")
	player.call("set_outcome", "first", outcome)
	_check(float(player.get("elapsed")) == elapsed, "AD-05 같은 장면 홈 재진입에 초기화 안 함")
	player.call("skip")
	_check(bool((player.call("current") as Dictionary).get("finished", false)), "AD-02 건너뛰면 결과로 이동")
	_check(JSON.stringify(outcome) == before, "AD-02 재생·건너뛰기는 판정·보상을 바꾸지 않음")
	player.call("set_outcome", "legacy", {"won": false, "nodes": [{"type": "encounter", "won": false, "remainingHp": 0}]})
	_check(not bool((player.call("current") as Dictionary).get("has_turns", true)), "AD-05 옛 기록에서 없는 피해를 만들지 않음")
	player.call("set_outcome", "broken", {"won": false, "nodes": [], "presentation": {"version": 1, "nodes": "bad"}})
	_check(bool((player.call("current") as Dictionary).get("finished", false)), "AD-05 잘못된 장면 기록은 결과만 표시")
	player.call("set_outcome", "broken-numbers", {"won": false, "presentation": {"version": 1, "nodes": [{"node": 1, "type": "encounter", "enemyMaxHp": []}]}})
	_check(bool((player.call("current") as Dictionary).get("finished", false)), "AD-05 파손된 숫자는 가짜 HP로 표시하지 않음")
	print("[ADVENTURE-PLAYBACK] checks=%d failed=%d" % [checks, failed])
	quit(0 if failed == 0 else 1)
func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:failed += 1
	print("[%s] %s" % ["PASS" if ok else "FAIL", label])
