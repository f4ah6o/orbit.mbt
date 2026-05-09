///|
/// Session — core runtime unit.
/// Holds current state and an append-only event log.
/// All transitions go through `apply`, guaranteeing deterministic replay.
pub struct Session {
  id : SessionId
  state : AgentState
  event_log : Array[AgentEvent]
} derive(Debug)

///|
pub fn Session::create(id : SessionId) -> Session {
  { id, state: Idle, event_log: [] }
}

///|
/// Idle -> Running. Produces `SessionStarted`.
pub fn Session::start(self : Session) -> Result[Session, String] {
  match self.state {
    Idle => Ok(self.apply(SessionStarted(self.id)))
    Running(_) => Err("cannot start: already running")
    WaitingTool(_, _) => Err("cannot start: waiting for tool")
    Failed(_) => Err("cannot start: session failed")
  }
}

///|
/// Running | WaitingTool -> Idle. Produces `SessionEnded`.
pub fn Session::end(self : Session) -> Result[Session, String] {
  match self.state {
    Running(_) | WaitingTool(_, _) => Ok(self.apply(SessionEnded(self.id)))
    Idle => Err("cannot end: session is idle")
    Failed(_) => Err("cannot end: session failed")
  }
}

///|
/// Append a user message. Only valid when Running.
pub fn Session::send_user_message(
  self : Session,
  content : String,
) -> Result[Session, String] {
  match self.state {
    Running(_) => Ok(self.apply(UserMessage(content)))
    _ => Err("cannot send message: not running")
  }
}

///|
/// Append an assistant message. Only valid when Running.
pub fn Session::receive_assistant_message(
  self : Session,
  content : String,
) -> Result[Session, String] {
  match self.state {
    Running(_) => Ok(self.apply(AssistantMessage(content)))
    _ => Err("cannot receive message: not running")
  }
}

///|
/// Running -> WaitingTool. Produces `ToolCall`.
pub fn Session::request_tool(
  self : Session,
  req : ToolRequest,
) -> Result[Session, String] {
  match self.state {
    Running(_) => Ok(self.apply(ToolCall(req)))
    WaitingTool(_, _) => Err("cannot request tool: already waiting")
    _ => Err("cannot request tool: not running")
  }
}

///|
/// WaitingTool -> Running. Produces `ToolResult`.
pub fn Session::respond_tool(
  self : Session,
  res : ToolResponse,
) -> Result[Session, String] {
  match self.state {
    WaitingTool(_, _) => Ok(self.apply(ToolResult(res)))
    _ => Err("cannot respond tool: not waiting for tool")
  }
}

///|
/// Any state -> Failed. Produces `Reason`.
pub fn Session::fail(self : Session, reason : String) -> Session {
  self.apply(Reason(reason))
}

///|
/// Core transition: apply one event, return new immutable session.
pub fn Session::apply(self : Session, event : AgentEvent) -> Session {
  let new_state = apply_event(self.state, event)
  let new_log : Array[AgentEvent] = []
  for e in self.event_log {
    new_log.push(e)
  }
  new_log.push(event)
  { id: self.id, state: new_state, event_log: new_log }
}

///|
/// Pure state-transition function. No side effects; used by apply and replay.
fn apply_event(state : AgentState, event : AgentEvent) -> AgentState {
  match state {
    Idle =>
      match event {
        SessionStarted(sid) => Running({ session_id: sid })
        _ => state
      }
    Running(ctx) =>
      match event {
        SessionEnded(_) => Idle
        ToolCall(req) => WaitingTool(ctx, req)
        Reason(msg) => Failed(msg)
        _ => state
      }
    WaitingTool(ctx, _) =>
      match event {
        ToolResult(_) => Running(ctx)
        Reason(msg) => Failed(msg)
        _ => state
      }
    Failed(_) => state
  }
}

///|
pub fn Session::is_idle(self : Session) -> Bool {
  match self.state {
    Idle => true
    _ => false
  }
}

///|
pub fn Session::is_running(self : Session) -> Bool {
  match self.state {
    Running(_) => true
    _ => false
  }
}

///|
pub fn Session::is_waiting_tool(self : Session) -> Bool {
  match self.state {
    WaitingTool(_, _) => true
    _ => false
  }
}

///|
pub fn Session::is_failed(self : Session) -> Bool {
  match self.state {
    Failed(_) => true
    _ => false
  }
}

///|
pub fn Session::current_state(self : Session) -> AgentState {
  self.state
}

///|
pub fn Session::event_count(self : Session) -> Int {
  self.event_log.length()
}
