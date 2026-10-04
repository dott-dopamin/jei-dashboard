# JEI Dashboard V66

V65(팬데믹 모바일 상태 2x2 + 잔룰 모바일 팝업 스크롤 수정)을 포함하고, GAME ARCHIVE에 `플레이 로그 📅`를 추가한 버전입니다.

## 업로드 파일
- index.html
- games.html
- play-log.html (신규)
- rules-notes.html
- pandemic-legacy-s1.html
- style.css
- archive-header.css (4개 GAME ARCHIVE 페이지 공통 헤더)

## Supabase
GitHub 업로드 전에 `database/v66-play-log.sql`을 SQL Editor에서 1회 실행하세요.

## 플레이 로그
관리자 로그인 상태에서 기록 추가/수정/삭제 가능. 외부 방문자는 읽기만 가능합니다.
기록 항목: 게임명, 날짜, 같이 한 사람, 인원, 장소, 결과/점수, 재플레이 태그, 한줄평, 첫 플레이, 확장 사용.

페이지 상단에 총 플레이 / 플레이한 게임 / 올해 플레이 / 미플 보유게임과 올해 TOP 5를 자동 집계합니다.
