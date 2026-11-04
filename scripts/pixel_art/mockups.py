"""방향 시안 3종(홈·활동 목록)을 390×844로 렌더한다.

    python3 scripts/pixel_art/mockups.py --out docs/game-design/ui/directions-v1

이미지 생성 없이 코드 도트와 번들 OFL 픽셀 폰트만 쓴다. 같은 게임 상태와 실제 문구를 쓴다.
"""
from __future__ import annotations

import argparse
import json
import pathlib

from PIL import Image, ImageDraw

import icons
import scenes
import trainee
import ui_kit as K
from pixellib import ROOT, Art, Screen, font, rgb

W, H = 195, 422  # 아트 1px 캔버스 (논리 390×844)

STATE = {
    "name": "세라",
    "time": "1연차 · 1시즌",
    "gold": "2,840",
    "tier": "세계 티어 1",
    "activity": "응용 마력학",
    "progress": 0.6,
    "reason": "학문 방향 · 계약 목표 · 다양성",
    "meters": [("energy", "에너지", 82, 100), ("stress", "스트레스", 24, 72), ("reputation", "평판", 50, 100)],
    "stats": [("지력", 112, 8), ("마법", 88, 12), ("소통", 96, 4)],
    "recent": "왕립 교양학 완료 · 지력 +8",
    "events": 1,
    "categories": [("학습", 15), ("알바", 11), ("휴식", 4), ("모험", 5), ("시험", 8)],
    "mastery": {"EDU_MAGIC": 3, "EDU_LITERATURE": 5, "EDU_ETIQUETTE": 2, "EDU_MUSIC": 1},
    "locked": {"EDU_HIGHMAGIC": "세계 티어 2", "EDU_KNIGHT": "세계 티어 2", "EDU_PROTOCOL": "평판 60"},
}

TABS = [("home", "홈"), ("plan", "계획"), ("activity", "활동"), ("growth", "성장"), ("record", "기록")]


def education_rows() -> list[dict]:
    data = json.loads((ROOT / "godot" / "data" / "activities.json").read_text())
    rows = [a for a in data if a.get("kind") == "education"]
    order = ["EDU_MAGIC", "EDU_LITERATURE", "EDU_ETIQUETTE", "EDU_PAINTING", "EDU_MUSIC", "EDU_DANCE",
             "EDU_COOKING", "EDU_HOME", "EDU_HIGHMAGIC", "EDU_KNIGHT"]
    by_id = {a["id"]: a for a in rows}
    return [by_id[i] for i in order if i in by_id]


def place_trainee(a: Art, x: int, y: int, preset: str = "scholar") -> None:
    # 시안 당시 32×52 몸 좌표를 그대로 맞추려고 캔버스 여백(OX, OY)만큼 당겨 놓는다.
    figure = trainee.compose(preset, {"outfit": "OUTFIT_FORMAL", "accessory": "ACC_RIBBON"}, "focus")
    a.blit(figure, x - trainee.OX, y - trainee.OY)


def activity_bubble(a: Art, x: int, y: int, progress: float) -> None:
    K.bubble(a, x, y, 18, 16)
    a.blit(icons.icon("magic"), x + 3, y + 2)
    K.gauge(a, x - 1, y + 20, 20, 4, progress, K.METER_COLORS["magic"], rgb("2b1d24"), rgb("2b1d24"), segment=0)


# ---------------------------------------------------------------- A. 아카데미 방

