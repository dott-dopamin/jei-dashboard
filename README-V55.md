# JEI Dashboard V55

변경점:
- 잔룰 노트가 보드게임 책장 전체 목록과 분리됩니다.
- 잔룰 노트에는 직접 등록한 게임만 보입니다.
- 관리자에게 `+ 잔룰 추가` 버튼이 보입니다.
- 등록 폼은 게임명 + 메모만 있습니다.
- 게임명을 누르면 잔룰 팝업이 열립니다.
- 관리자 수정 모드에서는 메모가 자동 저장됩니다.
- 기존 `board_game_rule_notes` 데이터가 있다면 SQL 실행 시 작성된 메모만 새 테이블로 자동 이관됩니다.

적용 순서:
1. Supabase SQL Editor에서 `database/v55-standalone-rule-notes.sql` 실행
2. GitHub에 `rules-notes.html` 업로드
3. V54 공용 헤더를 아직 올리지 않았다면 `archive-header.css` 포함 전체 파일 업로드
