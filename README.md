# JEI Dashboard — 유지보수 기준본

기준일: 2026-10-04

이 폴더는 지금까지 만든 JEI 개인 대시보드 / GAME ARCHIVE / 팬데믹 S1 로그의 **현재 유지보수 기준본**입니다.
이전 V2~V49 수정본, `todo.html`, `memo.html`, 구형 `games.js` 등 현재 사이트에서 사용하지 않는 중복 파일은 제외했습니다.

## 실제 GitHub Pages에 필요한 파일

루트에는 아래 5개와 공용 스타일 파일이 있으면 됩니다.

- `index.html` — 개인 대시보드
  - 업무 캘린더 / TODO / 메모 / 단종 예정
  - 대한민국 공휴일 자동 표시
  - TODO 드래그 정렬
  - `GAME ARCHIVE` 진입 버튼
- `games.html` — 외부 공유용 GAME ARCHIVE
  - 가나다순 정렬
  - 장르 필터 / 확장 숨김
  - 관리자 로그인 시 게임 추가·수정·삭제
  - 확장 / 펀딩 배지
  - 팬데믹 S1 로그 링크
- `rules-notes.html` — 보드게임 잔룰 노트
  - 게임별 잔룰/예외/점수 계산 메모
  - 관리자 로그인 시 자동 저장
  - `games.html`에서 게임명 클릭 시 같은 내용을 팝업으로 즉시 확인
- `pandemic-legacy-s1.html` — 팬데믹 레거시 시즌 1 공동 기록
  - 공유 비밀번호 통과 시 공동 편집
  - 플레이어 / 캠페인 상태 / 메모 자동 저장
  - 회차 기록 추가·수정·삭제
  - 모바일 세로 레이아웃
- `style.css` — `index.html`, `games.html` 공용 기본 스타일

`database/` 폴더는 GitHub Pages 실행에 필요하지 않습니다. Supabase 구조를 복구하거나 유지보수할 때 참고하는 문서입니다.

## 현재 페이지 주소

- 개인 대시보드: `/jei-dashboard/`
- GAME ARCHIVE: `/jei-dashboard/games.html`
- 잔룰 노트: `/jei-dashboard/rules-notes.html`
- 팬데믹 S1 로그: `/jei-dashboard/pandemic-legacy-s1.html`

## 유지보수 원칙

1. 수정 시작 전 이 기준본 전체를 복사해 새 버전에서 작업합니다.
2. 페이지 하나만 수정했다면 그 HTML만 GitHub에 덮어써도 됩니다.
3. `style.css`를 수정하면 `index.html`과 `games.html`을 둘 다 확인합니다.
4. DB 컬럼을 추가하는 기능은 HTML만 올리지 말고 Supabase SQL도 함께 반영합니다.
5. `service_role` / Secret key는 절대 HTML이나 GitHub에 넣지 않습니다.
6. 현재 HTML에 들어 있는 Supabase 키는 **Publishable key**입니다.

## 비밀번호 관련

- 개인 대시보드 잠금은 브라우저 코드 안에서 동작하는 간단 잠금입니다. 보안 인증 수단으로 보지 않습니다.
- 팬데믹 공유 비밀번호는 Supabase `pandemic_legacy_s1_settings`에 저장되고 RPC 함수가 확인합니다.
- 팬데믹 비밀번호 변경 예시:

```sql
update public.pandemic_legacy_s1_settings
set access_code = '새비밀번호'
where id = 1;
```

## Supabase에서 현재 사용하는 주요 항목

- `todos`
- `notes`
- `calendar_events`
- `calendar_keywords`
- `discontinued_items`
- `board_games`
- `board_game_rule_notes`
- `pandemic_legacy_s1_state`
- `pandemic_legacy_s1_settings`
- Storage bucket: `board-game-images`

자세한 구조는 `database/current-schema-reference.sql` 참고.

## 제거한 구형 파일

현재 페이지에서 링크/스크립트로 사용되지 않아 유지보수 기준본에서 제외했습니다.

- `todo.html`
- `memo.html`
- `games.js`
- `app.js`
- `supabase-config.js`
- 과거 버전 ZIP 및 개별 migration SQL

기존 Supabase 데이터는 이 파일 정리와 무관하며 삭제되지 않습니다.

## V51 팬데믹 기록 보강

커뮤니티 기록 습관을 반영해 현재 활성 목표, 이번 달 추가 규칙/예외, 영구 상태 요약, 캐릭터별 상처·관계·업그레이드 메모를 추가했습니다. 기존 JSON 상태에 필드가 추가되는 방식이라 별도 팬데믹 DB 마이그레이션은 필요하지 않습니다.


## V51 추가 기능
- 보드게임 책장 카드 제목 클릭 잔룰 팝업은 제거했습니다. 잔룰은 `rules-notes.html`에서만 관리합니다.
- 팬데믹 S1 회차 기록마다 사진 1~3장을 첨부할 수 있습니다. 사진은 브라우저에서 자동 축소 후 별도 DB 테이블에 저장합니다.
- 최초 적용 시 `database/v51-required.sql`을 Supabase SQL Editor에서 한 번 실행하세요.