class DirectionA:
    key = "A"
    title = "A. 아카데미 방"
    subtitle = "장면 중심 · 호두나무와 양피지 · 본문 Neo둥근모 16"
    s = K.STYLES["wood"]

    def hud(self, a: Art) -> None:
        K.wood_strip(a, 0, 0, W, 26, self.s)
        K.button(a, 3, 3, 20, 20, "secondary", self.s, under=self.s["strip"])
        a.blit(icons.icon("menu"), 9, 9)
        a.blit(icons.icon("coin"), 134, 5)

    def hud_text(self, sc: Screen) -> None:
        s = self.s
        sc.text(54, 6, STATE["name"], size=16, color=s["on_strip"])
        sc.text(54, 28, STATE["time"], size=16, color=s["on_strip_muted"])
        sc.text(290, 6, STATE["gold"] + " G", size=16, color=s["on_strip"], align="right", width=92)
        sc.text(240, 28, STATE["tier"], size=16, color=s["on_strip_muted"], align="right", width=142)

    def tabs(self, a: Art, selected: str) -> None:
        K.wood_strip(a, 0, 380, W, 42, self.s)
        for i, (key, _) in enumerate(TABS):
            x = i * 39
            if key == selected:
                a.rect(x + 1, 382, 37, 38, self.s["outline"])
                a.rect(x + 2, 383, 35, 36, self.s["selected"])
                a.hline(x + 2, 383, 35, self.s["selected_edge"])
                a.hline(x + 2, 384, 35, self.s["selected_edge"])
            a.blit(icons.icon(key), x + 13, 386)

    def tabs_text(self, sc: Screen, selected: str) -> None:
        for i, (key, label) in enumerate(TABS):
            color = self.s["text"] if key == selected else self.s["on_strip"]
            sc.text(i * 78, 812, label, size=16, color=color, align="center", width=78)

    def home(self) -> Screen:
        s = self.s
        a = Art(W, H, s["strip_lo"])
        self.hud(a)
        room = scenes.study_room(W, 210, "warm")
        a.blit(room, 0, 26)
        place_trainee(a, 92, 26 + 132)
        activity_bubble(a, 99, 26 + 106, STATE["progress"])
        # 장면 위 상태 창: 현재 활동과 일시정지
        K.parchment(a, 4, 30, 124, 34, s)
        K.gauge(a, 10, 54, 84, 6, STATE["progress"], K.METER_COLORS["magic"], s["gauge_bg"], s["outline"])
        K.button(a, 170, 30, 22, 22, "gold", s)
        a.blit(icons.icon("pause"), 177, 36)
        # 미터 띠
        K.parchment(a, 2, 237, W - 4, 36, s, under=s["strip_lo"])
        for i, (key, _, value, top) in enumerate(STATE["meters"]):
            x = 8 + i * 63
            a.blit(icons.icon(key), x, 243)
            K.gauge(a, x, 260, 56, 6, value / top, K.METER_COLORS[key], s["gauge_bg"], s["outline"])
        # 최근 결과 줄
        K.parchment(a, 2, 275, W - 4, 20, s, under=s["strip_lo"])
        # 행동 버튼
        K.button(a, 4, 298, 92, 26, "primary", s, under=s["strip_lo"])
        a.blit(icons.icon("play"), 12, 307)
        K.button(a, 99, 298, 92, 26, "gold", s, under=s["strip_lo"])
        a.blit(icons.icon("world"), 106, 304)
        K.button(a, 4, 328, 60, 24, "secondary", s, under=s["strip_lo"])
        K.button(a, 67, 328, 61, 24, "secondary", s, under=s["strip_lo"])
        a.blit(icons.icon("event"), 73, 334)
        K.button(a, 131, 328, 60, 24, "secondary", s, under=s["strip_lo"])
        self.tabs(a, "home")

        sc = Screen(a)
        self.hud_text(sc)
        sc.text(16, 70, "지금 · " + STATE["activity"], size=16, color=s["text"])
        sc.text(196, 104, "60%", size=16, color=s["text"])
        for i, (key, label, value, _) in enumerate(STATE["meters"]):
            x = 16 + i * 126
            sc.text(x + 20, 484, label, size=16, color=s["text"])
            sc.text(x, 484, "", size=16)
            sc.text(x + 56, 484, str(value), size=16, color=s["text"], align="right", width=56)
        sc.text(14, 556, "최근 · " + STATE["recent"], size=16, color=s["muted"])
        sc.text(44, 610, "자동 1회 실행", size=16, color=s["primary_text"], align="center", width=146)
        sc.text(238, 610, "월드 출정", size=16, color=s["gold_text"], align="center", width=142)
        sc.text(8, 666, "성장 방향", size=16, color=s["secondary_text"], align="center", width=120)
        sc.text(172, 666, "이벤트 1", size=16, color=s["secondary_text"], align="center", width=82)
        sc.text(262, 666, "방치 8시간", size=16, color=s["secondary_text"], align="center", width=120)
        sc.text(14, 718, "다음 이유 · " + STATE["reason"], size=16, color=rgb("fbefd0"))
        self.tabs_text(sc, "home")
        return sc

    def activities(self) -> Screen:
        s = self.s
        a = Art(W, H, s["strip_lo"])
        self.hud(a)
        K.parchment(a, 2, 28, W - 4, 26, s, under=s["strip_lo"])
        # 분류 탭(폴더 탭)
        for i, (label, count) in enumerate(STATE["categories"]):
            x = 2 + i * 38
            sel = i == 0
            a.rect(x, 56, 37, 24, s["outline"])
            a.rect(x + 1, 57, 35, 23 if sel else 22, s["panel"] if sel else s["secondary"])
            if sel:
                a.hline(x + 1, 57, 35, s["selected_edge"])
        K.parchment(a, 2, 79, W - 4, 299, s, under=s["strip_lo"])
        a.rect(3, 79, 36, 2, s["panel"])
        rows = education_rows()
        y = 84
        for act in rows[:9]:
            locked = act["id"] in STATE["locked"]
            current = act["id"] == "EDU_MAGIC"
            if current:
                a.rect(5, y - 1, W - 10, 34, rgb("fff0b8"))
            a.blit(icons.icon("lock" if locked else "activity"), 8, y + 4 if not locked else y + 6)
            if not locked:
                a.blit(icons.icon("coin"), 26, y + 20)
                a.blit(icons.icon("energy"), 70, y + 20)
                a.blit(icons.icon("stress"), 104, y + 20)
            K.button(a, 156, y + 5, 32, 22, "primary" if not locked else "secondary", s,
                     state="disabled" if locked else "normal", under=rgb("fff0b8") if current else s["panel"])
            a.hline(6, y + 32, W - 12, s["panel_lo"])
            y += 33
        self.tabs(a, "activity")

        sc = Screen(a)
        self.hud_text(sc)
        sc.text(14, 64, "활동 · 학습", size=16, color=s["text"])
        sc.text(170, 64, "추천과 같은 규칙", size=16, color=s["muted"], align="right", width=208)
        for i, (label, count) in enumerate(STATE["categories"]):
            sc.text(4 + i * 76, 124, f"{label} {count}", size=16, color=s["text"], align="center", width=76)
        y = 84
        for act in rows[:9]:
            locked = act["id"] in STATE["locked"]
            yy = y * 2
            name = act["name"]
            sc.text(48, yy + 6, name, size=16, color=s["muted"] if locked else s["text"])
            if locked:
                sc.text(48, yy + 38, "잠금 · " + STATE["locked"][act["id"]], size=16, color=rgb("a8463a"))
            else:
                sc.text(70, yy + 38, str(act["baseCost"]), size=16, color=s["text"])
                sc.text(158, yy + 38, str(act["energyDelta"]), size=16, color=s["text"])
                sc.text(226, yy + 38, f"+{act['stressDelta']}", size=16, color=s["text"])
                m = STATE["mastery"].get(act["id"])
                if m:
                    sc.text(220, yy + 6, f"숙련 {m}", size=16, color=s["muted"], align="right", width=80)
            sc.text(312, yy + 20, "1회", size=16, color=s["disabled_text"] if locked else s["primary_text"], align="center", width=64)
            y += 33
        self.tabs_text(sc, "activity")
        return sc


