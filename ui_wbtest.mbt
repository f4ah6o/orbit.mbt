///|
test "escape_html plain text" {
  assert_eq(escape_html("hello"), "hello")
}

///|
test "escape_html angle brackets" {
  assert_eq(escape_html("<script>"), "&lt;script&gt;")
}

///|
test "escape_html ampersand" {
  assert_eq(escape_html("a&b"), "a&amp;b")
}

///|
test "escape_html double quote" {
  assert_eq(escape_html("he\"llo"), "he&quot;llo")
}

///|
test "escape_html single quote" {
  assert_eq(escape_html("it's"), "it&#39;s")
}

///|
test "escape_html mixed" {
  assert_eq(
    escape_html("<a href=\"x&y\">"),
    "&lt;a href=&quot;x&amp;y&quot;&gt;",
  )
}

///|
test "render_action" {
  let action = {
    rel: "start",
    method: "POST",
    href: "/session/s1/actions/start",
  }
  let html = render_action(action)
  let expected = "<form method=\"POST\" action=\"/session/s1/actions/start\" class=\"orbit-action\"><button type=\"submit\">start</button></form>"
  assert_eq(html, expected)
}

///|
test "render_resource idle session" {
  let s = Session::create("s1")
  let r = project(s)
  let html = render_resource(r)
  let expected = "<div class=\"orbit-session\" data-state=\"idle\"><header class=\"orbit-header\"><h2 class=\"orbit-state-label\">idle</h2></header><section class=\"orbit-messages\"></section><section class=\"orbit-actions\"><h3>Actions</h3><form method=\"POST\" action=\"/session/s1/actions/start\" class=\"orbit-action\"><button type=\"submit\">start</button></form></section><section class=\"orbit-reasons\"></section><footer class=\"orbit-links\"><nav><a rel=\"self\" href=\"/session/s1\" class=\"orbit-link\">self</a></nav></footer></div>"
  assert_eq(html, expected)
}

///|
test "render_resource running session with messages" {
  let s = Session::create("s1")
    .start()
    .unwrap()
    .send_user_message("hello")
    .unwrap()
    .receive_assistant_message("hi")
    .unwrap()
  let r = project(s)
  let html = render_resource(r)
  let expected = "<div class=\"orbit-session\" data-state=\"running\"><header class=\"orbit-header\"><h2 class=\"orbit-state-label\">running</h2></header><section class=\"orbit-messages\"><div class=\"orbit-message orbit-message--user\"><span class=\"orbit-message-role\">user</span><p class=\"orbit-message-content\">hello</p></div><div class=\"orbit-message orbit-message--assistant\"><span class=\"orbit-message-role\">assistant</span><p class=\"orbit-message-content\">hi</p></div></section><section class=\"orbit-actions\"><h3>Actions</h3><form method=\"POST\" action=\"/session/s1/actions/message\" class=\"orbit-action\"><button type=\"submit\">send_message</button></form><form method=\"POST\" action=\"/session/s1/actions/end\" class=\"orbit-action\"><button type=\"submit\">end</button></form><form method=\"POST\" action=\"/session/s1/actions/tool\" class=\"orbit-action\"><button type=\"submit\">request_tool</button></form></section><section class=\"orbit-reasons\"></section><footer class=\"orbit-links\"><nav><a rel=\"self\" href=\"/session/s1\" class=\"orbit-link\">self</a></nav></footer></div>"
  assert_eq(html, expected)
}

///|
test "render_resource waiting_tool session" {
  let req = { tool_name: "echo", input: "{}", call_id: "c1" }
  let s = Session::create("s1").start().unwrap().request_tool(req).unwrap()
  let r = project(s)
  let html = render_resource(r)
  let expected = "<div class=\"orbit-session\" data-state=\"waiting_tool\"><header class=\"orbit-header\"><h2 class=\"orbit-state-label\">waiting_tool</h2></header><section class=\"orbit-messages\"></section><section class=\"orbit-actions\"><h3>Actions</h3><form method=\"POST\" action=\"/session/s1/actions/tool\" class=\"orbit-action\"><button type=\"submit\">respond_tool</button></form><form method=\"POST\" action=\"/session/s1/actions/end\" class=\"orbit-action\"><button type=\"submit\">end</button></form></section><section class=\"orbit-reasons\"></section><footer class=\"orbit-links\"><nav><a rel=\"self\" href=\"/session/s1\" class=\"orbit-link\">self</a></nav></footer></div>"
  assert_eq(html, expected)
}

///|
test "render_resource failed session" {
  let s = Session::create("s1").start().unwrap().fail("timeout")
  let r = project(s)
  let html = render_resource(r)
  let expected = "<div class=\"orbit-session\" data-state=\"failed\"><header class=\"orbit-header\"><h2 class=\"orbit-state-label\">failed</h2></header><section class=\"orbit-messages\"></section><section class=\"orbit-actions\"></section><section class=\"orbit-reasons\"><h3>Reasons</h3><ul><li class=\"orbit-reason\">timeout</li></ul></section><footer class=\"orbit-links\"><nav><a rel=\"self\" href=\"/session/s1\" class=\"orbit-link\">self</a></nav></footer></div>"
  assert_eq(html, expected)
}

