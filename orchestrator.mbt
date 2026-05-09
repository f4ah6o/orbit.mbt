///| Multi-Agent Orchestration — planner/reviewer/executor flows, task graph, session coordination. ///|

///|
/// AgentRole — distinct roles in a multi-agent orchestration.
/// Compatible with planner/dispatcher/runner/reviewer/decider flows.
pub enum AgentRole {
  Planner
  Executor
  Reviewer
  Strategist
} derive(Debug, Eq)

///|
fn agent_role_to_string(role : AgentRole) -> String {
  match role {
    Planner => "planner"
    Executor => "executor"
    Reviewer => "reviewer"
    Strategist => "strategist"
  }
}

///|
fn agent_role_from_string(s : String) -> AgentRole? {
  match s {
    "planner" => Some(Planner)
    "executor" => Some(Executor)
    "reviewer" => Some(Reviewer)
    "strategist" => Some(Strategist)
    _ => None
  }
}

///| Task Graph — DAG management with cycle detection. ///|

///|
/// TaskNode — a single task in the orchestration graph.
pub struct TaskNode {
  id : String
  description : String
  role : AgentRole
  dependencies : Array[String]
} derive(Debug, Eq)

///|
/// TaskGraph — DAG managing task dependencies.
/// Cycles are detected and rejected as errors.
pub struct TaskGraph {
  nodes : Array[TaskNode]
} derive(Debug)

///|
pub fn TaskGraph::create() -> TaskGraph {
  { nodes: [] }
}

///|
pub fn TaskGraph::add_node(
  self : TaskGraph,
  node : TaskNode,
) -> Result[TaskGraph, String] {
  let mut i = 0
  while i < self.nodes.length() {
    if self.nodes[i].id == node.id {
      return Err("duplicate task id: " + node.id)
    }
    i = i + 1
  }
  let new_nodes : Array[TaskNode] = []
  let mut j = 0
  while j < self.nodes.length() {
    new_nodes.push(self.nodes[j])
    j = j + 1
  }
  new_nodes.push(node)
  Ok({ nodes: new_nodes })
}

///|
fn TaskGraph::node_index(self : TaskGraph, id : String) -> Int? {
  let mut i = 0
  while i < self.nodes.length() {
    if self.nodes[i].id == id {
      return Some(i)
    }
    i = i + 1
  }
  None
}

///|
pub fn TaskGraph::get_node(self : TaskGraph, id : String) -> TaskNode? {
  let mut i = 0
  while i < self.nodes.length() {
    if self.nodes[i].id == id {
      return Some(self.nodes[i])
    }
    i = i + 1
  }
  None
}

///|
/// Roots: nodes with no dependencies.
pub fn TaskGraph::roots(self : TaskGraph) -> Array[TaskNode] {
  let roots : Array[TaskNode] = []
  let mut i = 0
  while i < self.nodes.length() {
    if self.nodes[i].dependencies.length() == 0 {
      roots.push(self.nodes[i])
    }
    i = i + 1
  }
  roots
}

///|
/// Check whether the graph contains a cycle.
pub fn TaskGraph::has_cycle(self : TaskGraph) -> Bool {
  match self.topological_order() {
    Ok(_) => false
    Err(_) => true
  }
}

///|
/// Topological order via Kahn's algorithm.
/// Returns Err if a cycle is detected or a dependency is not found.
pub fn TaskGraph::topological_order(
  self : TaskGraph,
) -> Result[Array[TaskNode], String] {
  let n = self.nodes.length()
  let in_degree : Array[Int] = []
  let adj : Array[Array[Int]] = []
  let mut k = 0
  while k < n {
    in_degree.push(0)
    adj.push([])
    k = k + 1
  }

  // Build adjacency and in-degree
  let mut i = 0
  while i < n {
    let deps = self.nodes[i].dependencies
    let mut dep_idx = 0
    while dep_idx < deps.length() {
      match self.node_index(deps[dep_idx]) {
        Some(di) => {
          adj[di].push(i)
          in_degree[i] = in_degree[i] + 1
        }
        None =>
          return Err(
            "dependency not found: " +
            deps[dep_idx] +
            " for task " +
            self.nodes[i].id,
          )
      }
      dep_idx = dep_idx + 1
    }
    i = i + 1
  }

  // Kahn's algorithm
  let queue : Array[Int] = []
  let mut i = 0
  while i < n {
    if in_degree[i] == 0 {
      queue.push(i)
    }
    i = i + 1
  }

  let order : Array[TaskNode] = []
  let mut q_idx = 0
  while q_idx < queue.length() {
    let u = queue[q_idx]
    q_idx = q_idx + 1
    order.push(self.nodes[u])
    let neighbors = adj[u]
    let mut j = 0
    while j < neighbors.length() {
      let v = neighbors[j]
      in_degree[v] = in_degree[v] - 1
      if in_degree[v] == 0 {
        queue.push(v)
      }
      j = j + 1
    }
  }

  if order.length() != n {
    Err("cycle detected in task graph")
  } else {
    Ok(order)
  }
}