# ---------------------------------------------------------------- B. 왕실 상태 장부

class DirectionB:
    key = "B"
    title = "B. 왕실 상태 장부"
    subtitle = "정보 중심 · 남색 창과 금 모서리 · 제목 Galmuri 24 + 본문 Neo둥근모 16"
    s = dict(K.STYLES["ledger"])

    def __init__(self):
        self.s["bg_under"] = self.s["bg"]

    def header(self, a: Art) -> None:
        K.navy_window(a, 2, 2, W - 4, 28, self.s)
        a.blit(icons.icon("coin"), 128, 8)

    def header_text(self, sc: Screen) -> None:
        s = self.s
        sc.text(16, 14, "왕립 아카데미", role="title", size=24, color=s["text"])
        sc.text(270, 10, STATE["gold"] + " G", size=16, color=s["accent"], align="right", width=108)
        sc.text(220, 32, STATE["time"], size=16, color=s["muted"], align="right", width=158)

    def tabs(self, a: Art, selected: str) -> None:
        for i, (key, _) in enumerate(TABS):
            x = 2 + i * 38
            if key == selected:
                a.rect(x, 378, 37, 42, self.s["outline"])
                a.rect(x + 1, 379, 35, 40, self.s["gold"])
                a.rect(x + 2, 380, 33, 38, self.s["primary"])
            else:
                K.navy_window(a, x, 378, 37, 42, self.s)
            a.blit(icons.icon(key), x + 12, 383)

    def tabs_text(self, sc: Screen, selected: str) -> None:
        for i, (key, label) in enumerate(TABS):
            color = self.s["accent"] if key == selected else self.s["text"]
            sc.text(4 + i * 76, 810, label, size=16, color=color, align="center", width=74)

    def home(self) -> Screen:
        s = self.s
        a = Art(W, H, s["bg"])
        self.header(a)
        # 장면 창
        K.navy_window(a, 2, 32, W - 4, 136, s)
        room = scenes.study_room(W - 10, 104, "night")
        a.blit(room, 5, 35)
        place_trainee(a, 80, 35 + 50)
        activity_bubble(a, 87, 35 + 26, STATE["progress"])
        a.rect(5, 139, W - 10, 26, s["panel_lo"])
        a.hline(5, 139, W - 10, s["border2"])
        a.blit(icons.icon("magic"), 9, 146)
        K.gauge(a, 92, 148, 64, 8, STATE["progress"], K.METER_COLORS["magic"], s["gauge_bg"], s["outline"])
        K.button(a, 170, 38, 20, 20, "gold", s, under=s["panel_hi"])
        a.blit(icons.icon("pause"), 176, 44)
        # 이름표 탭
        a.rect(10, 28, 36, 10, s["outline"])
        a.rect(11, 29, 34, 8, s["gold"])
        # 상태 장부
        K.navy_window(a, 2, 170, W - 4, 116, s)
        y = 182
        for key, _, value, top in STATE["meters"]:
            a.blit(icons.icon(key), 10, y)
            K.gauge(a, 74, y + 1, 84, 6, value / top, K.METER_COLORS[key], s["gauge_bg"], s["outline"])
            y += 16
        a.hline(10, y + 1, W - 20, s["border2"])
        y += 6
        for _ in STATE["stats"]:
            K.gauge(a, 74, y + 1, 84, 6, 0.4, K.METER_COLORS["stat"], s["gauge_bg"], s["outline"])
            a.blit(icons.icon("up"), 162, y)
            y += 16
        # 명령 창
        K.navy_window(a, 2, 288, W - 4, 88, s)
        a.rect(6, 304, 89, 22, s["cursor_bar"])
        a.blit(icons.icon("cursor"), 9, 311)
        for i, (cx, cy) in enumerate(((6, 304), (100, 304), (6, 330), (100, 330))):
            pass
        a.blit(icons.icon("world"), 104, 309)
        a.blit(icons.icon("event"), 104, 335)
        self.tabs(a, "home")

        sc = Screen(a)
        self.header_text(sc)
        sc.text(26, 58, STATE["name"], size=16, color=s["gold_text"])
        sc.text(40, 292, STATE["activity"], size=16, color=s["text"])
        sc.text(320, 292, "60%", size=16, color=s["text"], align="right", width=56)
        y = 182
        for key, label, value, top in STATE["meters"]:
            sc.text(40, y * 2 - 2, label, size=16, color=s["text"])
            sc.text(320, y * 2 - 2, str(value), size=16, color=s["text"], align="right", width=56)
            y += 16
        y += 6
        for label, value, delta in STATE["stats"]:
            sc.text(20, y * 2 - 2, label, size=16, color=s["muted"])
            sc.text(300, y * 2 - 2, f"{value}", size=16, color=s["text"], align="right", width=20)
            sc.text(340, y * 2 - 2, f"+{delta}", size=16, color=rgb("8ee6a0"), align="right", width=36)
            y += 16
        sc.text(16, 584, "다음 · " + STATE["reason"], size=16, color=s["muted"])
        sc.text(30, 618, "자동 1회 실행", size=16, color=s["text"])
        sc.text(232, 618, "월드 출정", size=16, color=s["text"])
        sc.text(30, 670, "성장 방향", size=16, color=s["text"])
        sc.text(232, 670, "이벤트 1", size=16, color=s["accent"])
        sc.text(16, 714, "방치 최대 8시간 · 자동 진행 중", size=16, color=s["muted"])
        self.tabs_text(sc, "home")
        return sc

    def activities(self) -> Screen:
        s = self.s
        a = Art(W, H, s["bg"])
        self.header(a)
        K.navy_window(a, 2, 32, W - 4, 30, s)
        for i, _ in enumerate(STATE["categories"]):
            x = 7 + i * 37
            if i == 0:
                a.rect(x, 37, 35, 20, s["gold"])
                a.rect(x + 1, 38, 33, 18, s["primary"])
        K.navy_window(a, 2, 64, W - 4, 214, s)
        rows = education_rows()
        y = 70
        for act in rows[:9]:
            if act["id"] == "EDU_MAGIC":
                a.rect(6, y, W - 12, 22, s["cursor_bar"])
                a.blit(icons.icon("cursor"), 9, y + 7)
            if act["id"] in STATE["locked"]:
                a.blit(icons.icon("lock"), 9, y + 7)
            else:
                a.blit(icons.icon("coin"), 142, y + 7)
            y += 23
        K.navy_window(a, 2, 280, W - 4, 96, s)
        K.button(a, 8, 344, 90, 26, "gold", s, under=s["panel_lo"])
        K.button(a, 102, 344, 86, 26, "secondary", s, under=s["panel_lo"])
        a.blit(icons.icon("energy"), 10, 322)
        a.blit(icons.icon("stress"), 70, 322)
        self.tabs(a, "activity")

        sc = Screen(a)
        self.header_text(sc)
        for i, (label, count) in enumerate(STATE["categories"]):
            sc.text(14 + i * 74, 82, f"{label}", size=16, color=s["accent"] if i == 0 else s["text"], align="center", width=70)
        y = 70
        for act in rows[:9]:
            locked = act["id"] in STATE["locked"]
            sc.text(40, y * 2 + 14, act["name"], size=16, color=s["disabled_text"] if locked else s["text"])
            if locked:
                sc.text(250, y * 2 + 14, STATE["locked"][act["id"]], size=16, color=s["disabled_text"], align="right", width=128)
            else:
                sc.text(302, y * 2 + 14, f"{act['baseCost']}", size=16, color=s["accent"], align="right", width=76)
            y += 23
        cur = rows[0]
        sc.text(18, 574, cur["name"], role="title", size=24, color=s["accent"])
        sc.text(200, 578, "숙련 3", size=16, color=s["muted"], align="right", width=176)
        sc.text(40, 640, f"{cur['energyDelta']}", size=16, color=s["text"])
        sc.text(160, 640, f"+{cur['stressDelta']}", size=16, color=s["text"])
        sc.text(232, 640, "마법 ▲", size=16, color=rgb("8ee6a0"))
        sc.text(18, 610, "안전한 마력 회로를 그리고 원리를 익힌다.", size=16, color=s["muted"])
        sc.text(16, 700, "1회 실행", size=16, color=s["gold_text"], align="center", width=180)
        sc.text(204, 700, "자동 큐에 추가", size=16, color=s["text"], align="center", width=172)
        self.tabs_text(sc, "activity")
        return sc


