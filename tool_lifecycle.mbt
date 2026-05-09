///|
/// Tool lifecycle — illegal states unrepresentable.
/// requested -> approved -> executing -> completed
///                             \-> failed
pub enum ToolLifecycle {
  Requested(ToolRequest)
  Approved(ToolRequest, Array[Permission])
  Executing(ToolRequest)
  Completed(ToolRequest, ExecResult)
  Failed(ToolRequest, String)
} derive(Debug, Eq)

///|
/// Create a new lifecycle in the Requested state.
pub fn ToolLifecycle::requested(req : ToolRequest) -> ToolLifecycle {
  Requested(req)
}

///|
/// Transition: Requested -> Approved.
/// Granted permissions are associated with the approval for auditability.
pub fn ToolLifecycle::approve(
  self : ToolLifecycle,
  granted : Array[Permission],
) -> Result[ToolLifecycle, String] {
  match self {
    Requested(req) => Ok(Approved(req, granted))
    _ => Err("can only approve a requested tool")
  }
}

///|
/// Transition: Approved -> Executing.
pub fn ToolLifecycle::start_executing(
  self : ToolLifecycle,
) -> Result[ToolLifecycle, String] {
  match self {
    Approved(req, _) => Ok(Executing(req))
    _ => Err("can only start executing an approved tool")
  }
}

///|
/// Transition: Executing -> Completed.
pub fn ToolLifecycle::complete(
  self : ToolLifecycle,
  result : ExecResult,
) -> Result[ToolLifecycle, String] {
  match self {
    Executing(req) => Ok(Completed(req, result))
    _ => Err("can only complete an executing tool")
  }
}

///|
/// Transition: any active state -> Failed.
pub fn ToolLifecycle::fail(
  self : ToolLifecycle,
  reason : String,
) -> ToolLifecycle {
  match self {
    Requested(req) => Failed(req, reason)
    Approved(req, _) => Failed(req, reason)
    Executing(req) => Failed(req, reason)
    Completed(_, _) | Failed(_, _) => self
  }
}

///|
/// Check if the lifecycle is in a terminal state.
pub fn ToolLifecycle::is_terminal(self : ToolLifecycle) -> Bool {
  match self {
    Completed(_, _) | Failed(_, _) => true
    _ => false
  }
}

///|
/// Check if the lifecycle is in the Requested state.
pub fn ToolLifecycle::is_requested(self : ToolLifecycle) -> Bool {
  match self {
    Requested(_) => true
    _ => false
  }
}

///|
/// Check if the lifecycle is in the Approved state.
pub fn ToolLifecycle::is_approved(self : ToolLifecycle) -> Bool {
  match self {
    Approved(_, _) => true
    _ => false
  }
}

///|
/// Check if the lifecycle is in the Executing state.
pub fn ToolLifecycle::is_executing(self : ToolLifecycle) -> Bool {
  match self {
    Executing(_) => true
    _ => false
  }
}

///|
/// Check if the lifecycle is in the Completed state.
pub fn ToolLifecycle::is_completed(self : ToolLifecycle) -> Bool {
  match self {
    Completed(_, _) => true
    _ => false
  }
}

///|
/// Check if the lifecycle is in the Failed state.
pub fn ToolLifecycle::is_failed(self : ToolLifecycle) -> Bool {
  match self {
    Failed(_, _) => true
    _ => false
  }
}

///|
/// Get the ToolRequest from any lifecycle state.
pub fn ToolLifecycle::request(self : ToolLifecycle) -> ToolRequest {
  match self {
    Requested(req) => req
    Approved(req, _) => req
    Executing(req) => req
    Completed(req, _) => req
    Failed(req, _) => req
  }
}
