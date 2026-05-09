///|
fn setup_running_session() -> @orbit.Session {
  let session = @orbit.Session::create("test")
  let session = match session.start() {
    Ok(s) => s
    Err(_) => @orbit.Session::create("test").fail("unreachable")
  }
  match session.send_user_message("hello") {
    Ok(s) => s
    Err(_) => session.fail("unreachable")
  }
}

///|
test "simulate_stream produces correct event_count" {
  let session = setup_running_session()
  let chunks = ["a", "b", "c"]
  let result = simulate_stream(session, chunks)
  match result {
    Ok(s) =>
      // 1 start + 1 user_msg + 3 chunks + 1 assistant_msg = 6
      assert_eq(s.event_count(), 6)
    Err(_) => assert_true(false)
  }
}

///|
test "current_stream_text joins chunks in order" {
  let session = setup_running_session()
  let chunks = ["a", "b", "c"]
  let mut s = session
  for chunk in chunks {
    s = s.apply(@orbit.StreamChunk(chunk))
  }
  let text = current_stream_text(s)
  assert_eq(text, "abc")
}

///|
test "accumulate_chunks matches current_stream_text" {
  let session = setup_running_session()
  let chunks = ["x", "y", "z"]
  let mut s = session
  for chunk in chunks {
    s = s.apply(@orbit.StreamChunk(chunk))
  }
  let from_orbit = @orbit.accumulate_chunks(s.event_log)
  let from_local = current_stream_text(s)
  assert_eq(from_orbit, from_local)
}

///|
test "replay produces same stream text as original" {
  let session = setup_running_session()
  let chunks = ["p", "q", "r"]
  let mut s = session
  for chunk in chunks {
    s = s.apply(@orbit.StreamChunk(chunk))
  }
  let original_text = current_stream_text(s)
  let replayed = @orbit.Session::replay("test", s.event_log)
  let replayed_text = current_stream_text(replayed)
  assert_eq(original_text, replayed_text)
}