# ---------------------------------------------------------------- C. 그림책 디오라마

class DirectionC:
    key = "C"
    title = "C. 그림책 디오라마"
    subtitle = "큰 장면과 큰 글자 · 파스텔 두꺼운 테두리 · 전부 Galmuri 24(2배 격자)"
    s = K.STYLES["storybook"]

    def tabs(self, a: Art, selected: str) -> None:
        for i, (key, _) in enumerate(TABS):
            x = 2 + i * 38
            sel = key == selected
            a.rect(x, 376, 37, 44, self.s["outline"])
            a.rect(x + 1, 377, 35, 42, self.s["frame"] if sel else self.s["tab"])
            a.hline(x + 1, 377, 35, self.s["border"])
            K.cut_corners(a, x, 376, 37, 44, 2, self.s["bg"])
            a.blit(icons.icon(key), x + 12, 381)

    def tabs_text(self, sc: Screen, selected: str) -> None:
        for i, (key, label) in enumerate(TABS):
            color = rgb("ffffff") if key == selected else self.s["text"]
            sc.text(4 + i * 76, 806, label, role="title", size=24, color=color, align="center", width=74,
                    shadow=self.s["frame_lo"] if key == selected else None)

    def home(self) -> Screen:
        s = self.s
        a = Art(W, H, s["bg"])
        K.story_frame(a, 0, 0, W, 256, s, fill=False)
        room = scenes.study_room(W - 8, 248, "pastel")
        a.blit(room, 4, 4)
        place_trainee(a, 86, 4 + 156)
        activity_bubble(a, 93, 4 + 130, STATE["progress"])
        # 모서리 버튼과 골드 판
        K.button(a, 8, 8, 24, 24, "secondary", s, under=rgb("fde8d4"))
        a.blit(icons.icon("menu"), 16, 16)
        K.story_frame(a, 112, 7, 78, 26, s, under=rgb("fde8d4"))
        a.blit(icons.icon("coin"), 119, 16)
        K.button(a, 166, 38, 24, 24, "gold", s, under=rgb("fde8d4"))
        a.blit(icons.icon("pause"), 174, 46)
        K.story_frame(a, 104, 38, 58, 24, s, under=rgb("fde8d4"))
        # 미터 알약
        for i, (key, _, value, _) in enumerate(STATE["meters"]):
            x = 10 + i * 60
            a.rect(x, 222, 56, 24, s["outline"])
            a.rect(x + 1, 223, 54, 22, s["panel"])
            K.cut_corners(a, x, 222, 56, 24, 2, rgb("e8c8a8"))
            a.blit(icons.icon(key), x + 6, 230)
        # 메시지 상자
        K.story_frame(a, 0, 258, W, 78, s)
        a.rect(8, 270, 28, 28, s["outline"])
        a.rect(9, 271, 26, 26, rgb("fde8d4"))
        a.blit(trainee.portrait("scholar", 24), 10, 272)
        a.rect(40, 250, 40, 17, s["outline"])
        a.rect(41, 251, 38, 15, s["frame"])
        # 큰 버튼
        K.button(a, 2, 338, 94, 36, "primary", s, under=s["bg"])
        a.blit(icons.icon("play"), 12, 351)
        K.button(a, 99, 338, 94, 36, "gold", s, under=s["bg"])
        a.blit(icons.icon("world"), 106, 348)
        self.tabs(a, "home")

        sc = Screen(a)
        sc.text(214, 86, "방치 8h", role="title", size=24, color=s["text"], align="center", width=100)
        sc.text(256, 22, STATE["gold"], role="title", size=24, color=s["text"], align="right", width=114)
        for i, (key, _, value, _) in enumerate(STATE["meters"]):
            sc.text(20 + i * 120 + 18, 454, str(value), role="title", size=24, color=s["text"], align="right", width=80)
        sc.text(80, 504, STATE["name"], role="title", size=24, color=rgb("ffffff"), shadow=s["frame_lo"], align="center", width=80)
        sc.text(88, 548, "응용 마력학 공부 중!", role="title", size=24, color=s["text"])
        sc.text(88, 592, "학문 방향에 딱 맞아요.", role="title", size=24, color=s["muted"])
        sc.text(46, 692, "1회 실행", role="title", size=24, color=s["primary_text"], align="center", width=142)
        sc.text(240, 692, "월드 출정", role="title", size=24, color=s["gold_text"], align="center", width=144)
        self.tabs_text(sc, "home")
        return sc

    def activities(self) -> Screen:
        s = self.s
        a = Art(W, H, s["bg"])
        K.story_frame(a, 0, 0, W, 34, s)
        a.blit(icons.icon("coin"), 128, 13)
        for i, _ in enumerate(STATE["categories"]):
            x = 2 + i * 38
            sel = i == 0
            a.rect(x, 37, 37, 28, s["outline"])
            a.rect(x + 1, 38, 35, 26, s["frame"] if sel else s["tab"])
            K.cut_corners(a, x, 37, 37, 28, 2, s["bg"])
        K.story_frame(a, 0, 67, W, 307, s)
        rows = education_rows()
        y = 73
        for act in rows[:6]:
            locked = act["id"] in STATE["locked"]
            if act["id"] == "EDU_MAGIC":
                a.rect(5, y - 1, W - 10, 48, rgb("fff0c8"))
            a.blit(icons.icon("lock" if locked else "activity"), 9, y + 4)
            if not locked:
                a.blit(icons.icon("coin"), 26, y + 30)
                a.blit(icons.icon("energy"), 74, y + 30)
                a.blit(icons.icon("stress"), 122, y + 30)
            K.button(a, 160, y + 10, 28, 28, "primary", s, state="disabled" if locked else "normal",
                     under=rgb("fff0c8") if act["id"] == "EDU_MAGIC" else s["panel"])
            a.hline(8, y + 48, W - 16, s["panel_lo"])
            y += 50
        self.tabs(a, "activity")

        sc = Screen(a)
        sc.text(20, 20, "활동", role="title", size=24, color=s["text"])
        sc.text(250, 20, STATE["gold"], role="title", size=24, color=s["text"], align="right", width=120)
        for i, (label, _) in enumerate(STATE["categories"]):
            sc.text(4 + i * 76, 88, label, role="title", size=24, color=rgb("ffffff") if i == 0 else s["text"], align="center", width=74,
                    shadow=s["frame_lo"] if i == 0 else None)
        y = 73
        for act in rows[:6]:
            locked = act["id"] in STATE["locked"]
            yy = y * 2
            sc.text(52, yy + 4, act["name"], role="title", size=24, color=s["muted"] if locked else s["text"])
            if locked:
                sc.text(52, yy + 52, STATE["locked"][act["id"]], role="title", size=24, color=rgb("c4607a"))
            else:
                sc.text(72, yy + 52, str(act["baseCost"]), role="title", size=24, color=s["text"])
                sc.text(166, yy + 52, str(act["energyDelta"]), role="title", size=24, color=s["text"])
                sc.text(262, yy + 52, f"+{act['stressDelta']}", role="title", size=24, color=s["text"])
            sc.text(320, yy + 34, "1회", role="title", size=24, color=s["disabled_text"] if locked else s["primary_text"], align="center", width=56)
            y += 50
        self.tabs_text(sc, "activity")
        return sc


