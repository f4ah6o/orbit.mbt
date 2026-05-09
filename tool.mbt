///|
/// Permission — explicit, inspectable, serializable boundaries.
/// Session-scoped: each session declares what operations tools may perform.
pub(all) enum Permission {
  FileRead(String)
  FileWrite(String)
  ShellExec(String)
  HttpAccess(String)
} derive(Debug, Eq)

///|
/// Show implementation for Permission — avoids deprecated derive(Show).
impl Show for Permission with to_string(self) -> String {
  match self {
    FileRead(p) => "FileRead(" + p + ")"
    FileWrite(p) => "FileWrite(" + p + ")"
    ShellExec(c) => "ShellExec(" + c + ")"
    HttpAccess(h) => "HttpAccess(" + h + ")"
  }
}

///|
/// Check if a required permission is granted by a set of granted permissions.
/// Supports "*" as a wildcard for any path, command, or host.
pub fn permission_granted(
  required : Permission,
  granted : Array[Permission],
) -> Bool {
  let mut found = false
  for g in granted {
    match (required, g) {
      (FileRead(p1), FileRead(p2)) => if p1 == p2 || p2 == "*" { found = true }
      (FileWrite(p1), FileWrite(p2)) =>
        if p1 == p2 || p2 == "*" {
          found = true
        }
      (ShellExec(c1), ShellExec(c2)) =>
        if c1 == c2 || c2 == "*" {
          found = true
        }
      (HttpAccess(h1), HttpAccess(h2)) =>
        if h1 == h2 || h2 == "*" {
          found = true
        }
      _ => ()
    }
    if found {
      return true
    }
  }
  false
}

///|
/// Check that all required permissions are covered by granted permissions.
pub fn permissions_satisfied(
  required : Array[Permission],
  granted : Array[Permission],
) -> Bool {
  let mut all_satisfied = true
  for r in required {
    if !permission_granted(r, granted) {
      all_satisfied = false
      return false
    }
  }
  all_satisfied
}

///|
/// Tool metadata — describes a tool's identity and required permissions.
pub(all) struct ToolMetadata {
  name : String
  description : String
  permissions : Array[Permission]
  version : String
} derive(Debug, Eq)

///|
/// Tool execution result — output of a tool invocation.
pub(all) struct ExecResult {
  output : String
  success : Bool
  error : String
} derive(Debug, Eq)

///|
/// Construct a successful ExecResult.
pub fn ExecResult::ok(output : String) -> ExecResult {
  { output, success: true, error: "" }
}

///|
/// Construct a failed ExecResult.
pub fn ExecResult::fail(error : String) -> ExecResult {
  { output: "", success: false, error }
}

///|
/// Tool trait — every tool implements metadata() and execute().
pub(open) trait Tool {
  metadata(Self) -> ToolMetadata
  execute(Self, String) -> ExecResult
}