///|
test "render_resource escapes HTML in message content" {
  let s = Session::create("s1")
    .start()
    .unwrap()
    .send_user_message("<script>alert(1)</script>")
    .unwrap()
  let r = project(s)
  let html = render_resource(r)
  let expected = "<div class=\"orbit-session\" data-state=\"running\"><header class=\"orbit-header\"><h2 class=\"orbit-state-label\">running</h2></header><section class=\"orbit-messages\"><div class=\"orbit-message orbit-message--user\"><span class=\"orbit-message-role\">user</span><p class=\"orbit-message-content\">&lt;script&gt;alert(1)&lt;/script&gt;</p></div></section><section class=\"orbit-actions\"><h3>Actions</h3><form method=\"POST\" action=\"/session/s1/actions/message\" class=\"orbit-action\"><button type=\"submit\">send_message</button></form><form method=\"POST\" action=\"/session/s1/actions/end\" class=\"orbit-action\"><button type=\"submit\">end</button></form><form method=\"POST\" action=\"/session/s1/actions/tool\" class=\"orbit-action\"><button type=\"submit\">request_tool</button></form></section><section class=\"orbit-reasons\"></section><footer class=\"orbit-links\"><nav><a rel=\"self\" href=\"/session/s1\" class=\"orbit-link\">self</a></nav></footer></div>"
  assert_eq(html, expected)
}

///|
test "render_resource escapes HTML in reason content" {
  let s = Session::create("s1").start().unwrap().fail("error <bad>&stuff")
  let r = project(s)
  let html = render_resource(r)
  let expected = "<div class=\"orbit-session\" data-state=\"failed\"><header class=\"orbit-header\"><h2 class=\"orbit-state-label\">failed</h2></header><section class=\"orbit-messages\"></section><section class=\"orbit-actions\"></section><section class=\"orbit-reasons\"><h3>Reasons</h3><ul><li class=\"orbit-reason\">error &lt;bad&gt;&amp;stuff</li></ul></section><footer class=\"orbit-links\"><nav><a rel=\"self\" href=\"/session/s1\" class=\"orbit-link\">self</a></nav></footer></div>"
  assert_eq(html, expected)
}

///|
test "session_viewer idle session includes data-session-id" {
  let s = Session::create("s1")
  let html = session_viewer(s)
  let expected = "<div class=\"orbit-session\" data-state=\"idle\" data-session-id=\"s1\"><header class=\"orbit-header\"><h2 class=\"orbit-state-label\">idle</h2></header><section class=\"orbit-messages\"></section><section class=\"orbit-actions\"><h3>Actions</h3><form method=\"POST\" action=\"/session/s1/actions/start\" class=\"orbit-action\"><button type=\"submit\">start</button></form></section><section class=\"orbit-reasons\"></section><footer class=\"orbit-links\"><nav><a rel=\"self\" href=\"/session/s1\" class=\"orbit-link\">self</a></nav></footer></div>"
  assert_eq(html, expected)
}

///|
test "session_viewer running session with messages" {
  let s = Session::create("s1")
    .start()
    .unwrap()
    .send_user_message("hello")
    .unwrap()
    .receive_assistant_message("hi")
    .unwrap()
  let html = session_viewer(s)
  let expected = "<div class=\"orbit-session\" data-state=\"running\" data-session-id=\"s1\"><header class=\"orbit-header\"><h2 class=\"orbit-state-label\">running</h2></header><section class=\"orbit-messages\"><div class=\"orbit-message orbit-message--user\"><span class=\"orbit-message-role\">user</span><p class=\"orbit-message-content\">hello</p></div><div class=\"orbit-message orbit-message--assistant\"><span class=\"orbit-message-role\">assistant</span><p class=\"orbit-message-content\">hi</p></div></section><section class=\"orbit-actions\"><h3>Actions</h3><form method=\"POST\" action=\"/session/s1/actions/message\" class=\"orbit-action\"><button type=\"submit\">send_message</button></form><form method=\"POST\" action=\"/session/s1/actions/end\" class=\"orbit-action\"><button type=\"submit\">end</button></form><form method=\"POST\" action=\"/session/s1/actions/tool\" class=\"orbit-action\"><button type=\"submit\">request_tool</button></form></section><section class=\"orbit-reasons\"></section><footer class=\"orbit-links\"><nav><a rel=\"self\" href=\"/session/s1\" class=\"orbit-link\">self</a></nav></footer></div>"
  assert_eq(html, expected)
}

