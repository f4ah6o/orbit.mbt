///|
/// An available action in the hypermedia resource.
/// Represents a state transition the client can request.
pub struct Action {
  rel : String
  method : String
  href : String
} derive(Debug, Eq)

///|
/// A message entry in the resource projection — user or assistant.
pub struct MessageEntry {
  role : String
  content : String
} derive(Debug, Eq)

///|
/// A hypermedia link.
pub struct Link {
  rel : String
  href : String
} derive(Debug, Eq)

///|
/// A hypermedia resource projection of a Session.
/// This is the canonical representation consumed by UI layers.
pub struct Resource {
  state : String
  messages : Array[MessageEntry]
  available_actions : Array[Action]
  reasons : Array[String]
  links : Array[Link]
} derive(Debug, Eq)

///|
/// Map AgentState variant to a stable string label.
fn state_label(state : AgentState) -> String {
  match state {
    Idle => "idle"
    Running(_) => "running"
    WaitingTool(_, _) => "waiting_tool"
    Failed(_) => "failed"
  }
}

///|
/// Compute available actions from the current session state.
/// Each state exposes only the transitions that are legal.
pub fn available_actions(session : Session) -> Array[Action] {
  let id = session.id
  match session.current_state() {
    Idle =>
      [
        {
          rel: "start",
          method: "POST",
          href: "/session/" + id + "/actions/start",
        },
      ]
    Running(_) =>
      [
        {
          rel: "send_message",
          method: "POST",
          href: "/session/" + id + "/actions/message",
        },
        { rel: "end", method: "POST", href: "/session/" + id + "/actions/end" },
        {
          rel: "request_tool",
          method: "POST",
          href: "/session/" + id + "/actions/tool",
        },
      ]
    WaitingTool(_, _) =>
      [
        {
          rel: "respond_tool",
          method: "POST",
          href: "/session/" + id + "/actions/tool",
        },
        { rel: "end", method: "POST", href: "/session/" + id + "/actions/end" },
      ]
    Failed(_) => []
  }
}

///|
/// Extract messages (UserMessage, AssistantMessage) from the event log.
fn messages_projection(session : Session) -> Array[MessageEntry] {
  let messages : Array[MessageEntry] = []
  for event in session.event_log {
    match event {
      UserMessage(content) => messages.push({ role: "user", content })
      AssistantMessage(content) => messages.push({ role: "assistant", content })
      _ => ()
    }
  }
  messages
}

///|
/// Extract reasons (Reason events) from the event log.
pub fn reasons_projection(session : Session) -> Array[String] {
  let reasons : Array[String] = []
  for event in session.event_log {
    match event {
      Reason(msg) => reasons.push(msg)
      _ => ()
    }
  }
  reasons
}

///|
/// Compute the full hypermedia resource projection for a session.
pub fn project(session : Session) -> Resource {
  {
    state: state_label(session.current_state()),
    messages: messages_projection(session),
    available_actions: available_actions(session),
    reasons: reasons_projection(session),
    links: [{ rel: "self", href: "/session/" + session.id }],
  }
}

///| Manual JSON serialization — avoids external dependencies, deterministic ordering. ///|

///|
fn escape_json(s : String) -> String {
  let mut buf = ""
  for ch in s {
    match ch {
      '"' => buf = buf + "\\\""
      '\\' => buf = buf + "\\\\"
      '\n' => buf = buf + "\\n"
      '\r' => buf = buf + "\\r"
      '\t' => buf = buf + "\\t"
      _ => buf = buf + ch.to_string()
    }
  }
  buf
}

///|
fn Action::to_json(self : Action) -> String {
  "{\"rel\":\"" +
  escape_json(self.rel) +
  "\",\"method\":\"" +
  escape_json(self.method) +
  "\",\"href\":\"" +
  escape_json(self.href) +
  "\"}"
}

///|
fn MessageEntry::to_json(self : MessageEntry) -> String {
  "{\"role\":\"" +
  escape_json(self.role) +
  "\",\"content\":\"" +
  escape_json(self.content) +
  "\"}"
}

///|
fn Link::to_json(self : Link) -> String {
  "{\"rel\":\"" +
  escape_json(self.rel) +
  "\",\"href\":\"" +
  escape_json(self.href) +
  "\"}"
}

///|
fn actions_to_json(actions : Array[Action]) -> String {
  let mut buf = "["
  let mut first = true
  for a in actions {
    if first {
      buf = buf + a.to_json()
      first = false
    } else {
      buf = buf + "," + a.to_json()
    }
  }
  buf + "]"
}

///|
fn messages_to_json(messages : Array[MessageEntry]) -> String {
  let mut buf = "["
  let mut first = true
  for m in messages {
    if first {
      buf = buf + m.to_json()
      first = false
    } else {
      buf = buf + "," + m.to_json()
    }
  }
  buf + "]"
}

///|
fn strings_to_json(items : Array[String]) -> String {
  let mut buf = "["
  let mut first = true
  for s in items {
    if first {
      buf = buf + "\"" + escape_json(s) + "\""
      first = false
    } else {
      buf = buf + ",\"" + escape_json(s) + "\""
    }
  }
  buf + "]"
}

///|
fn links_to_json(links : Array[Link]) -> String {
  let mut buf = "["
  let mut first = true
  for l in links {
    if first {
      buf = buf + l.to_json()
      first = false
    } else {
      buf = buf + "," + l.to_json()
    }
  }
  buf + "]"
}

///|
/// Serialize a Resource to a deterministic JSON string (no trailing comma, sorted keys).
pub fn Resource::to_json_string(self : Resource) -> String {
  "{" +
  "\"state\":\"" +
  escape_json(self.state) +
  "\"," +
  "\"messages\":" +
  messages_to_json(self.messages) +
  "," +
  "\"available_actions\":" +
  actions_to_json(self.available_actions) +
  "," +
  "\"reasons\":" +
  strings_to_json(self.reasons) +
  "," +
  "\"links\":" +
  links_to_json(self.links) +
  "}"
}