///|
pub fn TaskGraph::node_count(self : TaskGraph) -> Int {
  self.nodes.length()
}

///|
/// Return all task nodes.
pub fn TaskGraph::all_nodes(self : TaskGraph) -> Array[TaskNode] {
  self.nodes
}

///| Orchestrator Session — coordinates multiple Sessions bound to AgentRoles. ///|

///|
/// OrchestratorSession — multi-agent coordination container.
/// Manages a TaskGraph and binds AgentRole to individual Sessions.
pub struct OrchestratorSession {
  id : SessionId
  task_graph : TaskGraph
  agent_sessions : Array[(AgentRole, Session)]
} derive(Debug)

///|
pub fn OrchestratorSession::create(id : SessionId) -> OrchestratorSession {
  { id, task_graph: TaskGraph::create(), agent_sessions: [] }
}

///|
pub fn OrchestratorSession::set_task_graph(
  self : OrchestratorSession,
  graph : TaskGraph,
) -> OrchestratorSession {
  { id: self.id, task_graph: graph, agent_sessions: self.agent_sessions }
}

///|
/// Bind a session to a role (insert or replace).
pub fn OrchestratorSession::bind_session(
  self : OrchestratorSession,
  role : AgentRole,
  session : Session,
) -> OrchestratorSession {
  let new_sessions : Array[(AgentRole, Session)] = []
  let mut found = false
  let mut i = 0
  while i < self.agent_sessions.length() {
    if self.agent_sessions[i].0 == role {
      new_sessions.push((role, session))
      found = true
    } else {
      new_sessions.push(self.agent_sessions[i])
    }
    i = i + 1
  }
  if !found {
    new_sessions.push((role, session))
  }
  { id: self.id, task_graph: self.task_graph, agent_sessions: new_sessions }
}

///|
fn OrchestratorSession::find_session(
  self : OrchestratorSession,
  role : AgentRole,
) -> Session? {
  let mut i = 0
  while i < self.agent_sessions.length() {
    if self.agent_sessions[i].0 == role {
      return Some(self.agent_sessions[i].1)
    }
    i = i + 1
  }
  None
}

///|
/// Dispatch a task to the appropriate agent session based on role.
/// Finds an existing session or creates a new one; returns the updated
/// orchestrator and the dispatched session.
pub fn OrchestratorSession::dispatch(
  self : OrchestratorSession,
  role : AgentRole,
) -> (OrchestratorSession, Session) {
  let session = match self.find_session(role) {
    Some(s) => s
    None => {
      let sid = self.id + "/" + agent_role_to_string(role)
      Session::create(sid)
    }
  }
  let updated = self.bind_session(role, session)
  (updated, session)
}

///|
/// Get the number of bound agent sessions.
pub fn OrchestratorSession::agent_count(self : OrchestratorSession) -> Int {
  self.agent_sessions.length()
}

///|
/// Check if a session is bound for a given role.
pub fn OrchestratorSession::has_agent(
  self : OrchestratorSession,
  role : AgentRole,
) -> Bool {
  match self.find_session(role) {
    Some(_) => true
    None => false
  }
}

///|
/// Get the session for a role, if one is bound.
pub fn OrchestratorSession::get_session(
  self : OrchestratorSession,
  role : AgentRole,
) -> Session? {
  self.find_session(role)
}

///| Session Snapshot — serializable state of an orchestration session (session.yaml equivalent). ///|

///|
/// AgentEntry — role-to-session binding in the snapshot.
pub struct AgentEntry {
  role : String
  session_id : String
  state : String
} derive(Debug, Eq)

///|
/// TaskSnapshot — task state in the snapshot.
pub struct TaskSnapshot {
  id : String
  description : String
  role : String
  dependencies : Array[String]
  status : String
} derive(Debug, Eq)

///|
/// TransitionEntry — a transition record between tasks.
pub struct TransitionEntry {
  from : String
  to : String
  reason : String
} derive(Debug, Eq)

