///|
/// Decision for a pending tool call: Allow or Deny.
pub(all) enum GateDecision {
  Allow
  Deny
} derive(Debug, Eq)

///|
/// Given a session in WaitingTool state, simulate user approving or denying.
///
/// - Allow: execute the tool via registry and respond_tool.
/// - Deny: fail the session with "denied by user: <tool_name>".
///
/// Returns the session unchanged if not in WaitingTool state.
pub fn gate_decide(
  session : @orbit.Session,
  registry : @orbit.ToolRegistry,
  decision : GateDecision,
) -> @orbit.Session {
  match session.current_state() {
    @orbit.WaitingTool(_ctx, req) =>
      match decision {
        Allow =>
          match registry.execute(req.tool_name, req.input) {
            Ok(result) => {
              let res : @orbit.ToolResponse = {
                call_id: req.call_id,
                output: result.output,
                success: result.success,
              }
              match session.respond_tool(res) {
                Ok(s) => s
                Err(msg) => session.fail(msg)
              }
            }
            Err(msg) => session.fail("tool execution error: " + msg)
          }
        Deny => session.fail("denied by user: " + req.tool_name)
      }
    _ => session
  }
}
