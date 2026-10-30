/* Nickname -> internal (non-deliverable) Supabase Auth email. Not a password or secret. */
window.JeiAuth={
  isConfigured: c=>Boolean(c && /^https:\/\/[^/]+\.supabase\.co\/?$/.test(c.url||'') && /^(sb_publishable_|eyJ)/.test(c.publishableKey||'')),
  async emailForNickname(nickname){
    const normalized=String(nickname||'').trim().normalize('NFKC').toLocaleLowerCase('ko-KR');
    if(normalized.length<1 || normalized.length>30)throw new Error('닉네임은 1~30자로 입력해주세요.');
    const bytes=new TextEncoder().encode(normalized);
    const digest=await crypto.subtle.digest('SHA-256',bytes);
    const hex=Array.from(new Uint8Array(digest),b=>b.toString(16).padStart(2,'0')).join('');
    return 'u'+hex.slice(0,40)+'@accounts.jei-dashboard.invalid';
  }
};