DIRECTIONS = [DirectionA(), DirectionB(), DirectionC()]


def device_preview(screen: Screen, box, scale: float = 1080 / 390) -> Image.Image:
    """1080폭 기기에서 정수가 아닌 배율(2.769)로 그려질 때의 모습. nearest 확대로 근사한다."""
    crop = screen.img.crop(box)
    return crop.resize((int(crop.width * scale), int(crop.height * scale)), Image.NEAREST)


def compose_sheet(rendered: dict, out: pathlib.Path) -> None:
    gap, head = 24, 92
    sw, sh = 390, 844
    sheet = Image.new("RGB", (gap + 3 * (2 * sw + gap) + 2 * gap, head + sh + gap * 2), rgb("1b1b22")[:3])
    d = ImageDraw.Draw(sheet)
    d.fontmode = "1"
    for i, direction in enumerate(DIRECTIONS):
        x = gap + i * (2 * sw + gap * 2)
        d.text((x, 18), direction.title, font=font("title", 24), fill=(255, 240, 200))
        d.text((x, 54), direction.subtitle, font=font("body", 16), fill=(200, 200, 220))
        home, act = rendered[direction.key]
        sheet.paste(home.img.convert("RGB"), (x, head))
        sheet.paste(act.img.convert("RGB"), (x + sw + gap // 2, head))
    sheet.save(out / "directions-v1.png")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default=str(ROOT / "docs" / "game-design" / "ui" / "directions-v1"))
    args = parser.parse_args()
    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    rendered = {}
    for direction in DIRECTIONS:
        home = direction.home()
        act = direction.activities()
        home.save(out / f"{direction.key}-home-390x844.png")
        act.save(out / f"{direction.key}-activity-390x844.png")
        device_preview(home, (0, 440, 390, 760)).convert("RGB").save(out / f"{direction.key}-home-1080w-crop.png")
        rendered[direction.key] = (home, act)
    compose_sheet(rendered, out.parent)
    print("rendered", out)


if __name__ == "__main__":
    main()
