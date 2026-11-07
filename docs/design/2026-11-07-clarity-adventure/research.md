# 화면 조사

2026-11-07, Google Play 영문 공식 등록정보와 스크린샷을 확인했다. 마케팅 이미지 안에 보이는 실제 UI 부분만 구조 관찰에 쓰고, 직접 플레이·시간 측정·검증된 전환율로 취급하지 않는다. 외부 이미지는 참고 자료로만 NAS에 보관하며 제품 아트나 생성 참조로 복사하지 않는다.

| 게임·출처 | 관찰 | 이번 설계에 적용하는 원리 |
|---|---|---|
| [Legend of Slime](https://play.google.com/store/apps/details?id=com.loadcomplete.slimeidle&hl=en_US) | 공식 설명은 자동 전투와 성장·보상을 연결한다. Village Raid 스크린샷의 전투 장면 위에 단계와 0/5 진행이 같이 보인다 | 플레이어가 손을 떼어도 무엇이 진행되는지 장면과 진행값으로 함께 보여 준다 |
| [AFK Journey](https://play.google.com/store/apps/details?id=com.farlightgames.igame.gp&hl=en_US) | 공식 전투 스크린샷의 오른쪽 UI에서 캐릭터와 적, HP가 같은 공간에 놓인다. 첫 모집 광고 이미지는 게임 실행 화면 근거에서 제외했다 | 전투의 주체와 결과를 같은 장면 안에서 보여 준다. 3D·영웅 모집 시스템은 가져오지 않는다 |
| [Melvor Idle](https://play.google.com/store/apps/details?id=com.malcs.melvoridle&hl=en_US) | Smithing 스크린샷은 만들 결과물, 필요 재료, Create 행동이 한 흐름이다. 공식 설명은 스킬 성장과 전투의 연계를 설명한다 | 현재 행동과 얻을 결과·다음 준비를 연결한다. 숫자 목록 중심의 전체 구성을 복제하지 않는다 |

기존 `game-ui-commercial`의 FTUE와 HUD 관찰 원리도 확인했다. 정량적인 UI 타이밍이나 성과 개선율을 이 세 이미지에서 추정하지 않았다. A안 추천은 외부 게임의 성공을 보장 근거로 삼은 것이 아니라, 사용자가 요청한 모험 장면에 캐릭터와 적이 더 크게 보인다는 판단이다.
