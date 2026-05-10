///|
/// App Server session contract.
///
/// This file is intentionally transport-free: it defines the JSON artifact that
/// native, wasm, WebView, or HTTP adapters can consume without making the core
/// runtime depend on any server or UI protocol.

///|
fn app_server_contract_version() -> String {
  "orbit.app_server.session.v1"
}

///|
fn replay_export_artifact_type() -> String {
  "orbit.app_server.replay_export"
}

///|
pub(all) struct AppServerPendingTool {
  lifecycle_state : String
  request : ToolRequest
  registered : Bool
} derive(Debug, Eq)

///|
pub(all) struct ApprovalBoundary {
  version : String
  normal_mutations : Array[String]
  approval_required_mutations : Array[String]
  required_permissions : Array[Permission]
  granted_permissions : Array[Permission]
  missing_permissions : Array[Permission]
  approval_required : Bool
  reason : String
} derive(Debug, Eq)

///|
pub(all) struct DiagnosticEntry {
  level : String
  code : String
  message : String
} derive(Debug, Eq)

///|
pub(all) struct LastAction {
  kind : String
  summary : String
} derive(Debug, Eq)

///|
pub(all) struct AgentSessionSnapshot {
  schema_version : String
  session_id : SessionId
  state : String
  event_log : Array[AgentEvent]
  messages : Array[MessageEntry]
  pending_tool : AppServerPendingTool?
  approval : ApprovalBoundary
  resource : Resource
  diagnostics : Array[DiagnosticEntry]
  last_action : LastAction
} derive(Debug, Eq)

///|
pub(all) struct ReplayExportEnvelope {
  schema_version : String
  artifact_type : String
  session_id : SessionId
  snapshot : AgentSessionSnapshot
  replay_events : Array[AgentEvent]
} derive(Debug, Eq)

///|
fn normal_app_server_mutations() -> Array[String] {
  // Normal mutations only append runtime events or move between pure Session
  // states. They do not execute host capabilities such as files, shell, or HTTP.
  [
    "start_session", "end_session", "append_user_message", "append_assistant_message",
    "record_tool_result", "record_failure", "record_stream_chunk",
  ]
}

///|
fn approval_required_app_server_mutations() -> Array[String] {
  // Approval-required mutations cross from the transport-free runtime into host
  // capabilities. Adapters may expose these over HTTP, WebView, or native calls,
  // but the boundary itself is represented here as data.
  [
    "approve_tool_request", "execute_tool_request", "grant_permission", "write_host_resource",
    "run_host_command", "open_network_connection",
  ]
}

///|
fn missing_permissions(
  required : Array[Permission],
  granted : Array[Permission],
) -> Array[Permission] {
  let missing : Array[Permission] = []
  for permission in required {
    if !permission_granted(permission, granted) {
      missing.push(permission)
    }
  }
  missing
}

///|
fn Permission::to_json(self : Permission) -> String {
  match self {
    FileRead(path) =>
      "{\"kind\":\"file_read\",\"value\":\"" + escape_json(path) + "\"}"
    FileWrite(path) =>
      "{\"kind\":\"file_write\",\"value\":\"" + escape_json(path) + "\"}"
    ShellExec(command) =>
      "{\"kind\":\"shell_exec\",\"value\":\"" + escape_json(command) + "\"}"
    HttpAccess(host) =>
      "{\"kind\":\"http_access\",\"value\":\"" + escape_json(host) + "\"}"
  }
}

///|
fn permissions_to_json(permissions : Array[Permission]) -> String {
  let mut buf = "["
  let mut first = true
  for permission in permissions {
    if first {
      buf = buf + permission.to_json()
      first = false
    } else {
      buf = buf + "," + permission.to_json()
    }
  }
  buf + "]"
}

///|
fn string_array_to_json(items : Array[String]) -> String {
  let mut buf = "["
  let mut first = true
  for item in items {
    if first {
      buf = buf + "\"" + escape_json(item) + "\""
      first = false
    } else {
      buf = buf + ",\"" + escape_json(item) + "\""
    }
  }
  buf + "]"
}

///|
fn event_log_to_json(events : Array[AgentEvent]) -> String {
  let mut buf = "["
  let mut first = true
  for event in events {
    if first {
      buf = buf + event_to_json(event)
      first = false
    } else {
      buf = buf + "," + event_to_json(event)
    }
  }
  buf + "]"
}

///|
fn tool_request_to_json(req : ToolRequest) -> String {
  "{\"tool_name\":\"" +
  escape_json(req.tool_name) +
  "\",\"input\":\"" +
  escape_json(req.input) +
  "\",\"call_id\":\"" +
  escape_json(req.call_id) +
  "\"}"
}

///|
fn AppServerPendingTool::to_json(self : AppServerPendingTool) -> String {
  "{\"lifecycle_state\":\"" +
  escape_json(self.lifecycle_state) +
  "\",\"request\":" +
  tool_request_to_json(self.request) +
  ",\"registered\":" +
  (if self.registered { "true" } else { "false" }) +
  "}"
}