///|
test "session_viewer waiting_tool session" {
  let req = { tool_name: "echo", input: "{}", call_id: "c1" }
  let s = Session::create("s1").start().unwrap().request_tool(req).unwrap()
  let html = session_viewer(s)
  let expected = "<div class=\"orbit-session\" data-state=\"waiting_tool\" data-session-id=\"s1\"><header class=\"orbit-header\"><h2 class=\"orbit-state-label\">waiting_tool</h2></header><section class=\"orbit-messages\"></section><section class=\"orbit-actions\"><h3>Actions</h3><form method=\"POST\" action=\"/session/s1/actions/tool\" class=\"orbit-action\"><button type=\"submit\">respond_tool</button></form><form method=\"POST\" action=\"/session/s1/actions/end\" class=\"orbit-action\"><button type=\"submit\">end</button></form></section><section class=\"orbit-reasons\"></section><footer class=\"orbit-links\"><nav><a rel=\"self\" href=\"/session/s1\" class=\"orbit-link\">self</a></nav></footer></div>"
  assert_eq(html, expected)
}

///|
test "session_viewer failed session" {
  let s = Session::create("s1").start().unwrap().fail("timeout")
  let html = session_viewer(s)
  let expected = "<div class=\"orbit-session\" data-state=\"failed\" data-session-id=\"s1\"><header class=\"orbit-header\"><h2 class=\"orbit-state-label\">failed</h2></header><section class=\"orbit-messages\"></section><section class=\"orbit-actions\"></section><section class=\"orbit-reasons\"><h3>Reasons</h3><ul><li class=\"orbit-reason\">timeout</li></ul></section><footer class=\"orbit-links\"><nav><a rel=\"self\" href=\"/session/s1\" class=\"orbit-link\">self</a></nav></footer></div>"
  assert_eq(html, expected)
}

///|
test "accumulate_chunks empty" {
  let events : Array[AgentEvent] = []
  assert_eq(accumulate_chunks(events), "")
}

///|
test "accumulate_chunks single chunk" {
  let events = [StreamChunk("hello")]
  assert_eq(accumulate_chunks(events), "hello")
}

///|
test "accumulate_chunks multiple chunks" {
  let events = [StreamChunk("Hello "), StreamChunk("World")]
  assert_eq(accumulate_chunks(events), "Hello World")
}

///|
test "accumulate_chunks ignores non-chunk events" {
  let events = [
    UserMessage("hello"),
    StreamChunk("W"),
    StreamChunk("orld"),
    AssistantMessage("hi"),
  ]
  assert_eq(accumulate_chunks(events), "World")
}

///|
test "streaming_render with chunks" {
  let s = Session::create("s1").start().unwrap()
  let chunks = [StreamChunk("Hello "), StreamChunk("World")]
  let html = streaming_render(s, chunks)
  let expected = "<div class=\"orbit-session\" data-state=\"running\" data-session-id=\"s1\"><header class=\"orbit-header\"><h2 class=\"orbit-state-label\">running</h2></header><section class=\"orbit-messages\"><div class=\"orbit-message orbit-message--assistant\"><span class=\"orbit-message-role\">assistant</span><p class=\"orbit-message-content\">Hello World</p></div></section><section class=\"orbit-actions\"><h3>Actions</h3><form method=\"POST\" action=\"/session/s1/actions/message\" class=\"orbit-action\"><button type=\"submit\">send_message</button></form><form method=\"POST\" action=\"/session/s1/actions/end\" class=\"orbit-action\"><button type=\"submit\">end</button></form><form method=\"POST\" action=\"/session/s1/actions/tool\" class=\"orbit-action\"><button type=\"submit\">request_tool</button></form></section><section class=\"orbit-reasons\"></section><footer class=\"orbit-links\"><nav><a rel=\"self\" href=\"/session/s1\" class=\"orbit-link\">self</a></nav></footer></div><div class=\"orbit-streaming-indicator\">streaming…</div>"
  assert_eq(html, expected)
}

///|
test "streaming_render empty chunks returns session_viewer" {
  let s = Session::create("s1")
  let chunks : Array[AgentEvent] = []
  let html_stream = streaming_render(s, chunks)
  let html_viewer = session_viewer(s)
  assert_eq(html_stream, html_viewer)
}

///|
test "rendered HTML is deterministic across replays" {
  let original = Session::create("s1")
    .start()
    .unwrap()
    .send_user_message("hello")
    .unwrap()
    .receive_assistant_message("hi")
    .unwrap()
  let html1 = session_viewer(original)

  let replayed = Session::replay("s1", original.event_log)
  let html2 = session_viewer(replayed)

  assert_eq(html1, html2)
  assert_eq(original.event_count(), replayed.event_count())
}

///|
test "render_resource deterministic for identical resources" {
  let r1 = project(Session::create("s1"))
  let r2 = project(Session::create("s1"))
  assert_eq(render_resource(r1), render_resource(r2))
}
