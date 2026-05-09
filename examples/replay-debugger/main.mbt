///|
fn main {
  let log = demo_log()
  let total = log.length()
  let mut dbg = ReplayDebugger::new("demo", log)

  println("=== Walking forward ===")
  let mut i = 0
  while i < total {
    dbg = dbg.step_forward()
    let session = dbg.current_session()
    let desc = dbg.last_event_description()
    let state_label = @orbit.project(session).state
    println(
      "[" +
      dbg.cursor.to_string() +
      "/" +
      total.to_string() +
      "] " +
      desc +
      " | state: " +
      state_label,
    )
    i = i + 1
  }

  println("")
  println("=== Seeking back to position 3 ===")
  dbg = dbg.seek(3)
  let session3 = dbg.current_session()
  let state3 = @orbit.project(session3).state
  println(
    "at position 3, state: " + state3 + " | " + dbg.last_event_description(),
  )

  println("")
  println("=== Forking from position 3 ===")
  let extra_events : Array[@orbit.AgentEvent] = [
    @orbit.AgentEvent::UserMessage("What about the second file?"),
  ]
  let fork = dbg.fork("demo-fork-1", extra_events)
  let mut fork_dbg = fork
  while fork_dbg.cursor < fork_dbg.full_log.length() {
    fork_dbg = fork_dbg.step_forward()
    let desc = fork_dbg.last_event_description()
    let state_label = @orbit.project(fork_dbg.current_session()).state
    println(
      "[" +
      fork_dbg.cursor.to_string() +
      "/" +
      fork_dbg.full_log.length().to_string() +
      "] " +
      desc +
      " | state: " +
      state_label,
    )
  }
}