///|
fn pending_tool_to_json(pending : AppServerPendingTool?) -> String {
  match pending {
    Some(tool) => tool.to_json()
    None => "null"
  }
}

///|
fn ApprovalBoundary::to_json(self : ApprovalBoundary) -> String {
  "{\"version\":\"" +
  escape_json(self.version) +
  "\",\"normal_mutations\":" +
  string_array_to_json(self.normal_mutations) +
  ",\"approval_required_mutations\":" +
  string_array_to_json(self.approval_required_mutations) +
  ",\"required_permissions\":" +
  permissions_to_json(self.required_permissions) +
  ",\"granted_permissions\":" +
  permissions_to_json(self.granted_permissions) +
  ",\"missing_permissions\":" +
  permissions_to_json(self.missing_permissions) +
  ",\"approval_required\":" +
  (if self.approval_required { "true" } else { "false" }) +
  ",\"reason\":\"" +
  escape_json(self.reason) +
  "\"}"
}

///|
fn DiagnosticEntry::to_json(self : DiagnosticEntry) -> String {
  "{\"level\":\"" +
  escape_json(self.level) +
  "\",\"code\":\"" +
  escape_json(self.code) +
  "\",\"message\":\"" +
  escape_json(self.message) +
  "\"}"
}

///|
fn diagnostics_to_json(diagnostics : Array[DiagnosticEntry]) -> String {
  let mut buf = "["
  let mut first = true
  for diagnostic in diagnostics {
    if first {
      buf = buf + diagnostic.to_json()
      first = false
    } else {
      buf = buf + "," + diagnostic.to_json()
    }
  }
  buf + "]"
}

///|
fn LastAction::to_json(self : LastAction) -> String {
  "{\"kind\":\"" +
  escape_json(self.kind) +
  "\",\"summary\":\"" +
  escape_json(self.summary) +
  "\"}"
}

///|
fn last_action_from_event(event : AgentEvent?) -> LastAction {
  match event {
    Some(UserMessage(_)) =>
      { kind: "user_message", summary: "user message appended" }
    Some(AssistantMessage(_)) =>
      { kind: "assistant_message", summary: "assistant message appended" }
    Some(ToolCall(req)) =>
      { kind: "tool_call", summary: "tool requested: " + req.tool_name }
    Some(ToolResult(res)) =>
      { kind: "tool_result", summary: "tool result recorded: " + res.call_id }
    Some(Transition(from, to)) =>
      { kind: "transition", summary: from + " -> " + to }
    Some(Reason(msg)) => { kind: "failure", summary: msg }
    Some(StreamChunk(_)) =>
      { kind: "stream_chunk", summary: "stream chunk recorded" }
    Some(SessionStarted(_)) =>
      { kind: "session_started", summary: "session started" }
    Some(SessionEnded(_)) => { kind: "session_ended", summary: "session ended" }
    None => { kind: "none", summary: "" }
  }
}

///|
fn last_event(events : Array[AgentEvent]) -> AgentEvent? {
  if events.length() == 0 {
    None
  } else {
    Some(events[events.length() - 1])
  }
}

///|
fn pending_tool_from_state(
  session : Session,
  registry : ToolRegistry?,
) -> AppServerPendingTool? {
  match session.current_state() {
    WaitingTool(_, req) => {
      let registered = match registry {
        Some(reg) => reg.has_tool(req.tool_name)
        None => false
      }
      Some({ lifecycle_state: "requested", request: req, registered })
    }
    _ => None
  }
}

///|
fn required_permissions_for_pending_tool(
  session : Session,
  registry : ToolRegistry?,
) -> Array[Permission] {
  match (session.current_state(), registry) {
    (WaitingTool(_, req), Some(reg)) =>
      match reg.lookup(req.tool_name) {
        Some(meta) => meta.permissions
        None => []
      }
    _ => []
  }
}

///|
fn approval_reason(
  pending : AppServerPendingTool?,
  missing : Array[Permission],
  required : Array[Permission],
) -> String {
  match pending {
    Some(tool) =>
      if !tool.registered {
        "pending tool is not registered"
      } else if missing.length() > 0 {
        "pending tool requires approval before host mutation"
      } else if required.length() > 0 {
        "pending tool permissions are already granted"
      } else {
        "pending tool has no host permission requirement"
      }
    None => "no pending host mutation"
  }
}

