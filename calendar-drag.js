/* V112 | Drag manual calendar entries between dates.
 * Leaves, auto holidays and personal dashboard data outside calendar_events are untouched.
 */
(function () {
  'use strict';
  const calendar = document.getElementById('calendar');
  if (!calendar || calendar.dataset.dragReady) return;
  calendar.dataset.dragReady = 'true';

  let active = null;
  let target = null;
  let saving = false;
  let suppressClickUntil = 0;

  const text = (value) => String(value ?? '');
  const dayCell = (node) => node?.closest?.('.day[data-calendar-date]');
  const eventCard = (node) => node?.closest?.('.calendar-drag-chip[data-event-id]');

  function findCalendarEvent(id) {
    for (const date of Object.keys(events)) {
      const item = (events[date] || []).find((entry) => entry.id === id && !entry.auto && !entry.leave);
      if (item) return item;
    }
    return null;
  }

  function dayOffset(from, to) {
    const u = (value) => {
      const [year, month, day] = value.split('-').map(Number);
      return Date.UTC(year, month - 1, day);
    };
    return Math.round((u(to) - u(from)) / 86400000);
  }

  function clearHighlight() {
    if (target) target.classList.remove('calendar-drop-target');
    target = null;
    calendar.classList.remove('calendar-is-dragging');
    calendar.querySelectorAll('.calendar-dragging').forEach((chip) => chip.classList.remove('calendar-dragging'));
  }

  function notify(message, error = false) {
    let el = document.getElementById('calendarDragStatus');
    if (!el) {
      el = document.createElement('p');
      el.id = 'calendarDragStatus';
      el.className = 'calendar-drag-status';
      el.setAttribute('role', 'status');
      el.setAttribute('aria-live', 'polite');
      calendar.insertAdjacentElement('afterend', el);
    }
    el.textContent = message;
    el.classList.toggle('is-error', error);
  }

  async function moveEvent(drag, newDate) {
    if (!dashboardUser) return notify('먼저 로그인해 주세요.', true);
    const item = findCalendarEvent(drag.id);
    if (!item) return notify('이동할 일정을 찾지 못했어요. 화면을 새로고침해 주세요.', true);

    const delta = dayOffset(drag.fromDate, newDate);
    if (!Number.isInteger(delta) || delta === 0) return;

    const start = addDays(item.start, delta);
    const end = addDays(item.end, delta);

    // A multi-day event is shifted as a whole, preserving its number of days.
    // The card picked up on a particular day lands on the exact day where released.
    try {
      const { data, error } = await db.from('calendar_events')
        .update({ event_date: start, end_date: end, updated_at: new Date().toISOString() })
        .eq('id', item.id)
        .select('id')
        .single();
      if (error || !data) throw error || new Error('일정 수정 권한이 없거나 일정이 이미 삭제됐어요.');

      Object.keys(events).forEach((day) => {
        events[day] = events[day].filter((entry) => entry.id !== item.id);
        if (!events[day].length) delete events[day];
      });
      addEventToMap({ ...item, start, end });
      drawCalendar();
      if (selected) drawEventList();
      notify('✓ ' + text(item.text) + ' 일정이 ' + start + (start !== end ? ' ~ ' + end : '') + '로 이동했어요.');
    } catch (err) {
      notify('일정 이동을 저장하지 못했어요. 기존 날짜는 유지돼요.', true);
      alert('일정 이동 실패: ' + (err?.message || '네트워크 및 로그인 상태를 확인해 주세요.'));
    }
  }

  calendar.addEventListener('dragstart', (event) => {
    const chip = eventCard(event.target);
    if (!chip || saving) return;
    const cell = dayCell(chip);
    if (!cell) return;
    const id = chip.dataset.eventId;
    if (!findCalendarEvent(id)) {
      event.preventDefault();
      return;
    }
    active = { id, fromDate: cell.dataset.calendarDate };
    if (event.dataTransfer) {
      event.dataTransfer.effectAllowed = 'move';
      event.dataTransfer.setData('text/plain', id);
    }
    calendar.classList.add('calendar-is-dragging');
    chip.classList.add('calendar-dragging');
  });

  calendar.addEventListener('dragover', (event) => {
    if (!active || saving) return;
    const cell = dayCell(event.target);
    if (!cell) return;
    event.preventDefault();
    if (event.dataTransfer) event.dataTransfer.dropEffect = 'move';
    if (target !== cell) {
      if (target) target.classList.remove('calendar-drop-target');
      target = cell;
      target.classList.add('calendar-drop-target');
    }
  });

  calendar.addEventListener('dragleave', (event) => {
    if (target && !target.contains(event.relatedTarget)) {
      target.classList.remove('calendar-drop-target');
      target = null;
    }
  });

  calendar.addEventListener('drop', (event) => {
    if (!active || saving) return;
    const cell = dayCell(event.target);
    if (!cell) return;
    event.preventDefault();
    event.stopPropagation();
    const drag = active;
    active = null;
    const date = cell.dataset.calendarDate;
    suppressClickUntil = Date.now() + 500;
    clearHighlight();
    saving = true;
    Promise.resolve(moveEvent(drag, date)).finally(() => { saving = false; });
  });

  calendar.addEventListener('dragend', () => {
    active = null;
    suppressClickUntil = Date.now() + 350;
    clearHighlight();
  });

  // Prevent the existing day-click handler from opening the event modal on drop.
  calendar.addEventListener('click', (event) => {
    if (Date.now() < suppressClickUntil) {
      event.preventDefault();
      event.stopImmediatePropagation();
    }
  }, true);

  window.JeiCalendarDrag = { isEnabled: true };
})();