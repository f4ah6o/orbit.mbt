///|
test "cursor starts at 0, current_session is Idle" {
  let log = demo_log()
  let dbg = ReplayDebugger::new("test", log)
  assert_eq(dbg.cursor, 0)
  let session = dbg.current_session()
  let state = session.current_state()
  assert_true(state is @orbit.AgentState::Idle)
}

///|
test "step_forward to 1, current_session is after first event" {
  let log = demo_log()
  let dbg = ReplayDebugger::new("test", log).step_forward()
  assert_eq(dbg.cursor, 1)
  let session = dbg.current_session()
  let state = session.current_state()
  assert_true(state is @orbit.AgentState::Running(_))
  assert_eq(session.event_count(), 1)
}

///|
test "step_back from 0 stays at 0" {
  let log = demo_log()
  let dbg = ReplayDebugger::new("test", log).step_back()
  assert_eq(dbg.cursor, 0)
  let state = dbg.current_session().current_state()
  assert_true(state is @orbit.AgentState::Idle)
}

///|
test "seek to last position gives same state as full replay" {
  let log = demo_log()
  let dbg = ReplayDebugger::new("test", log).seek(log.length())
  let session_a = dbg.current_session()
  let session_b = @orbit.Session::replay("test", log)
  assert_eq(session_a.event_count(), session_b.event_count())
  assert_eq(@orbit.project(session_a).state, @orbit.project(session_b).state)
}

///|
test "fork creates new debugger with extra events appended" {
  let log = demo_log()
  let dbg = ReplayDebugger::new("test", log).seek(3)
  let extra : Array[@orbit.AgentEvent] = [
    @orbit.AgentEvent::UserMessage("forked message"),
  ]
  let fork = dbg.fork("fork-1", extra)
  assert_eq(fork.id, "fork-1")
  assert_eq(fork.cursor, 3)
  assert_eq(fork.full_log.length(), 4)
  let step = fork.step_forward()
  let desc = step.last_event_description()
  assert_eq(desc, "UserMessage: forked message")
}

///|
test "replay is deterministic: same log always same state at each position" {
  let log = demo_log()
  let n = log.length()
  let dbg1 = ReplayDebugger::new("test", log)
  let dbg2 = ReplayDebugger::new("test", log)
  let mut pos = 0
  while pos <= n {
    let s1 = dbg1.seek(pos).current_session()
    let s2 = dbg2.seek(pos).current_session()
    assert_eq(s1.event_count(), s2.event_count())
    assert_eq(@orbit.project(s1).state, @orbit.project(s2).state)
    pos = pos + 1
  }
}

///|
test "step_back then step_forward returns to same state" {
  let log = demo_log()
  let dbg = ReplayDebugger::new("test", log).seek(5)
  let state_at_5 = @orbit.project(dbg.current_session()).state
  let dbg2 = dbg.step_back().step_forward()
  let state_at_5_again = @orbit.project(dbg2.current_session()).state
  assert_eq(state_at_5, state_at_5_again)
}

///|
test "seek with negative index clamps to 0" {
  let log = demo_log()
  let dbg = ReplayDebugger::new("test", log).seek(-1)
  assert_eq(dbg.cursor, 0)
}

///|
test "seek past end clamps to length" {
  let log = demo_log()
  let dbg = ReplayDebugger::new("test", log).seek(log.length() + 100)
  assert_eq(dbg.cursor, log.length())
}

///|
test "fork preserves original debugger unchanged" {
  let log = demo_log()
  let dbg = ReplayDebugger::new("test", log).seek(3)
  let state_before = @orbit.project(dbg.current_session()).state
  let extra : Array[@orbit.AgentEvent] = [
    @orbit.AgentEvent::UserMessage("forked message"),
  ]
  let _ = dbg.fork("fork-1", extra)
  let state_after = @orbit.project(dbg.current_session()).state
  assert_eq(state_before, state_after)
}
