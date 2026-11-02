/* JEI Dashboard V111 — per-user annual leave manager. */
(function(){
'use strict';
var entries=[], annual=[], ready=false, loadError='', identity=null, loadToken=0, editId=null, saving=false, selectedYear=new Date().getFullYear();
var byId=function(id){return document.getElementById(id);};
var escapeHtml=function(value){return String(value==null?'':value).replace(/[&<>"']/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c];});};
var todayKey=function(){var d=new Date();return [d.getFullYear(),String(d.getMonth()+1).padStart(2,'0'),String(d.getDate()).padStart(2,'0')].join('-');};
var offsetDate=function(key,n){var p=key.split('-').map(Number),d=new Date(p[0],p[1]-1,p[2]+n);return [d.getFullYear(),String(d.getMonth()+1).padStart(2,'0'),String(d.getDate()).padStart(2,'0')].join('-');};
var isWorkday=function(key){if(!/^\d{4}-\d{2}-\d{2}$/.test(key))return false;var p=key.split('-').map(Number),d=new Date(p[0],p[1]-1,p[2]);if(d.getFullYear()!==p[0]||d.getMonth()!==p[1]-1||d.getDate()!==p[2])return false;return d.getDay()!==0&&d.getDay()!==6&&!(typeof AUTO_HOLIDAYS!=='undefined'&&AUTO_HOLIDAYS[key]);};
var datesOf=function(e){var a=[],key=e.start_date,until=e.end_date;for(var n=0;n<370&&key<=until;n++,key=offsetDate(key,1)){if(isWorkday(key))a.push(key);}return a;};
var units=function(e){return datesOf(e).length*(e.leave_type==='full'?1:0.5);};
var label=function(t){return t==='am'?'오전 반차':t==='pm'?'오후 반차':'연차';};
var tone=function(t){return t==='full'?'#dcf1e7':'#ffe9d5';};
var yearTotal=function(y){var found=annual.find(function(x){return +x.year===+y;});return found?Number(found.total_days):null;};
var byYear=function(y){return entries.filter(function(e){return +e.start_date.slice(0,4)===+y;});};
var isReady=function(){if(!ready||!identity){alert('연차 관리용 Supabase 테이블이 아직 준비되지 않았어요. 관리자가 SQL을 먼저 적용해야 해요.');return false;}return true;};
var usable=function(e){var days=datesOf(e);return days.length>0&&!(e.leave_type!=='full'&&(e.start_date!==e.end_date||days.length!==1));};
var sums=function(y){var used=0,planned=0,today=todayKey();byYear(y).forEach(function(e){datesOf(e).forEach(function(k){var amount=e.leave_type==='full'?1:0.5;if(k<=today)used+=amount;else planned+=amount;});});return {used:used,planned:planned};};
function install(){
 var panel=document.querySelector('.calendar-panel'),head=panel&&panel.querySelector('.section-head');
 if(!head||byId('leaveManagerTab'))return;
 var tabs=document.createElement('div');tabs.className='leave-top-tabs';tabs.setAttribute('role','tablist');tabs.setAttribute('aria-label','업무 일정 보기 선택');
 tabs.innerHTML='<button type="button" class="active" id="leaveTabCalendar" role="tab" aria-selected="true" aria-controls="leaveCalendarTab">업무 캘린더</button><button type="button" id="leaveTabManager" role="tab" aria-selected="false" aria-controls="leaveManagerTab">연차 관리</button>';
 head.insertBefore(tabs,head.querySelector('.month-nav'));
 var wrapper=document.createElement('div');wrapper.id='leaveCalendarTab';wrapper.setAttribute('role','tabpanel');
 var rule=panel.querySelector('.calendar-rules');panel.insertBefore(wrapper,rule);
 ['.calendar-rules','.week','#calendar','.cal-help'].forEach(function(sel){var node=panel.querySelector(sel);if(node&&node!==wrapper)wrapper.appendChild(node);});
 var area=document.createElement('div');area.id='leaveManagerTab';area.setAttribute('role','tabpanel');area.hidden=true;
 area.innerHTML=[
 '<div class="leave-manager-head"><label for="leaveYearSelect">관리 연도</label><select id="leaveYearSelect" aria-label="연차 관리 연도"></select></div>',
 '<div id="leaveServiceStatus" class="leave-service-status" role="status"></div>',
 '<div class="leave-settings"><label for="leaveEntitlement">해당 연도 총 연차 (일)</label><div class="leave-settings-line"><input id="leaveEntitlement" type="number" min="0" max="365" step="0.5" placeholder="예: 15" aria-label="총 연차 일수"><button type="button" id="leaveSaveEntitlement">총 연차 저장</button></div><small>연도별로 직접 설정하며, 이월·추가 발생분도 총 연차에 포함해 입력할 수 있어요.</small></div>',
 '<div class="leave-stats"><div><small>총 연차</small><strong id="leaveStatTotal">미설정</strong></div><div><small>사용 완료</small><strong id="leaveStatUsed">0일</strong></div><div><small>사용 예정</small><strong id="leaveStatPlanned">0일</strong></div><div><small>잔여 / 사용 가능</small><strong id="leaveStatRemaining">미설정</strong></div></div>',
 '<section class="leave-editor" aria-labelledby="leaveEditHeading"><h3 id="leaveEditHeading">연차 등록</h3>',
 '<form id="leaveEntryForm"><div class="leave-editor-grid"><label>시작일<input id="leaveStart" type="date" required></label><label id="leaveEndWrap">종료일<input id="leaveEnd" type="date" required></label><label>연차 종류<select id="leaveKind"><option value="full">연차 (1일)</option><option value="am">오전 반차 (0.5일)</option><option value="pm">오후 반차 (0.5일)</option></select></label></div>',
 '<label class="leave-note-label">메모 (선택)<input id="leaveNote" type="text" maxlength="300" spellcheck="false" placeholder="예: 개인 일정"></label>',
 '<div id="leaveDatePreview" class="leave-date-preview" role="status"></div><div class="leave-editor-actions"><button type="button" id="leaveEntryReset">새로 작성</button><button type="button" id="leaveEntryDelete" class="leave-danger" hidden>삭제</button><button type="submit" id="leaveEntrySave" class="leave-primary">연차 등록</button></div></form></section>',
 '<section class="leave-history"><div class="leave-history-head"><h3>연차 사용 내역 <small id="leaveCount"></small></h3><button id="leaveCopyHistory" type="button">내역 복사</button></div><div id="leaveHistoryList"></div></section>',
 '<p class="leave-holiday-guide">연속 연차는 주말·등록된 공휴일을 제외해 계산해요. 오전/오후 반차는 하루에 각각 0.5일이며, 다른 연도로 넘어가는 기간은 연도별로 따로 등록해 주세요.</p>'
 ].join('');
 panel.appendChild(area);
 byId('leaveTabCalendar').onclick=function(){selectTab('calendar');};
 byId('leaveTabManager').onclick=function(){selectTab('manager');};
 byId('leaveYearSelect').onchange=function(e){selectedYear=Number(e.target.value);resetEntryForm();selectTab('calendar');render();};
 byId('leaveSaveEntitlement').onclick=saveAnnual;
 byId('leaveEntryForm').onsubmit=saveEntry;
 byId('leaveEntryReset').onclick=resetEntryForm;
 byId('leaveEntryDelete').onclick=deleteEntry;
 byId('leaveCopyHistory').onclick=copyHistory;
 byId('leaveKind').onchange=function(){syncHalf();preview();};
 byId('leaveStart').onchange=function(){syncHalf();preview();};
 byId('leaveEnd').onchange=preview;
 byId('leaveHistoryList').addEventListener('click',function(e){var b=e.target.closest('[data-leave-edit]');if(b)openEdit(b.getAttribute('data-leave-edit'));});
 var cal=byId('calendar');
 if(cal)cal.addEventListener('click',function(e){var chip=e.target.closest('.leave-chip');if(chip){e.preventDefault();e.stopPropagation();openEdit(chip.getAttribute('data-leave-id'));}},true);
 resetEntryForm();render();
}
function selectTab(which){
 var isCalendar=which==='calendar';
 // Keep visual, accessibility and state attributes in sync. Inline styling avoids stale/overriding stylesheets.
 [[byId('leaveTabCalendar'),isCalendar],[byId('leaveTabManager'),!isCalendar]].forEach(function(pair){
   var b=pair[0],on=pair[1];
   b.classList.toggle('active',on);
   b.setAttribute('aria-selected',String(on));
   b.tabIndex=on?0:-1;
   b.style.setProperty('background-color',on?'#fff':'#e9edf1','important');
   b.style.setProperty('color',on?'#20252a':'#87919d','important');
   b.style.setProperty('box-shadow',on?'0 1px 5px rgba(24,32,40,.12)':'none','important');
   b.style.setProperty('border-color',on?'#dfe4e9':'transparent','important');
 });
 byId('leaveCalendarTab').setAttribute('aria-expanded',String(isCalendar));
 byId('leaveCalendarTab').closest('.calendar-panel').querySelector('.month-nav').hidden=!isCalendar;
 byId('leaveCalendarTab').closest('.calendar-panel').querySelector('.section-head h2').textContent=isCalendar?'업무 캘린더':'연차 관리';
 byId('leaveCalendarTab').closest('.calendar-panel').querySelector('.section-head small').textContent=isCalendar?'SCHEDULE':'ANNUAL LEAVE';
 byId('leaveCalendarTab').closest('.calendar-panel').querySelector('.section-head').classList.toggle('leave-mode',!isCalendar);
 byId('leaveCalendarTab').closest('.calendar-panel').querySelector('.cal-help')?.setAttribute('aria-hidden',String(!isCalendar));
 byId('leaveCalendarTab').closest('.calendar-panel').querySelector('#leaveCalendarTab').hidden=!isCalendar;
 byId('leaveManagerTab').hidden=isCalendar;
 if(!isCalendar)render();
}
function resetEntryForm(){
 editId=null;var date=todayKey(),yr=String(selectedYear);
 if(date.slice(0,4)!==yr)date=yr+'-01-02';
 byId('leaveStart').value=date;byId('leaveEnd').value=date;
 byId('leaveKind').value='full';byId('leaveNote').value='';
 byId('leaveEditHeading').textContent='연차 등록';byId('leaveEntrySave').textContent='연차 등록';byId('leaveEntryDelete').hidden=true;
 syncHalf();preview();
}
function syncHalf(){
 var half=byId('leaveKind').value!=='full';
 if(half)byId('leaveEnd').value=byId('leaveStart').value;
 byId('leaveEnd').disabled=half;byId('leaveEndWrap').classList.toggle('leave-disabled',half);
}
function preview(){
 var st=byId('leaveStart').value,ed=byId('leaveEnd').disabled?st:byId('leaveEnd').value,kind=byId('leaveKind').value;
 var el=byId('leaveDatePreview');
 if(!st||!ed||ed<st){el.textContent='시작일·종료일을 확인해 주세요.';return;}
 if(st.slice(0,4)!==ed.slice(0,4)){el.textContent='다른 연도로 이어지는 연차는 연도별로 따로 등록해 주세요.';return;}
 var d={start_date:st,end_date:ed,leave_type:kind};el.textContent=usable(d)?'차감 예정: '+units(d)+'일 (주말·공휴일 제외)':'차감할 근무일이 없어요. 날짜를 확인해 주세요.';
}
function renderYearSelect(){
 var ys=new Set();
 for(var y=new Date().getFullYear()-8;y<=new Date().getFullYear()+5;y++)ys.add(y);
 annual.forEach(function(x){ys.add(+x.year);});entries.forEach(function(x){ys.add(+x.start_date.slice(0,4));});ys.add(+selectedYear);
 var opts=[...ys].sort(function(a,b){return b-a;});
 byId('leaveYearSelect').innerHTML=opts.map(function(y){return '<option value="'+y+'">'+y+'년</option>';}).join('');
 byId('leaveYearSelect').value=String(selectedYear);
}
function render(){
 if(!byId('leaveManagerTab'))return;
 renderYearSelect();
 var total=yearTotal(selectedYear),s=sums(selectedYear),remaining=total===null?null:total-s.used-s.planned;
 byId('leaveEntitlement').value=total===null?'':String(total);
 byId('leaveStatTotal').textContent=total===null?'미설정':total+'일';
 byId('leaveStatUsed').textContent=s.used+'일';byId('leaveStatPlanned').textContent=s.planned+'일';
 byId('leaveStatRemaining').textContent=remaining===null?'미설정':remaining+'일';
 byId('leaveStatRemaining').classList.toggle('leave-overdrawn',remaining!==null&&remaining<0);
 byId('leaveServiceStatus').textContent=loadError?loadError:!ready?'연차 데이터 불러오는 중…':'연차는 개인별로 저장되며 업무 캘린더와 자동 연동돼요.';
 byId('leaveServiceStatus').classList.toggle('leave-error',!!loadError);
 ['leaveSaveEntitlement','leaveEntrySave','leaveEntryDelete'].forEach(function(id){byId(id).disabled=!ready||saving;});
 var list=byYear(selectedYear).slice().sort(function(a,b){return b.start_date.localeCompare(a.start_date)||b.created_at.localeCompare(a.created_at);});
 byId('leaveCount').textContent=''+list.length+'건';
 byId('leaveHistoryList').innerHTML=list.length?list.map(function(e){
   var amount=units(e),future=datesOf(e).every(function(k){return k>todayKey();});
   var period=e.start_date===e.end_date?e.start_date:e.start_date+' ~ '+e.end_date;
   return '<div class="leave-history-row"><div class="leave-history-info"><strong>'+escapeHtml(period)+'</strong><span class="leave-kind '+(e.leave_type==='full'?'leave-full':'leave-half')+'">'+label(e.leave_type)+'</span><small>'+(future?'사용 예정':datesOf(e).every(function(k){return k<=todayKey();})?'사용 완료':'사용·예정')+(e.note?' · '+escapeHtml(e.note):'')+'</small></div><b>−'+amount+'일</b><button type="button" data-leave-edit="'+escapeHtml(e.id)+'">수정</button></div>';
 }).join(''):'<p class="empty">이 연도에는 등록한 연차가 없어요.</p>';
 if(!ready)byId('leaveHistoryList').innerHTML='<p class="empty">연차 관리 SQL을 적용하면 이곳에서 내역을 확인할 수 있어요.</p>';
}
function refresh(){
 render();if(typeof drawCalendar==='function')drawCalendar();if(typeof drawEventList==='function'&&typeof selected!=='undefined'&&selected)drawEventList();
}
function reset(){
 loadToken++;identity=null;entries=[];annual=[];ready=false;loadError='';editId=null;saving=false;
 if(byId('leaveManagerTab')){resetEntryForm();render();}
}
async function load(user){
 var token=++loadToken;identity=user||null;entries=[];annual=[];ready=false;loadError='';render();
 if(!user)return;
 try{
  var all=await Promise.all([
    db.from('dashboard_leave_years').select('*').eq('owner_id',user.id),
    db.from('dashboard_leave_entries').select('*').eq('owner_id',user.id).order('start_date',{ascending:false})
  ]);
  if(token!==loadToken||identity?.id!==user.id)return;
  var failure=all.find(function(x){return x.error;});if(failure)throw failure.error;
  annual=all[0].data||[];entries=all[1].data||[];ready=true;
 }catch(e){
  if(token!==loadToken)return;
  ready=false;loadError='연차 관리 테이블이 아직 준비되지 않았어요. Supabase SQL Editor에서 database/2026-11-02-annual-leave.sql을 실행해 주세요. ('+(e.message||'불러오기 실패')+')';
 }finally{if(token===loadToken)refresh();}
}
function calendarItems(key){
 if(!ready)return [];
 return entries.filter(function(e){return datesOf(e).includes(key);}).map(function(e){
  return {id:e.id,text:label(e.leave_type),leave:true,bg:tone(e.leave_type),start:key,end:key};
 });
}
function eventRows(key){
 var list=calendarItems(key);if(!list.length)return '';
 return list.map(function(e){return '<div class="event-row leave-event-row"><i style="background:'+e.bg+'"></i><span>'+escapeHtml(e.text)+'<small class="event-range-label">연차 관리에서 수정·삭제 가능</small></span><button type="button" onclick="JeiLeave.openEdit(\''+escapeHtml(e.id)+'\')">수정</button></div>';}).join('');
}
function openEdit(id){
 var e=entries.find(function(x){return x.id===id;});if(!e||!ready)return;
 selectedYear=Number(e.start_date.slice(0,4));var eventModal=byId('eventModal');if(eventModal)eventModal.classList.remove('show');selectTab('manager');
 editId=id;render();
 byId('leaveStart').value=e.start_date;byId('leaveEnd').value=e.end_date;
 byId('leaveKind').value=e.leave_type;byId('leaveNote').value=e.note||'';
 byId('leaveEditHeading').textContent='연차 수정';byId('leaveEntrySave').textContent='변경사항 저장';byId('leaveEntryDelete').hidden=false;
 syncHalf();preview();
 byId('leaveEntryForm').scrollIntoView({behavior:'smooth',block:'nearest'});
}
async function saveAnnual(){
 if(!isReady()||saving)return;
 var value=Number(byId('leaveEntitlement').value);
 if(byId('leaveEntitlement').value.trim()===''||!Number.isFinite(value)||value<0||value>365||value*2%1!==0){alert('연차 총량을 0.5일 단위로 입력해 주세요.');return;}
 saving=true;render();
 try{
  var payload={owner_id:identity.id,year:selectedYear,total_days:value,updated_at:new Date().toISOString()};
  var res=await db.from('dashboard_leave_years').upsert(payload,{onConflict:'owner_id,year'}).select().single();
  if(res.error)throw res.error;
  annual=annual.filter(function(x){return +x.year!==selectedYear;});annual.push(res.data);
 }catch(err){alert('총 연차 저장 실패: '+err.message);}
 finally{saving=false;render();}
}
function conflicts(candidate){
 var nextDates=datesOf(candidate);
 return entries.some(function(e){
  if(e.id===editId)return false;
  var overlapping=datesOf(e).some(function(x){return nextDates.includes(x);});
  if(!overlapping)return false;
  return e.leave_type==='full'||candidate.leave_type==='full'||e.leave_type===candidate.leave_type;
 });
}
async function saveEntry(ev){
 ev.preventDefault();if(!isReady()||saving)return;
 var start=byId('leaveStart').value,kind=byId('leaveKind').value,end=kind==='full'?byId('leaveEnd').value:start,note=byId('leaveNote').value.trim();
 var candidate={start_date:start,end_date:end,leave_type:kind,note:note};
 if(!start||!end||end<start||start.slice(0,4)!==end.slice(0,4)){alert('날짜를 확인해 주세요. 다른 연도에 걸친 연차는 따로 등록해야 해요.');return;}
 if(!usable(candidate)){alert('차감할 근무일이 없어요. 연차·반차 날짜를 확인해 주세요.');return;}
 var yr=Number(start.slice(0,4));
 if(yearTotal(yr)===null){alert(yr+'년 총 연차를 먼저 설정해 주세요.');return;}
 if(conflicts(candidate)){alert('이미 같은 날 등록된 연차와 겹쳐요. 오전 반차 + 오후 반차 조합만 중복 등록할 수 있어요.');return;}
 var newAmt=units(candidate);
 var old=entries.find(function(x){return x.id===editId;});
 var otherUsed=byYear(yr).reduce(function(sum,e){return sum+(old&&e.id===old.id?0:units(e));},0);
 if(otherUsed+newAmt>yearTotal(yr)&&!confirm('총 연차보다 '+(otherUsed+newAmt-yearTotal(yr))+'일 초과해요. 그래도 등록할까요?'))return;
 saving=true;render();
 try{
  var payload={start_date:start,end_date:end,leave_type:kind,note:note,updated_at:new Date().toISOString()};
  var res;
  if(editId){res=await db.from('dashboard_leave_entries').update(payload).eq('owner_id',identity.id).eq('id',editId).select().single();}
  else{payload.owner_id=identity.id;res=await db.from('dashboard_leave_entries').insert(payload).select().single();}
  if(res.error)throw res.error;
  entries=entries.filter(function(x){return x.id!==res.data.id;});entries.push(res.data);
  selectedYear=yr;resetEntryForm();
 }catch(err){alert('연차 저장 실패: '+err.message);}
 finally{saving=false;refresh();}
}
async function deleteEntry(){
 if(!isReady()||saving||!editId)return;
 var target=entries.find(function(e){return e.id===editId;});if(!target)return;
 if(!confirm(target.start_date+' '+label(target.leave_type)+' 기록을 삭제할까요? 잔여 연차도 자동으로 복구됩니다.'))return;
 saving=true;render();
 try{
  var res=await db.from('dashboard_leave_entries').delete().eq('owner_id',identity.id).eq('id',editId);
  if(res.error)throw res.error;
  entries=entries.filter(function(e){return e.id!==editId;});resetEntryForm();
 }catch(err){alert('연차 삭제 실패: '+err.message);}
 finally{saving=false;refresh();}
}
async function copyHistory(){
 var list=byYear(selectedYear).slice().sort(function(a,b){return a.start_date.localeCompare(b.start_date);});
 if(!list.length){alert('복사할 연차 내역이 없어요.');return;}
 var text=selectedYear+'년 연차 사용 내역\n'+list.map(function(e){return '- '+e.start_date+(e.start_date===e.end_date?'':' ~ '+e.end_date)+' | '+label(e.leave_type)+' | '+units(e)+'일'+(e.note?' | '+e.note:'');}).join('\n');
 try{
  if(navigator.clipboard&&navigator.clipboard.writeText)await navigator.clipboard.writeText(text);
  else{var ta=document.createElement('textarea');ta.value=text;document.body.appendChild(ta);ta.select();if(!document.execCommand('copy'))throw Error('복사 실패');ta.remove();}
  alert('연차 사용 내역을 복사했어요.');
 }catch(e){alert('복사 권한을 허용한 뒤 다시 시도해 주세요.');}
}
install();
window.JeiLeave={load:load,reset:reset,calendarItems:calendarItems,eventRows:eventRows,openEdit:openEdit,go:function(){selectTab('manager');},_test:{datesOf:datesOf,isWorkday:isWorkday,units:units}};
})();