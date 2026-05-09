///| Local-first runtime — filesystem abstraction, session cache, and indexing.
/// No external storage dependencies (OPFS, sqlite, duckdb).
/// Pure in-memory implementation with trait boundaries for future swap-in.

///|
/// StorageBackend — abstract key-value storage interface. ///|
/// Implementations: MemoryStorage (in-memory), future: OPFS, sqlite, etc.
pub trait StorageBackend {
  read(Self, String) -> String?
  write(Self, String, String) -> Unit
  delete(Self, String) -> Unit
  list(Self) -> Array[String]
}

///|
/// MemoryStorage — in-memory implementation of StorageBackend.
pub struct MemoryStorage {
  mut entries : Array[(String, String)]
}

///|
pub fn MemoryStorage::create() -> MemoryStorage {
  { entries: [] }
}

///|
impl StorageBackend for MemoryStorage with read(self, key : String) -> String? {
  for entry in self.entries {
    if entry.0 == key {
      return Some(entry.1)
    }
  }
  None
}

///|
impl StorageBackend for MemoryStorage with write(
  self,
  key : String,
  value : String,
) -> Unit {
  let new_entries : Array[(String, String)] = []
  for entry in self.entries {
    if entry.0 != key {
      new_entries.push(entry)
    }
  }
  new_entries.push((key, value))
  self.entries = new_entries
}

///|
impl StorageBackend for MemoryStorage with delete(self, key : String) -> Unit {
  let new_entries : Array[(String, String)] = []
  for entry in self.entries {
    if entry.0 != key {
      new_entries.push(entry)
    }
  }
  self.entries = new_entries
}

///|
impl StorageBackend for MemoryStorage with list(self) -> Array[String] {
  let keys : Array[String] = []
  for entry in self.entries {
    keys.push(entry.0)
  }
  keys
}

///| AgentEvent JSON serialization — deterministic, manual (no external deps). ///|

///|
fn event_to_json(event : AgentEvent) -> String {
  match event {
    UserMessage(content) =>
      "{\"type\":\"UserMessage\",\"content\":\"" + escape_json(content) + "\"}"
    AssistantMessage(content) =>
      "{\"type\":\"AssistantMessage\",\"content\":\"" +
      escape_json(content) +
      "\"}"
    ToolCall(req) =>
      "{\"type\":\"ToolCall\",\"tool_name\":\"" +
      escape_json(req.tool_name) +
      "\",\"input\":\"" +
      escape_json(req.input) +
      "\",\"call_id\":\"" +
      escape_json(req.call_id) +
      "\"}"
    ToolResult(res) =>
      "{\"type\":\"ToolResult\",\"call_id\":\"" +
      escape_json(res.call_id) +
      "\",\"output\":\"" +
      escape_json(res.output) +
      "\",\"success\":" +
      (if res.success { "true" } else { "false" }) +
      "}"
    Transition(from, to) =>
      "{\"type\":\"Transition\",\"from\":\"" +
      escape_json(from) +
      "\",\"to\":\"" +
      escape_json(to) +
      "\"}"
    Reason(msg) =>
      "{\"type\":\"Reason\",\"message\":\"" + escape_json(msg) + "\"}"
    StreamChunk(delta) =>
      "{\"type\":\"StreamChunk\",\"delta\":\"" + escape_json(delta) + "\"}"
    SessionStarted(sid) =>
      "{\"type\":\"SessionStarted\",\"session_id\":\"" +
      escape_json(sid) +
      "\"}"
    SessionEnded(sid) =>
      "{\"type\":\"SessionEnded\",\"session_id\":\"" + escape_json(sid) + "\"}"
  }
}

///| AgentEvent JSON deserialization — minimal, handles only the format we produce. ///|

///|
/// Find the first index of pattern in s. Returns None if not found.
fn str_index_of(s : String, pattern : String) -> Int? {
  let len = s.length()
  let pat_len = pattern.length()
  if pat_len == 0 {
    return Some(0)
  }
  if pat_len > len {
    return None
  }
  let mut i = 0
  while i <= len - pat_len {
    let mut found = true
    let mut j = 0
    while j < pat_len {
      if s[i + j] != pattern[j] {
        found = false
        break
      }
      j = j + 1
    }
    if found {
      return Some(i)
    }
    i = i + 1
  }
  None
}

