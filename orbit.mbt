///|
type SessionId = String

///|
type StateId = String

///|
struct RunContext {
  session_id : SessionId
} derive(Debug, Eq)

///|
pub(all) struct ToolRequest {
  tool_name : String
  input : String
  call_id : String
} derive(Debug, Eq)

///|
pub(all) struct ToolResponse {
  call_id : String
  output : String
  success : Bool
} derive(Debug, Eq)

///|
/// Agent state machine — illegal states unrepresentable.
/// Each variant carries exactly the data needed for that state.
pub enum AgentState {
  Idle
  Running(RunContext)
  WaitingTool(RunContext, ToolRequest)
  Failed(String)
} derive(Debug, Eq)

///|
/// Agent event — single source of truth for all runtime changes.
/// Every state transition is recorded as an event; replay is deterministic.
pub(all) enum AgentEvent {
  UserMessage(String)
  AssistantMessage(String)
  ToolCall(ToolRequest)
  ToolResult(ToolResponse)
  Transition(StateId, StateId)
  Reason(String)
  StreamChunk(String)
  SessionStarted(SessionId)
  SessionEnded(SessionId)
} derive(Debug, Eq)