///|
/// SessionSnapshot — full serializable orchestrator state.
/// Equivalent to the session.yaml concept from HANDOFF.
pub struct SessionSnapshot {
  session_id : String
  state : String
  agents : Array[AgentEntry]
  tasks : Array[TaskSnapshot]
  transitions : Array[TransitionEntry]
} derive(Debug, Eq)

///|
/// Build a SessionSnapshot from an OrchestratorSession.
pub fn OrchestratorSession::snapshot(
  self : OrchestratorSession,
) -> SessionSnapshot {
  let agents : Array[AgentEntry] = []
  let mut i = 0
  while i < self.agent_sessions.length() {
    let entry = self.agent_sessions[i]
    let role_str = agent_role_to_string(entry.0)
    agents.push({
      role: role_str,
      session_id: entry.1.id,
      state: state_label(entry.1.current_state()),
    })
    i = i + 1
  }

  let tasks : Array[TaskSnapshot] = []
  let mut j = 0
  while j < self.task_graph.nodes.length() {
    let node = self.task_graph.nodes[j]
    tasks.push({
      id: node.id,
      description: node.description,
      role: agent_role_to_string(node.role),
      dependencies: node.dependencies,
      status: "pending",
    })
    j = j + 1
  }

  {
    session_id: self.id,
    state: "orchestrating",
    agents,
    tasks,
    transitions: [],
  }
}

///| SessionSnapshot JSON serialization — deterministic, manual. ///|

///|
fn AgentEntry::to_json(self : AgentEntry) -> String {
  "{\"role\":\"" +
  escape_json(self.role) +
  "\",\"session_id\":\"" +
  escape_json(self.session_id) +
  "\",\"state\":\"" +
  escape_json(self.state) +
  "\"}"
}

///|
fn TaskSnapshot::to_json(self : TaskSnapshot) -> String {
  "{\"id\":\"" +
  escape_json(self.id) +
  "\",\"description\":\"" +
  escape_json(self.description) +
  "\",\"role\":\"" +
  escape_json(self.role) +
  "\",\"dependencies\":" +
  strings_to_json(self.dependencies) +
  ",\"status\":\"" +
  escape_json(self.status) +
  "\"}"
}

///|
fn TransitionEntry::to_json(self : TransitionEntry) -> String {
  "{\"from\":\"" +
  escape_json(self.from) +
  "\",\"to\":\"" +
  escape_json(self.to) +
  "\",\"reason\":\"" +
  escape_json(self.reason) +
  "\"}"
}

///|
fn agents_to_json(agents : Array[AgentEntry]) -> String {
  let mut buf = "["
  let mut first = true
  let mut i = 0
  while i < agents.length() {
    if first {
      buf = buf + agents[i].to_json()
      first = false
    } else {
      buf = buf + "," + agents[i].to_json()
    }
    i = i + 1
  }
  buf + "]"
}

///|
fn task_snapshots_to_json(tasks : Array[TaskSnapshot]) -> String {
  let mut buf = "["
  let mut first = true
  let mut i = 0
  while i < tasks.length() {
    if first {
      buf = buf + tasks[i].to_json()
      first = false
    } else {
      buf = buf + "," + tasks[i].to_json()
    }
    i = i + 1
  }
  buf + "]"
}

///|
fn transitions_to_json(transitions : Array[TransitionEntry]) -> String {
  let mut buf = "["
  let mut first = true
  let mut i = 0
  while i < transitions.length() {
    if first {
      buf = buf + transitions[i].to_json()
      first = false
    } else {
      buf = buf + "," + transitions[i].to_json()
    }
    i = i + 1
  }
  buf + "]"
}

///|
/// Serialize a SessionSnapshot to a deterministic JSON string.
pub fn SessionSnapshot::to_json_string(self : SessionSnapshot) -> String {
  "{" +
  "\"session_id\":\"" +
  escape_json(self.session_id) +
  "\"," +
  "\"state\":\"" +
  escape_json(self.state) +
  "\"," +
  "\"agents\":" +
  agents_to_json(self.agents) +
  "," +
  "\"tasks\":" +
  task_snapshots_to_json(self.tasks) +
  "," +
  "\"transitions\":" +
  transitions_to_json(self.transitions) +
  "}"
}

///| SessionSnapshot JSON deserialization — minimal, handles the format we produce. ///|

///|
fn agent_entry_from_json(json : String) -> AgentEntry? {
  let role = json_extract_string(json, "role")
  let session_id = json_extract_string(json, "session_id")
  let state = json_extract_string(json, "state")
  match (role, session_id, state) {
    (Some(r), Some(sid), Some(st)) =>
      Some({ role: r, session_id: sid, state: st })
    _ => None
  }
}

