///| HTML rendering for hypermedia resources.
/// No external dependencies — raw string generation with tmpx/mhx-compatible interfaces.

///|
fn escape_html(s : String) -> String {
  let mut buf = ""
  for ch in s {
    match ch {
      '&' => buf = buf + "&amp;"
      '<' => buf = buf + "&lt;"
      '>' => buf = buf + "&gt;"
      '"' => buf = buf + "&quot;"
      '\'' => buf = buf + "&#39;"
      _ => buf = buf + ch.to_string()
    }
  }
  buf
}

///|
fn render_action(action : Action) -> String {
  "<form method=\"" +
  escape_html(action.method) +
  "\" action=\"" +
  escape_html(action.href) +
  "\" class=\"orbit-action\">" +
  "<button type=\"submit\">" +
  escape_html(action.rel) +
  "</button>" +
  "</form>"
}

///|
fn render_actions(actions : Array[Action]) -> String {
  if actions.length() == 0 {
    return "<section class=\"orbit-actions\"></section>"
  }
  let mut buf = "<section class=\"orbit-actions\"><h3>Actions</h3>"
  for action in actions {
    buf = buf + render_action(action)
  }
  buf + "</section>"
}

///|
fn render_message(message : MessageEntry) -> String {
  "<div class=\"orbit-message orbit-message--" +
  escape_html(message.role) +
  "\">" +
  "<span class=\"orbit-message-role\">" +
  escape_html(message.role) +
  "</span>" +
  "<p class=\"orbit-message-content\">" +
  escape_html(message.content) +
  "</p>" +
  "</div>"
}

///|
fn render_messages(messages : Array[MessageEntry]) -> String {
  if messages.length() == 0 {
    return "<section class=\"orbit-messages\"></section>"
  }
  let mut buf = "<section class=\"orbit-messages\">"
  for message in messages {
    buf = buf + render_message(message)
  }
  buf + "</section>"
}

///|
fn render_reasons(reasons : Array[String]) -> String {
  if reasons.length() == 0 {
    return "<section class=\"orbit-reasons\"></section>"
  }
  let mut buf = "<section class=\"orbit-reasons\"><h3>Reasons</h3><ul>"
  for reason in reasons {
    buf = buf + "<li class=\"orbit-reason\">" + escape_html(reason) + "</li>"
  }
  buf + "</ul></section>"
}

///|
fn render_links(links : Array[Link]) -> String {
  if links.length() == 0 {
    return "<footer class=\"orbit-links\"></footer>"
  }
  let mut buf = "<footer class=\"orbit-links\"><nav>"
  for link in links {
    buf = buf +
      "<a rel=\"" +
      escape_html(link.rel) +
      "\" href=\"" +
      escape_html(link.href) +
      "\" class=\"orbit-link\">" +
      escape_html(link.rel) +
      "</a>"
  }
  buf + "</nav></footer>"
}

///|
/// Render a Resource projection as an HTML fragment.
/// This is the lower-level entry point — use session_viewer when you have a Session.
pub fn render_resource(resource : Resource) -> String {
  "<div class=\"orbit-session\" data-state=\"" +
  escape_html(resource.state) +
  "\">" +
  "<header class=\"orbit-header\"><h2 class=\"orbit-state-label\">" +
  escape_html(resource.state) +
  "</h2></header>" +
  render_messages(resource.messages) +
  render_actions(resource.available_actions) +
  render_reasons(resource.reasons) +
  render_links(resource.links) +
  "</div>"
}

///|
/// Accumulate StreamChunk deltas into a single string.
/// Reconstructs streaming content from the event stream — no mutable append.
pub fn accumulate_chunks(events : Array[AgentEvent]) -> String {
  let mut buf = ""
  for event in events {
    match event {
      StreamChunk(delta) => buf = buf + delta
      _ => ()
    }
  }
  buf
}

///|
/// Render a session with streaming content as HTML.
/// Takes the session and a separate list of streaming chunk events,
/// accumulates them, and appends the result as an in-progress assistant message.
pub fn streaming_render(
  session : Session,
  chunks : Array[AgentEvent],
) -> String {
  let streaming_content = accumulate_chunks(chunks)
  if streaming_content == "" {
    return session_viewer(session)
  }
  let resource = project(session)
  let stream_message = { role: "assistant", content: streaming_content }
  let updated_messages : Array[MessageEntry] = []
  for m in resource.messages {
    updated_messages.push(m)
  }
  updated_messages.push(stream_message)
  let streaming_resource = {
    state: resource.state,
    messages: updated_messages,
    available_actions: resource.available_actions,
    reasons: resource.reasons,
    links: resource.links,
  }
  "<div class=\"orbit-session\" data-state=\"" +
  escape_html(streaming_resource.state) +
  "\" data-session-id=\"" +
  escape_html(session.id) +
  "\">" +
  "<header class=\"orbit-header\"><h2 class=\"orbit-state-label\">" +
  escape_html(streaming_resource.state) +
  "</h2></header>" +
  render_messages(streaming_resource.messages) +
  render_actions(streaming_resource.available_actions) +
  render_reasons(streaming_resource.reasons) +
  render_links(streaming_resource.links) +
  "</div>" +
  "<div class=\"orbit-streaming-indicator\">streaming…</div>"
}

///|
/// Render a Session as HTML with its session-id attribute.
/// This is the top-level entry point for hypermedia rendering.
pub fn session_viewer(session : Session) -> String {
  let resource = project(session)
  "<div class=\"orbit-session\" data-state=\"" +
  escape_html(resource.state) +
  "\" data-session-id=\"" +
  escape_html(session.id) +
  "\">" +
  "<header class=\"orbit-header\"><h2 class=\"orbit-state-label\">" +
  escape_html(resource.state) +
  "</h2></header>" +
  render_messages(resource.messages) +
  render_actions(resource.available_actions) +
  render_reasons(resource.reasons) +
  render_links(resource.links) +
  "</div>"
}
