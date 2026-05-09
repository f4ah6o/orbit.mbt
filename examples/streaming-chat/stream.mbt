///|
/// Join an array of chunk strings into one.
fn join_chunks(chunks : Array[String]) -> String {
  let mut buf = ""
  for chunk in chunks {
    buf = buf + chunk
  }
  buf
}

///|
/// Simulate a streaming assistant response by appending N StreamChunk events.
/// chunks: array of strings to stream one by one
/// Returns session after all chunks appended + final AssistantMessage confirmation
pub fn simulate_stream(
  session : @orbit.Session,
  chunks : Array[String],
) -> Result[@orbit.Session, String] {
  let mut s = session
  for chunk in chunks {
    s = s.apply(@orbit.StreamChunk(chunk))
  }
  s.receive_assistant_message(join_chunks(chunks))
}

///|
/// Get the in-progress text from all StreamChunk events so far
pub fn current_stream_text(session : @orbit.Session) -> String {
  @orbit.accumulate_chunks(session.event_log)
}
