# Supabase 유지보수 메모

## GAME ARCHIVE 장르 허용값

- 전략
- 파티/패밀리
- 추리
- 마피아/디덕션
- 협력

## board_games 추가 필드

- `is_expansion` — 확장 배지 및 숨김 필터
- `is_funding` — 펀딩 배지

## calendar_events 추가 필드

- `end_date` — 연속 일정
- `is_holiday` — 사용자가 직접 지정한 공휴일 일정

대한민국 자동 공휴일 데이터는 현재 `index.html` 내부 상수로 들어 있으며 DB에 매년 저장하는 구조가 아닙니다.

## 팬데믹 S1

- 상태 전체를 `pandemic_legacy_s1_state.data` JSONB 한 건에 저장합니다.
- 비밀번호 사용자는 `get_pandemic_legacy_s1`, `save_pandemic_legacy_s1` RPC를 통해 읽기/쓰기 합니다.
- 비밀번호 자체는 `pandemic_legacy_s1_settings`에 저장합니다.

## 주의

Publishable key는 프론트엔드에 노출될 수 있지만 `service_role` 또는 Secret key는 절대 공개 저장소에 넣으면 안 됩니다.


## V50 잔룰 노트
- `board_game_rule_notes.game_id`는 `board_games.id`와 1:1 연결
- 외부 사용자는 SELECT만 가능
- 관리자 로그인 사용자는 자동 저장 편집 가능
- `games.html` 게임명 클릭 팝업과 `rules-notes.html`이 같은 데이터를 사용


## V51 팬데믹 회차 사진
- `pandemic_legacy_s1_photos`: 회차별 최대 3장. 클라이언트에서 1280px 이내 JPEG로 축소.
- 공유 비밀번호 사용자는 사진 테이블에 직접 접근하지 않고 `get/save/delete_pandemic_legacy_s1_*photo*` RPC로 접근합니다.
- 잔룰 노트는 보드게임 책장과 UI상 분리되어 `rules-notes.html`에서만 확인/편집합니다.
