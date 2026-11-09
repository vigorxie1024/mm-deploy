// 常驻群聊 bot（服务器本机版，走 127.0.0.1:8000 避免公网抖动）：
// 真人发话 → 总工 2.2s + 大模型 5s 错开接话，形成三方讨论（VX 2026-11-07）
const BASE = 'http://127.0.0.1:8000';
const TOKEN = 'ck_7361590dc3cc68d41555f452599e1861105e';
const H = { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + TOKEN };
const seen = new Set();
let since = 0;

async function getState() {
  const r = await fetch(BASE + '/api/cell/state', { headers: H });
  const j = await r.json();
  return j.seq || 0;
}

async function speakAs(memberId, text) {
  const body = JSON.stringify({ member_id: memberId, text });
  try {
    const r = await fetch(BASE + '/api/cell/agents/speak', { method: 'POST', headers: H, body });
    const j = await r.json().catch(() => ({}));
    console.log(new Date().toISOString(), memberId, '->', r.status, JSON.stringify(j).slice(0, 120));
  } catch (e) { console.log(memberId, 'speak err', e.message); }
}

async function speakAsMember(memberId, text) {
  const body = JSON.stringify({ member_id: memberId, text });
  try {
    const r = await fetch(BASE + '/api/cell/ai/members/speak', { method: 'POST', headers: H, body });
    const j = await r.json().catch(() => ({}));
    console.log(new Date().toISOString(), memberId, '(own model) ->', r.status, JSON.stringify(j).slice(0, 140));
  } catch (e) { console.log(memberId, 'speakMember err', e.message); }
}

function handle(env) {
  if (!env || env.type !== 'chat.user') return;
  const from = env.from || '';
  if (from === 'zonggong' || from === 'llm' || from === 'aina' || from === 'system') return;
  const seq = env.seq;
  if (seen.has(seq)) return;
  seen.add(seq);
  const text = (env.payload && env.payload.text) || '';
  if (!text) return;
  // 错开延迟：aina（引擎自动）最先 → 总工 2.2s → 大模型 5s，形成多方讨论节奏
  setTimeout(() => speakAs('zonggong', text), 2200);
  setTimeout(() => speakAs('llm', text), 5000);
  if (/workbuddy|work.buddy/i.test(text)) {
    setTimeout(() => speakAsMember('workbuddy', text), 7500);
  }
  console.log(new Date().toISOString(), 'user said seq=' + seq + ' from=' + from + ':', text.slice(0, 50));
}

async function connect() {
  console.log('connecting since_seq=' + since);
  let resp;
  try {
    resp = await fetch(BASE + '/api/cell/events?since_seq=' + since, { headers: H });
  } catch (e) { console.log('connect err', e.message); setTimeout(connect, 3000); return; }
  if (!resp.ok || !resp.body) { console.log('connect bad', resp.status); setTimeout(connect, 3000); return; }
  const reader = resp.body.getReader();
  const dec = new TextDecoder();
  let buf = '';
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      buf += dec.decode(value, { stream: true });
      let idx;
      while ((idx = buf.indexOf('\n\n')) >= 0) {
        const chunk = buf.slice(0, idx); buf = buf.slice(idx + 2);
        for (const line of chunk.split('\n')) {
          if (line.startsWith('data: ')) {
            try { handle(JSON.parse(line.slice(6))); } catch (e) {}
          }
        }
      }
    }
  } catch (e) { console.log('stream err', e.message); }
  setTimeout(connect, 3000);
}

process.on('unhandledRejection', e => console.log('unhandledRejection:', e && e.message));
(async () => {
  while (true) {
    try { since = await getState(); break; }
    catch (e) { console.log('getState retry:', e.message); await new Promise(r => setTimeout(r, 3000)); }
  }
  console.log('zg-bot-server started, since_seq=' + since);
  connect();
})();
