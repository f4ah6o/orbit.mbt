///|
fn main {
  let session = @orbit.Session::create("streaming-demo")
  let session = match session.start() {
    Ok(s) => s
    Err(msg) => {
      println("Error starting: " + msg)
      return
    }
  }

  let session = match session.send_user_message("write me a haiku") {
    Ok(s) => s
    Err(msg) => {
      println("Error sending: " + msg)
      return
    }
  }

  let chunks = [
    "The ", "moon ", "hangs ", "low,\n", "Silence ", "fills ", "the ", "bamboo ",
    "grove,\n", "Dawn ", "breaks ", "softly.",
  ]

  println("--- Streaming Simulation ---")
  let mut s = session
  for chunk in chunks {
    s = s.apply(@orbit.StreamChunk(chunk))
    let progress = @orbit.accumulate_chunks(s.event_log)
    println("[" + progress + "]")
  }

  let s = match simulate_stream_confirm(s, chunks) {
    Ok(s2) => s2
    Err(msg) => {
      println("Error: " + msg)
      return
    }
  }

  println("--- Final ---")
  println("Event count: " + s.event_count().to_string())
  let state_str = match s.current_state() {
    @orbit.Idle => "idle"
    @orbit.Running(_) => "running"
    @orbit.WaitingTool(_, _) => "waiting_tool"
    @orbit.Failed(_) => "failed"
  }
  println("State: " + state_str)
}

///|
fn simulate_stream_confirm(
  session : @orbit.Session,
  _chunks : Array[String],
) -> Result[@orbit.Session, String] {
  let joined = @orbit.accumulate_chunks(session.event_log)
  session.receive_assistant_message(joined)
}
