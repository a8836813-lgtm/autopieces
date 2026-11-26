import { useEffect, useRef, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { api, photoUrl } from '../api';
import { useAuth } from '../auth';
import { Monogram } from '../art';
import { Empty, ErrorBox } from '../ui';

function useSelf(user) {
  if (user.role === 'client') return { side: 'client', params: { as: 'client', client_ref: user.email.toLowerCase() } };
  const id = String(user.role === 'shop' ? user.shop_id : user.mechanic_id);
  return { side: 'peer', params: { as: 'peer', peer_kind: user.role, peer_id: id }, kind: user.role, id };
}

const keyOf = (t) => `${t.client_ref}|${t.peer_kind}|${t.peer_id}`;

function Conversation({ thread, self, user }) {
  const [msgs, setMsgs] = useState([]);
  const [body, setBody] = useState('');
  const [file, setFile] = useState(null);
  const [error, setError] = useState(null);
  const last = useRef(0);
  const box = useRef(null);

  const query = {
    client_ref: thread.client_ref,
    peer_kind: thread.peer_kind,
    peer_id: thread.peer_id,
    reader: self.side,
  };

  async function poll(reset) {
    try {
      const r = await api.get('chat/messages.php', { ...query, after_id: reset ? 0 : last.current });
      if (r.messages.length) {
        last.current = r.messages[r.messages.length - 1].id;
        setMsgs((m) => (reset ? r.messages : [...m, ...r.messages.filter((x) => !m.some((y) => y.id === x.id))]));
      } else if (reset) {
        setMsgs([]);
      }
    } catch (e) {
      setError(e);
    }
  }

  useEffect(() => {
    last.current = 0;
    poll(true);
    const id = setInterval(() => poll(false), 3000);
    return () => clearInterval(id);
    // eslint-disable-next-line
  }, [keyOf(thread)]);

  useEffect(() => {
    if (box.current) box.current.scrollTop = box.current.scrollHeight;
  }, [msgs]);

  async function send(e) {
    e.preventDefault();
    if (!body.trim() && !file) return;
    try {
      await api.form(
        'chat/send.php',
        {
          client_ref: thread.client_ref,
          client_name: thread.client_name || (self.side === 'client' ? user.name : ''),
          peer_kind: thread.peer_kind,
          peer_id: thread.peer_id,
          peer_name: thread.peer_name || '',
          sender: self.side,
          body: body.trim(),
        },
        file ? [['photo', file]] : []
      );
      setBody('');
      setFile(null);
      setError(null);
      poll(false);
    } catch (err) {
      setError(err);
    }
  }

  return (
    <div className="conv">
      <div className="msgs" ref={box}>
        {msgs.length === 0 && <Empty>Say hello 👋</Empty>}
        {msgs.map((m) => (
          <div key={m.id} className={`msg ${m.sender === self.side ? 'me' : ''}`}>
            {m.photo && <img src={photoUrl(m.photo)} alt="" />}
            {m.body}
            <div className="small" style={{ opacity: 0.7 }}>{m.created_at.slice(11, 16)}</div>
          </div>
        ))}
      </div>
      <ErrorBox error={error} />
      <form className="composer" onSubmit={send}>
        <input type="text" placeholder="Write a message" value={body} onChange={(e) => setBody(e.target.value)} />
        <label className="attach" title={file ? file.name : 'Attach a photo'} style={file ? { borderColor: 'var(--cobalt)' } : undefined}>
          {file ? '✔' : '📎'}
          <input type="file" accept="image/*" onChange={(e) => setFile(e.target.files[0] || null)} />
        </label>
        <button className="btn">Send</button>
      </form>
    </div>
  );
}

export default function Messages() {
  const { user } = useAuth();
  const self = useSelf(user);
  const [params] = useSearchParams();
  const [threads, setThreads] = useState([]);
  const [active, setActive] = useState(null);
  const [error, setError] = useState(null);

  const wanted =
    self.side === 'client' && params.get('kind') && params.get('id')
      ? {
          client_ref: user.email.toLowerCase(),
          client_name: user.name,
          peer_kind: params.get('kind'),
          peer_id: params.get('id'),
          peer_name: params.get('name') || '',
        }
      : null;

  async function load() {
    try {
      const r = await api.get('chat/inbox.php', self.params);
      setThreads(r.threads);
      setError(null);
    } catch (e) {
      setError(e);
    }
  }

  useEffect(() => {
    load();
    const id = setInterval(load, 5000);
    return () => clearInterval(id);
    // eslint-disable-next-line
  }, []);

  useEffect(() => {
    if (wanted) setActive(wanted);
    // eslint-disable-next-line
  }, [params.get('kind'), params.get('id')]);

  const list = [...threads];
  if (wanted && !list.some((t) => keyOf(t) === keyOf(wanted))) list.unshift({ ...wanted, last: null, unread: 0 });
  const current = active && (list.find((t) => keyOf(t) === keyOf(active)) || active);

  return (
    <>
      <h1>Messages</h1>
      <ErrorBox error={error} />
      <div className="chat">
        <div className="threads">
          {list.length === 0 && <Empty>No conversation yet.</Empty>}
          {list.map((t) => (
            <div key={keyOf(t)} className={`thread ${current && keyOf(current) === keyOf(t) ? 'on' : ''}`} onClick={() => setActive(t)}>
              <div className="item">
                <Monogram name={self.side === 'client' ? t.peer_name || t.peer_kind : t.client_name || t.client_ref} size={38} />
                <div className="grow">
                  <div className="row between">
                    <b>{self.side === 'client' ? t.peer_name || `${t.peer_kind} #${t.peer_id}` : t.client_name || t.client_ref}</b>
                    {t.unread > 0 && <span className="dot">{t.unread}</span>}
                  </div>
                  <div className="muted small">{t.last ? t.last.body || 'Photo' : 'New conversation'}</div>
                </div>
              </div>
            </div>
          ))}
        </div>
        {current ? <Conversation thread={current} self={self} user={user} /> : <div className="conv"><Empty>Choose a conversation.</Empty></div>}
      </div>
    </>
  );
}