///|
/// Extract the value of a string field from a JSON object string.
/// Searches for "key":"value" pattern (with JSON-escaped value).
fn json_extract_string(json : String, key : String) -> String? {
  let pattern = "\"" + key + "\":\""
  let start = str_index_of(json, pattern)
  match start {
    Some(pos) => {
      let val_start = pos + pattern.length()
      let rest = json[val_start:]
      let mut i = 0
      let mut buf = ""
      let rest_len = rest.length()
      while i < rest_len {
        let ch = rest[i]
        if ch == '"' {
          return Some(buf)
        }
        if ch == '\\' && i + 1 < rest_len {
          let next = rest[i + 1]
          match next {
            '"' => {
              buf = buf + "\""
              i = i + 2
              continue
            }
            '\\' => {
              buf = buf + "\\"
              i = i + 2
              continue
            }
            'n' => {
              buf = buf + "\n"
              i = i + 2
              continue
            }
            'r' => {
              buf = buf + "\r"
              i = i + 2
              continue
            }
            't' => {
              buf = buf + "\t"
              i = i + 2
              continue
            }
            _ => {
              buf = buf + rest[i + 1:i + 2].to_owned()
              i = i + 2
              continue
            }
          }
        }
        buf = buf + rest[i:i + 1].to_owned()
        i = i + 1
      }
      None
    }
    None => None
  }
}

///|
/// Extract the value of a bool field from a JSON object string.
fn json_extract_bool(json : String, key : String) -> Bool? {
  let pattern_true = "\"" + key + "\":true"
  match str_index_of(json, pattern_true) {
    Some(_) => Some(true)
    None =>
      match str_index_of(json, "\"" + key + "\":false") {
        Some(_) => Some(false)
        None => None
      }
  }
}

///|
/// Extract the array value for a given key from JSON.
fn json_extract_array(json : String, key : String) -> String? {
  let pattern = "\"" + key + "\":["
  match str_index_of(json, pattern) {
    Some(pos) => {
      let from = pos + pattern.length()
      let slice = json[from:]
      let mut depth = 1
      let mut i = 0
      let slice_len = slice.length()
      while i < slice_len {
        if slice[i] == '[' {
          depth = depth + 1
        } else if slice[i] == ']' {
          if depth == 1 {
            return Some(slice[0:i].to_owned())
          } else {
            depth = depth - 1
          }
        }
        i = i + 1
      }
      None
    }
    None => None
  }
}

///|
/// Split a JSON array of event objects into individual event strings.
fn split_events_array(events_json : String) -> Array[String] {
  let events : Array[String] = []
  let mut i = 0
  let mut depth = 0
  let mut start = -1
  let json_len = events_json.length()
  while i < json_len {
    let ch = events_json[i]
    if ch == '{' {
      if depth == 0 {
        start = i
      }
      depth = depth + 1
    } else if ch == '}' {
      if depth == 1 {
        let event_str = events_json[start:i + 1].to_owned()
        events.push(event_str)
        start = -1
      }
      depth = depth - 1
    }
    i = i + 1
  }
  events
}

///|
fn event_from_json(json : String) -> AgentEvent? {
  let typ = json_extract_string(json, "type")
  match typ {
    Some("UserMessage") => {
      let content = json_extract_string(json, "content")
      match content {
        Some(c) => Some(UserMessage(c))
        None => None
      }
    }
    Some("AssistantMessage") => {
      let content = json_extract_string(json, "content")
      match content {
        Some(c) => Some(AssistantMessage(c))
        None => None
      }
    }
    Some("ToolCall") => {
      let tool_name = json_extract_string(json, "tool_name")
      let input = json_extract_string(json, "input")
      let call_id = json_extract_string(json, "call_id")
      match (tool_name, input, call_id) {
        (Some(tn), Some(inp), Some(cid)) =>
          Some(ToolCall({ tool_name: tn, input: inp, call_id: cid }))
        _ => None
      }
    }
    Some("ToolResult") => {
      let call_id = json_extract_string(json, "call_id")
      let output = json_extract_string(json, "output")
      let success = json_extract_bool(json, "success")
      match (call_id, output, success) {
        (Some(cid), Some(out), Some(succ)) =>
          Some(ToolResult({ call_id: cid, output: out, success: succ }))
        _ => None
      }
    }
    Some("Transition") => {
      let from = json_extract_string(json, "from")
      let to = json_extract_string(json, "to")
      match (from, to) {
        (Some(f), Some(t)) => Some(Transition(f, t))
        _ => None
      }
    }
    Some("Reason") => {
      let message = json_extract_string(json, "message")
      match message {
        Some(m) => Some(Reason(m))
        None => None
      }
    }
    Some("StreamChunk") => {
      let delta = json_extract_string(json, "delta")
      match delta {
        Some(d) => Some(StreamChunk(d))
        None => None
      }
    }
    Some("SessionStarted") => {
      let session_id = json_extract_string(json, "session_id")
      match session_id {
        Some(sid) => Some(SessionStarted(sid))
        None => None
      }
    }
    Some("SessionEnded") => {
      let session_id = json_extract_string(json, "session_id")
      match session_id {
        Some(sid) => Some(SessionEnded(sid))
        None => None
      }
    }
    _ => None
  }
}

