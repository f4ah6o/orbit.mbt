///| Deterministic replay — reconstruct session state from an event log.
/// Same events always produce the same state; no hidden mutable state.

///| Replay a full event log against a fresh session.
/// Starts from Idle, applies every event in order, returns final session.
pub fn Session::replay(id : SessionId, events : Array[AgentEvent]) -> Session {
  let mut session = Session::create(id)
  for event in events {
    session = session.apply(event)
  }
  session
}

///| Continue replay from an existing session (append new events).
pub fn Session::replay_from(
  self : Session,
  new_events : Array[AgentEvent]
) -> Session {
  let mut session = self
  for event in new_events {
    session = session.apply(event)
  }
  session
}
