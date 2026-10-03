
const db=supabase.createClient('https://yqvjgalmjrydfygtozgo.supabase.co','sb_publishable_8K_sITH95Nkikw8-tdyDwQ_-JFzo94Z');
const $=s=>document.querySelector(s);
const esc=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const koCollator=new Intl.Collator('ko-KR',{numeric:true,sensitivity:'base'});
let games=[],isAdmin=false,editingId=null;

function sortGames(list){return [...list].sort((a,b)=>koCollator.compare((a.name||'').trim(),(b.name||'').trim()));}

async function init(){
  const {data:{session}}=await db.auth.getSession();
  isAdmin=!!session;
  $('#addToggle').style.display=isAdmin?'':'none';
  const {data,error}=await db.from('board_games').select('*');
  if(error)return alert(error.message);
  games=(data||[]).map(g=>({id:g.id,name:g.title,people:g.player_count,time:g.play_time,genre:g.genre,expansion:g.is_expansion,image:g.image_url}));
  draw();
}

function draw(){
  const q=$('#q').value.trim().toLowerCase(),genre=$('#genreFilter').value;
  const arr=sortGames(games.filter(g=>(!q||g.name.toLowerCase().includes(q))&&(!genre||g.genre===genre)));
  $('#resultCount').textContent=`총 ${arr.length}개 · 가나다순`;
  $('#list').innerHTML=arr.length?arr.map(g=>`<article class="game-card">${g.expansion?'<span class="expansion-badge">확장</span>':''}${isAdmin?`<div class="game-actions"><button class="edit-game" onclick="editGame('${g.id}')">수정</button><button class="delete-game" onclick="delGame('${g.id}')">×</button></div>`:''}<div class="game-image">${g.image?`<img src="${g.image}" alt="${esc(g.name)}">`:'<span class="no-image">NO IMAGE</span>'}</div><div class="game-info"><span class="game-genre">${esc(g.genre)}</span><h3 title="${esc(g.name)}">${esc(g.name)}</h3><div class="game-meta">👥 ${esc(g.people||'-')}<br>⏱ ${esc(g.time||'-')}</div></div></article>`).join(''):'<div class="empty-games">등록된 게임이 없어요.</div>';
}

function openAdd(){
  editingId=null;
  $('#gameForm').reset();
  $('#addBox').classList.add('show');
  $('#addBox').classList.remove('editing');
  $('#formTitle').textContent='새 게임 추가';
  $('#submitGame').textContent='책장에 추가';
  $('#imageNote').textContent='이미지는 Supabase Storage에 저장돼요.';
  $('#gameName').focus();
}
function closeForm(){
  editingId=null;
  $('#gameForm').reset();
  $('#addBox').classList.remove('show','editing');
  $('#formTitle').textContent='새 게임 추가';
  $('#submitGame').textContent='책장에 추가';
}

$('#q').oninput=draw;
$('#genreFilter').onchange=draw;
$('#addToggle').onclick=()=>{if($('#addBox').classList.contains('show'))closeForm();else openAdd();};
$('#cancelEdit').onclick=closeForm;

window.editGame=id=>{
  if(!isAdmin)return;
  const g=games.find(x=>x.id===id);
  if(!g)return;
  editingId=id;
  $('#gameName').value=g.name||'';
  $('#gamePeople').value=g.people||'';
  $('#gameTime').value=g.time||'';
  $('#gameGenre').value=g.genre||'';
  $('#gameExpansion').checked=!!g.expansion;
  $('#gameImage').value='';
  $('#addBox').classList.add('show','editing');
  $('#formTitle').textContent='게임 수정';
  $('#submitGame').textContent='수정 저장';
  $('#imageNote').textContent=g.image?'새 이미지를 선택하지 않으면 기존 이미지가 그대로 유지돼요.':'현재 등록된 이미지가 없어요. 필요하면 새 이미지를 선택하세요.';
  $('#addBox').scrollIntoView({behavior:'smooth',block:'start'});
  setTimeout(()=>$('#gameName').focus(),250);
};

window.delGame=async id=>{
  if(!isAdmin||!confirm('이 게임을 책장에서 삭제할까요?'))return;
  const {error}=await db.from('board_games').delete().eq('id',id);
  if(error)return alert(error.message);
  games=games.filter(g=>g.id!==id);
  if(editingId===id)closeForm();
  draw();
};

async function uploadImage(file){
  if(!file)return null;
  const path=`${crypto.randomUUID()}-${file.name.replace(/[^a-zA-Z0-9._-]/g,'_')}`;
  const up=await db.storage.from('board-game-images').upload(path,file);
  if(up.error)throw up.error;
  return db.storage.from('board-game-images').getPublicUrl(path).data.publicUrl;
}

$('#gameForm').addEventListener('submit',async e=>{
  e.preventDefault();
  if(!isAdmin)return;
  const name=$('#gameName').value.trim();
  if(!name)return;
  const file=$('#gameImage').files[0];
  let newImage=null;
  try{newImage=await uploadImage(file);}catch(err){return alert(err.message);}
  const row={
    title:name,
    player_count:$('#gamePeople').value.trim(),
    play_time:$('#gameTime').value.trim(),
    genre:$('#gameGenre').value,
    is_expansion:$('#gameExpansion').checked
  };
  if(newImage)row.image_url=newImage;

  if(editingId){
    const {data,error}=await db.from('board_games').update(row).eq('id',editingId).select().single();
    if(error)return alert(error.message);
    const idx=games.findIndex(g=>g.id===editingId);
    if(idx>-1)games[idx]={id:data.id,name:data.title,people:data.player_count,time:data.play_time,genre:data.genre,expansion:data.is_expansion,image:data.image_url};
  }else{
    if(!newImage)row.image_url='';
    const {data,error}=await db.from('board_games').insert(row).select().single();
    if(error)return alert(error.message);
    games.push({id:data.id,name:data.title,people:data.player_count,time:data.play_time,genre:data.genre,expansion:data.is_expansion,image:data.image_url});
  }
  closeForm();
  draw();
});

init();
