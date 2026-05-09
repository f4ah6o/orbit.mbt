///|
pub struct ReplayDebugger {
  id : String
  full_log : Array[@orbit.AgentEvent]
  cursor : Int
} derive(Debug)

///|
pub fn ReplayDebugger::new(
  id : String,
  log : Array[@orbit.AgentEvent],
) -> ReplayDebugger {
  { id, full_log: log, cursor: 0 }
}

///|
fn replay_until(
  id : String,
  log : Array[@orbit.AgentEvent],
  end : Int,
) -> @orbit.Session {
  let mut session = @orbit.Session::create(id)
  let mut i = 0
  while i < end {
    session = session.apply(log[i])
    i = i + 1
  }
  session
}

///|
pub fn ReplayDebugger::current_session(self : ReplayDebugger) -> @orbit.Session {
  replay_until(self.id, self.full_log, self.cursor)
}

///|
pub fn ReplayDebugger::step_forward(self : ReplayDebugger) -> ReplayDebugger {
  let n = self.full_log.length()
  let new_cursor = if self.cursor < n { self.cursor + 1 } else { self.cursor }
  { id: self.id, full_log: self.full_log, cursor: new_cursor }
}

///|
pub fn ReplayDebugger::step_back(self : ReplayDebugger) -> ReplayDebugger {
  let new_cursor = if self.cursor > 0 { self.cursor - 1 } else { 0 }
  { id: self.id, full_log: self.full_log, cursor: new_cursor }
}

///|
pub fn ReplayDebugger::seek(
  self : ReplayDebugger,
  index : Int,
) -> ReplayDebugger {
  let n = self.full_log.length()
  let clamped = if index < 0 { 0 } else if index > n { n } else { index }
  { id: self.id, full_log: self.full_log, cursor: clamped }
}

///|
pub fn ReplayDebugger::fork(
  self : ReplayDebugger,
  new_id : String,
  extra : Array[@orbit.AgentEvent],
) -> ReplayDebugger {
  let new_log : Array[@orbit.AgentEvent] = []
  let mut i = 0
  while i < self.cursor {
    new_log.push(self.full_log[i])
    i = i + 1
  }
  for e in extra {
    new_log.push(e)
  }
  { id: new_id, full_log: new_log, cursor: self.cursor }
}

///|
pub fn ReplayDebugger::last_event_description(self : ReplayDebugger) -> String {
  if self.cursor == 0 {
    return "(no event)"
  }
  let event = self.full_log[self.cursor - 1]
  match event {
    @orbit.AgentEvent::SessionStarted(sid) => "SessionStarted: " + sid
    @orbit.AgentEvent::UserMessage(s) => "UserMessage: " + s
    @orbit.AgentEvent::AssistantMessage(s) => "AssistantMessage: " + s
    @orbit.AgentEvent::ToolCall(req) => "ToolCall: " + req.tool_name
    @orbit.AgentEvent::ToolResult(res) => "ToolResult: " + res.output
    @orbit.AgentEvent::StreamChunk(s) => "StreamChunk: " + s
    @orbit.AgentEvent::Reason(s) => "Reason: " + s
    @orbit.AgentEvent::SessionEnded(sid) => "SessionEnded: " + sid
    @orbit.AgentEvent::Transition(a, b) => "Transition: " + a + " -> " + b
  }
}
