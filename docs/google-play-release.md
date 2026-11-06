# Google Play 출시 절차

이 문서는 `왕립 아카데미: 수련생 육성`(`com.seoleeapps.princesstycoon`)을 Google Play에 올리는 방법이다. 결정과 근거는 `docs/design/2026-11-google-play-launch/design.md`, 출시 관문 증거는 `release/market-launch-state.json`에 있다.

## 고정값

| 항목 | 값 |
|---|---|
| 개발자 계정 | Seolee Apps, 개인 계정, ID `5547060480954653351` |
| 패키지 | `com.seoleeapps.princesstycoon` |
| 스토어 이름 | 왕립 아카데미: 수련생 육성 (ko-KR) |
| 국가 | 대한민국 |
| 가격·수익화 | 무료, 광고·인앱 결제 없음 |
| 대상 API·최소 API | 36 · 24(`godot/export_presets.cfg`에 명시) |
| 업로드 키 | 카탈로그 `app/princess-tycoon/google-play/upload-key`, 인증서 SHA-256 `BB:CF:E8:D7:B9:D2:65:61:7A:B8:41:4A:DC:26:58:79:50:84:A2:06:ED:11:E9:07:37:C8:3B:6A:39:E3:13:65` |
| 개인정보처리방침 | https://www.seorilabs.com/privacy/ |
| 고객 지원 | cs@seorilabs.com |

## 빌드

```bash
npm test                 # 문서·콘텐츠·아키텍처·도트·스토어 그림·Godot 스모크
npm run test:e2e         # 세 기기 화면 headless 여정
npm run build:android    # 서명한 AAB: build/android/princess-tycoon.aab(+ .sha256)
npm run check:play       # 등록정보·그림 검사(Console 전용 신고는 제외)
```

`build:android`는 Godot가 Android Gradle 템플릿을 `godot/android/`에 설치하고(저장소에 넣지 않는다) AAB를 만든 뒤, 서명 인증서가 위 업로드 키와 같은지 확인한다. 업로드 키는 카탈로그 항목의 동반 파일 `~/.config/seorilabs/play-store/princess-tycoon-keystore.env`(`ANDROID_KEYSTORE_FILE`, `ANDROID_KEYSTORE_ALIAS`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`)에서 읽고 값을 출력하지 않는다. 다른 위치를 쓰려면 `PRINCESS_TYCOON_KEYSTORE_ENV`로 지정한다.

버전을 올릴 때는 세 곳을 함께 바꾼다.
- `godot/export_presets.cfg`의 `version/code`(직전보다 1 크게)와 `version/name`
- `play-store/google-play.config.json`의 `release.versionCode`, `release.versionName`, 출시 노트
- `release/market-launch-state.json`의 `release.version`·`tag`와 Google Play `identity.build`(새 원장으로 시작)

## 그림

- 아이콘·대표 이미지·런처 아이콘: `python3 scripts/store_assets/generate.py`(도트 원본으로 생성, `npm run check:store-assets`가 재생성 결과와 비교)
- 스크린샷: `godot --path godot --script res://tests/store_screenshots.gd -- --out <폴더> --size=<가로>x<세로>`(휴대전화 1080×1920, 7인치 1215×2160, 10인치 1440×2560). 같은 seed로 197일 진행한 실제 상태를 렌더링한다.

## Console과 API

1. Console에서 앱을 만든다(게임, 무료, 기본 언어 한국어). 앱 콘텐츠 신고는 다음과 같다.
   - 개인정보처리방침: 위 URL
   - 앱 액세스: 모든 기능 사용 가능(로그인 없음)
   - 광고: 없음
   - 콘텐츠 등급: IARC 설문(폭력은 판타지 전투 묘사, 성적 내용·도박·실제 돈 거래·사용자 상호작용 없음)
   - 대상 연령: 13세 이상, 아동 대상 아님
   - 데이터 보안: 수집·공유하는 사용자 데이터 없음
2. 등록 그림과 문구는 `play-store/google-play.config.json`에서 올린다(`apply_play_store_listing.py`).
3. 같은 AAB를 내부 테스트에 올리고, 승인된 실기기 확인(설계 AND-01~07)을 마친 뒤 프로덕션(대한민국, 100%)으로 제출한다.
