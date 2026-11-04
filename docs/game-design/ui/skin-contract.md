# UI 스킨 계약 (방향 A. 아카데미 방)

`scripts/pixel_art/generate.py`가 `godot/assets/pixel/ui/skins.json`과 함께 만든다. 직접 고치지 말고 생성기를 고친다.
모든 값은 최종 파일 px(아트 1px = 2px)이다. 고대비 스킨은 같은 이름에 `_hc`를 붙인 파일이고 크기와 분할이 같다.

| 구성요소·상태 | 파일 | 크기 | 9분할 좌/상/우/하 | 내용 여백 좌/상/우/하 | 최소 표시 크기 | 가로 반복 |
|---|---|---|---|---|---|---|
| `window` | `window.png` | 24×24 | 6/6/6/6 | 12/10/12/10 | 24×24 |  |
| `window_gold` | `window_gold.png` | 24×24 | 6/6/6/6 | 12/10/12/10 | 24×24 |  |
| `window_accent` | `window_accent.png` | 24×24 | 6/6/6/6 | 12/10/12/10 | 24×24 |  |
| `window_selected` | `window_selected.png` | 24×24 | 6/6/6/6 | 12/10/12/10 | 24×24 |  |
| `inset` | `inset.png` | 16×16 | 4/4/4/4 | 10/8/10/8 | 16×16 |  |
| `strip` | `strip.png` | 24×28 | 6/6/6/6 | 12/6/12/6 | 24×28 |  |
| `sheet` | `sheet.png` | 32×32 | 10/10/10/10 | 16/14/16/14 | 32×32 |  |
| `toast` | `toast.png` | 24×24 | 6/6/6/6 | 14/10/14/10 | 24×24 |  |
| `chip` | `chip.png` | 16×16 | 4/4/4/4 | 8/2/8/2 | 16×16 |  |
| `gauge_bg` | `gauge_bg.png` | 12×12 | 4/4/4/4 | 0/0/0/0 | 12×12 |  |
| `focus` | `focus.png` | 24×28 | 6/6/6/6 | 0/0/0/0 | 24×28 |  |
| `tab_normal` | `tab_normal.png` | 24×28 | 6/6/6/6 | 4/6/4/6 | 24×28 |  |
| `tab_selected` | `tab_selected.png` | 24×28 | 6/6/6/6 | 4/6/4/6 | 24×28 |  |
| `scroll_grabber` | `scroll_grabber.png` | 8×16 | 2/4/2/4 | 0/0/0/0 | 8×16 |  |
| `scroll_bg` | `scroll_bg.png` | 8×16 | 2/4/2/4 | 0/0/0/0 | 8×16 |  |
| `button_primary_normal` | `button_primary_normal.png` | 24×28 | 6/6/6/8 | 12/8/12/10 | 44×44 |  |
| `button_primary_pressed` | `button_primary_pressed.png` | 24×28 | 6/6/6/8 | 12/10/12/8 | 44×44 |  |
| `button_primary_disabled` | `button_primary_disabled.png` | 24×28 | 6/6/6/8 | 12/8/12/10 | 44×44 |  |
| `button_gold_normal` | `button_gold_normal.png` | 24×28 | 6/6/6/8 | 12/8/12/10 | 44×44 |  |
| `button_gold_pressed` | `button_gold_pressed.png` | 24×28 | 6/6/6/8 | 12/10/12/8 | 44×44 |  |
| `button_gold_disabled` | `button_gold_disabled.png` | 24×28 | 6/6/6/8 | 12/8/12/10 | 44×44 |  |
| `button_secondary_normal` | `button_secondary_normal.png` | 24×28 | 6/6/6/8 | 12/8/12/10 | 44×44 |  |
| `button_secondary_pressed` | `button_secondary_pressed.png` | 24×28 | 6/6/6/8 | 12/10/12/8 | 44×44 |  |
| `button_secondary_disabled` | `button_secondary_disabled.png` | 24×28 | 6/6/6/8 | 12/8/12/10 | 44×44 |  |
| `button_danger_normal` | `button_danger_normal.png` | 24×28 | 6/6/6/8 | 12/8/12/10 | 44×44 |  |
| `button_danger_pressed` | `button_danger_pressed.png` | 24×28 | 6/6/6/8 | 12/10/12/8 | 44×44 |  |
| `button_danger_disabled` | `button_danger_disabled.png` | 24×28 | 6/6/6/8 | 12/8/12/10 | 44×44 |  |
| `gauge_fill_energy` | `gauge_fill_energy.png` | 8×12 | 0/0/0/0 | 0/0/0/0 | 8×12 | 예 |
| `gauge_fill_stress` | `gauge_fill_stress.png` | 8×12 | 0/0/0/0 | 0/0/0/0 | 8×12 | 예 |
| `gauge_fill_reputation` | `gauge_fill_reputation.png` | 8×12 | 0/0/0/0 | 0/0/0/0 | 8×12 | 예 |
| `gauge_fill_stat` | `gauge_fill_stat.png` | 8×12 | 0/0/0/0 | 0/0/0/0 | 8×12 | 예 |
| `gauge_fill_magic` | `gauge_fill_magic.png` | 8×12 | 0/0/0/0 | 0/0/0/0 | 8×12 | 예 |
| `gauge_fill_neutral` | `gauge_fill_neutral.png` | 8×12 | 0/0/0/0 | 0/0/0/0 | 8×12 | 예 |

버튼 상태는 같은 12×14 아트 캔버스를 쓴다. normal은 아래 2px 그림자, pressed는 1 아트픽셀 내려가고 그림자가 없다. focus는 바깥 점선 테두리만 있는 덧그림이다.
토글 아이콘(`toggle_on`, `toggle_off`, `toggle_disabled`)은 44×24이고 CheckButton 아이콘으로 쓴다.