///|
fn task_snapshot_from_json(json : String) -> TaskSnapshot? {
  let id = json_extract_string(json, "id")
  let description = json_extract_string(json, "description")
  let role = json_extract_string(json, "role")
  let status = json_extract_string(json, "status")
  let deps_json = json_extract_array(json, "dependencies")
  match (id, description, role, status, deps_json) {
    (Some(i), Some(desc), Some(r), Some(st), Some(dj)) => {
      let deps = parse_string_array(dj)
      Some({ id: i, description: desc, role: r, dependencies: deps, status: st })
    }
    _ => None
  }
}

///|
fn parse_string_array(json : String) -> Array[String] {
  let items : Array[String] = []
  let len = json.length()
  let mut i = 0
  while i < len {
    if json[i] == '"' {
      let mut j = i + 1
      let mut buf = ""
      while j < len {
        if json[j] == '"' {
          items.push(buf)
          i = j + 1
          break
        }
        if json[j] == '\\' && j + 1 < len {
          let next = json[j + 1]
          match next {
            '"' => {
              buf = buf + "\""
              j = j + 2
              continue
            }
            '\\' => {
              buf = buf + "\\"
              j = j + 2
              continue
            }
            'n' => {
              buf = buf + "\n"
              j = j + 2
              continue
            }
            'r' => {
              buf = buf + "\r"
              j = j + 2
              continue
            }
            't' => {
              buf = buf + "\t"
              j = j + 2
              continue
            }
            _ => {
              j = j + 2
              continue
            }
          }
        }
        buf = buf + json[j:j + 1].to_owned()
        j = j + 1
      }
    } else {
      i = i + 1
    }
  }
  items
}

///|
fn transition_entry_from_json(json : String) -> TransitionEntry? {
  let from = json_extract_string(json, "from")
  let to = json_extract_string(json, "to")
  let reason = json_extract_string(json, "reason")
  match (from, to, reason) {
    (Some(f), Some(t), Some(r)) => Some({ from: f, to: t, reason: r })
    _ => None
  }
}

///|
fn split_snapshot_array(json : String) -> Array[String] {
  let items : Array[String] = []
  let len = json.length()
  let mut i = 0
  let mut depth = 0
  let mut start = -1
  while i < len {
    if json[i] == '{' {
      if depth == 0 {
        start = i
      }
      depth = depth + 1
    } else if json[i] == '}' {
      if depth == 1 {
        items.push(json[start:i + 1].to_owned())
        start = -1
      }
      depth = depth - 1
    }
    i = i + 1
  }
  items
}

///|
fn agents_from_json_array(json : String) -> Array[AgentEntry] {
  let parts = split_snapshot_array(json)
  let agents : Array[AgentEntry] = []
  let mut i = 0
  while i < parts.length() {
    match agent_entry_from_json(parts[i]) {
      Some(a) => agents.push(a)
      None => ()
    }
    i = i + 1
  }
  agents
}

///|
fn tasks_from_json_array(json : String) -> Array[TaskSnapshot] {
  let parts = split_snapshot_array(json)
  let tasks : Array[TaskSnapshot] = []
  let mut i = 0
  while i < parts.length() {
    match task_snapshot_from_json(parts[i]) {
      Some(t) => tasks.push(t)
      None => ()
    }
    i = i + 1
  }
  tasks
}

///|
fn transitions_from_json_array(json : String) -> Array[TransitionEntry] {
  let parts = split_snapshot_array(json)
  let transitions : Array[TransitionEntry] = []
  let mut i = 0
  while i < parts.length() {
    match transition_entry_from_json(parts[i]) {
      Some(t) => transitions.push(t)
      None => ()
    }
    i = i + 1
  }
  transitions
}

///|
/// Deserialize a SessionSnapshot from a JSON string.
pub fn session_snapshot_from_json(json : String) -> SessionSnapshot? {
  let session_id = json_extract_string(json, "session_id")
  let state = json_extract_string(json, "state")
  let agents_json = json_extract_array(json, "agents")
  let tasks_json = json_extract_array(json, "tasks")
  let transitions_json = json_extract_array(json, "transitions")
  match (session_id, state, agents_json, tasks_json, transitions_json) {
    (Some(sid), Some(st), Some(aj), Some(tj), Some(tj2)) =>
      Some({
        session_id: sid,
        state: st,
        agents: agents_from_json_array(aj),
        tasks: tasks_from_json_array(tj),
        transitions: transitions_from_json_array(tj2),
      })
    _ => None
  }
}