///|
fn diagnostics_for_snapshot(
  session : Session,
  pending : AppServerPendingTool?,
  missing : Array[Permission],
) -> Array[DiagnosticEntry] {
  let diagnostics : Array[DiagnosticEntry] = []
  match session.current_state() {
    Failed(reason) =>
      diagnostics.push({
        level: "error",
        code: "session_failed",
        message: reason,
      })
    _ => ()
  }
  match pending {
    Some(tool) =>
      if !tool.registered {
        diagnostics.push({
          level: "warning",
          code: "tool_not_registered",
          message: "pending tool is not registered: " + tool.request.tool_name,
        })
      }
    None => ()
  }
  if missing.length() > 0 {
    diagnostics.push({
      level: "info",
      code: "approval_required",
      message: "pending tool is waiting for missing permissions",
    })
  }
  diagnostics
}

///|
fn ApprovalBoundary::from_permissions(
  required : Array[Permission],
  granted : Array[Permission],
  pending : AppServerPendingTool?,
) -> ApprovalBoundary {
  let missing = missing_permissions(required, granted)
  let pending_unregistered = match pending {
    Some(tool) => !tool.registered
    None => false
  }
  {
    version: app_server_contract_version(),
    normal_mutations: normal_app_server_mutations(),
    approval_required_mutations: approval_required_app_server_mutations(),
    required_permissions: required,
    granted_permissions: granted,
    missing_permissions: missing,
    approval_required: missing.length() > 0 || pending_unregistered,
    reason: approval_reason(pending, missing, required),
  }
}

///|
fn AgentSessionSnapshot::create(
  session : Session,
  registry : ToolRegistry?,
  granted_permissions : Array[Permission],
) -> AgentSessionSnapshot {
  let pending = pending_tool_from_state(session, registry)
  let required = required_permissions_for_pending_tool(session, registry)
  let approval = ApprovalBoundary::from_permissions(
    required, granted_permissions, pending,
  )
  {
    schema_version: app_server_contract_version(),
    session_id: session.id,
    state: state_label(session.current_state()),
    event_log: session.event_log,
    messages: project(session).messages,
    pending_tool: pending,
    approval,
    resource: project(session),
    diagnostics: diagnostics_for_snapshot(
      session,
      pending,
      approval.missing_permissions,
    ),
    last_action: last_action_from_event(last_event(session.event_log)),
  }
}

///|
pub fn Session::app_server_snapshot(
  self : Session,
  registry : ToolRegistry,
  granted_permissions : Array[Permission],
) -> AgentSessionSnapshot {
  AgentSessionSnapshot::create(self, Some(registry), granted_permissions)
}

///|
pub fn Session::app_server_snapshot_without_registry(
  self : Session,
) -> AgentSessionSnapshot {
  AgentSessionSnapshot::create(self, None, [])
}

///|
pub fn Session::app_server_snapshot_json_without_registry(
  self : Session,
) -> String {
  self.app_server_snapshot_without_registry().to_json_string()
}

///|
pub fn AgentSessionSnapshot::to_json_string(
  self : AgentSessionSnapshot,
) -> String {
  "{\"schema_version\":\"" +
  escape_json(self.schema_version) +
  "\",\"session_id\":\"" +
  escape_json(self.session_id) +
  "\",\"state\":\"" +
  escape_json(self.state) +
  "\",\"event_log\":" +
  event_log_to_json(self.event_log) +
  ",\"messages\":" +
  messages_to_json(self.messages) +
  ",\"pending_tool\":" +
  pending_tool_to_json(self.pending_tool) +
  ",\"approval\":" +
  self.approval.to_json() +
  ",\"resource\":" +
  self.resource.to_json_string() +
  ",\"diagnostics\":" +
  diagnostics_to_json(self.diagnostics) +
  ",\"last_action\":" +
  self.last_action.to_json() +
  "}"
}

///|
pub fn Session::app_server_snapshot_json(
  self : Session,
  registry : ToolRegistry,
  granted_permissions : Array[Permission],
) -> String {
  self.app_server_snapshot(registry, granted_permissions).to_json_string()
}

///|
pub fn ReplayExportEnvelope::create(
  snapshot : AgentSessionSnapshot,
) -> ReplayExportEnvelope {
  {
    schema_version: app_server_contract_version(),
    artifact_type: replay_export_artifact_type(),
    session_id: snapshot.session_id,
    snapshot,
    replay_events: snapshot.event_log,
  }
}

///|
pub fn ReplayExportEnvelope::to_json_string(
  self : ReplayExportEnvelope,
) -> String {
  "{\"schema_version\":\"" +
  escape_json(self.schema_version) +
  "\",\"artifact_type\":\"" +
  escape_json(self.artifact_type) +
  "\",\"session_id\":\"" +
  escape_json(self.session_id) +
  "\",\"snapshot\":" +
  self.snapshot.to_json_string() +
  ",\"replay\":{\"events\":" +
  event_log_to_json(self.replay_events) +
  "}}"
}

///|
pub fn Session::app_server_replay_export_json(
  self : Session,
  registry : ToolRegistry,
  granted_permissions : Array[Permission],
) -> String {
  ReplayExportEnvelope::create(
    self.app_server_snapshot(registry, granted_permissions),
  ).to_json_string()
}