///|
fn events_array_to_json(events : Array[AgentEvent]) -> String {
  let mut buf = "["
  let mut first = true
  for e in events {
    if first {
      buf = buf + event_to_json(e)
      first = false
    } else {
      buf = buf + "," + event_to_json(e)
    }
  }
  buf + "]"
}

///|
fn parse_events_array(events_json : String) -> Array[AgentEvent] {
  let event_strs = split_events_array(events_json)
  let events : Array[AgentEvent] = []
  for s in event_strs {
    match event_from_json(s) {
      Some(e) => events.push(e)
      None => ()
    }
  }
  events
}

///| Session serialization for cache — id + events (state is reconstructed via replay). ///|

///|
/// Serialize a Session to a deterministic JSON string for caching.
pub fn session_to_json(session : Session) -> String {
  "{\"id\":\"" +
  escape_json(session.id) +
  "\",\"events\":" +
  events_array_to_json(session.event_log) +
  "}"
}

///|
/// Deserialize a Session from a cache JSON string.
/// Reconstructs state via Session::replay (deterministic).
pub fn session_from_json(json : String) -> Session? {
  let id = json_extract_string(json, "id")
  let events_json = json_extract_array(json, "events")
  match (id, events_json) {
    (Some(sid), Some(ejson)) => {
      let events = parse_events_array(ejson)
      Some(Session::replay(sid, events))
    }
    _ => None
  }
}

///| SessionCache — caches Session objects via a StorageBackend. ///|

///|
/// SessionCache wraps a StorageBackend to persist and restore Session objects.
pub struct SessionCache {
  backend : MemoryStorage
}

///|
pub fn SessionCache::create(backend : MemoryStorage) -> SessionCache {
  { backend, }
}

///|
pub fn SessionCache::cache(self : SessionCache, session : Session) -> Unit {
  self.backend.write(session.id, session_to_json(session))
}

///|
pub fn SessionCache::load(self : SessionCache, id : SessionId) -> Session? {
  match self.backend.read(id) {
    Some(json) => session_from_json(json)
    None => None
  }
}

///|
pub fn SessionCache::remove(self : SessionCache, id : SessionId) -> Unit {
  self.backend.delete(id)
}

///|
pub fn SessionCache::list_ids(self : SessionCache) -> Array[SessionId] {
  self.backend.list()
}

///|
pub fn SessionCache::contains(self : SessionCache, id : SessionId) -> Bool {
  match self.backend.read(id) {
    Some(_) => true
    None => false
  }
}

///| SessionIndex — manages a list of session IDs for indexing. ///|

///|
/// SessionIndex maintains an index of session IDs using a StorageBackend.
pub struct SessionIndex {
  backend : MemoryStorage
}

///|
pub fn SessionIndex::create(backend : MemoryStorage) -> SessionIndex {
  { backend, }
}

///|
pub fn SessionIndex::list(self : SessionIndex) -> Array[SessionId] {
  self.backend.list()
}

///|
pub fn SessionIndex::add(self : SessionIndex, id : SessionId) -> Unit {
  self.backend.write(id, id)
}

///|
pub fn SessionIndex::remove(self : SessionIndex, id : SessionId) -> Unit {
  self.backend.delete(id)
}

///|
pub fn SessionIndex::contains(self : SessionIndex, id : SessionId) -> Bool {
  match self.backend.read(id) {
    Some(_) => true
    None => false
  }
}

///|
pub fn SessionIndex::count(self : SessionIndex) -> Int {
  self.backend.list().length()
}
