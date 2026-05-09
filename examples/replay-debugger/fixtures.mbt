///|
pub fn demo_log() -> Array[@orbit.AgentEvent] {
  let req : @orbit.ToolRequest = {
    tool_name: "read_file",
    input: "/path/to/file",
    call_id: "call-1",
  }
  let res : @orbit.ToolResponse = {
    call_id: "call-1",
    output: "file contents",
    success: true,
  }
  [
    @orbit.AgentEvent::SessionStarted("demo"),
    @orbit.AgentEvent::UserMessage("Hello, can you read this file?"),
    @orbit.AgentEvent::AssistantMessage("Sure, let me read it for you."),
    @orbit.AgentEvent::ToolCall(req),
    @orbit.AgentEvent::ToolResult(res),
    @orbit.AgentEvent::UserMessage("Thanks, now summarize it."),
    @orbit.AgentEvent::StreamChunk("Here"),
    @orbit.AgentEvent::StreamChunk(" is a"),
    @orbit.AgentEvent::StreamChunk(" summary."),
    @orbit.AgentEvent::AssistantMessage("Complete summary: it's a great file."),
  ]
}
