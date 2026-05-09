// Whitebox tests for multi-agent orchestration.

///|
test "agent_role_to_string converts all variants" {
  assert_eq(agent_role_to_string(Planner), "planner")
  assert_eq(agent_role_to_string(Executor), "executor")
  assert_eq(agent_role_to_string(Reviewer), "reviewer")
  assert_eq(agent_role_to_string(Strategist), "strategist")
}

///|
test "agent_role_from_string round-tripping" {
  assert_true(agent_role_from_string("planner") == Some(Planner))
  assert_true(agent_role_from_string("executor") == Some(Executor))
  assert_true(agent_role_from_string("reviewer") == Some(Reviewer))
  assert_true(agent_role_from_string("strategist") == Some(Strategist))
  assert_true(agent_role_from_string("unknown") == None)
}

///|
test "agent_role equality" {
  assert_true(Planner == Planner)
  assert_true(Planner != Executor)
}

///|
test "task node construction" {
  let node : TaskNode = {
    id: "task1",
    description: "Plan the solution",
    role: Planner,
    dependencies: [],
  }
  assert_eq(node.id, "task1")
  assert_eq(node.description, "Plan the solution")
  assert_true(node.role == Planner)
  assert_eq(node.dependencies.length(), 0)
}

///|
test "task node with dependencies" {
  let node : TaskNode = {
    id: "task2",
    description: "Execute the plan",
    role: Executor,
    dependencies: ["task1"],
  }
  assert_eq(node.dependencies.length(), 1)
  assert_eq(node.dependencies[0], "task1")
}

///|
test "task graph: create empty" {
  let graph = TaskGraph::create()
  assert_eq(graph.node_count(), 0)
}

///|
test "task graph: add single node" {
  let node : TaskNode = {
    id: "t1",
    description: "First task",
    role: Planner,
    dependencies: [],
  }
  let graph = TaskGraph::create().add_node(node).unwrap()
  assert_eq(graph.node_count(), 1)
  assert_true(graph.get_node("t1") != None)
}

///|
test "task graph: duplicate node id is rejected" {
  let node : TaskNode = {
    id: "t1",
    description: "First task",
    role: Planner,
    dependencies: [],
  }
  let graph = TaskGraph::create().add_node(node).unwrap()
  let result = graph.add_node(node)
  assert_true(result is Err(_))
}

///|
test "task graph: get_node returns node" {
  let node : TaskNode = {
    id: "t1",
    description: "Task one",
    role: Planner,
    dependencies: [],
  }
  let graph = TaskGraph::create().add_node(node).unwrap()
  let found = graph.get_node("t1")
  match found {
    Some(n) => {
      assert_eq(n.id, "t1")
      assert_eq(n.description, "Task one")
    }
    None => assert_true(false)
  }
}

///|
test "task graph: get_node returns None for missing" {
  let graph = TaskGraph::create()
  assert_true(graph.get_node("missing") == None)
}

///|
test "task graph: roots with no dependencies" {
  let n1 : TaskNode = {
    id: "t1",
    description: "Task 1",
    role: Planner,
    dependencies: [],
  }
  let n2 : TaskNode = {
    id: "t2",
    description: "Task 2",
    role: Executor,
    dependencies: [],
  }
  let graph = TaskGraph::create().add_node(n1).unwrap().add_node(n2).unwrap()
  let roots = graph.roots()
  assert_eq(roots.length(), 2)
}

///|
test "task graph: roots with dependencies" {
  let n1 : TaskNode = {
    id: "t1",
    description: "Task 1",
    role: Planner,
    dependencies: [],
  }
  let n2 : TaskNode = {
    id: "t2",
    description: "Task 2",
    role: Executor,
    dependencies: ["t1"],
  }
  let graph = TaskGraph::create().add_node(n1).unwrap().add_node(n2).unwrap()
  let roots = graph.roots()
  assert_eq(roots.length(), 1)
  assert_eq(roots[0].id, "t1")
}

///|
test "task graph: topological order linear" {
  let n1 : TaskNode = {
    id: "t1",
    description: "First",
    role: Planner,
    dependencies: [],
  }
  let n2 : TaskNode = {
    id: "t2",
    description: "Second",
    role: Executor,
    dependencies: ["t1"],
  }
  let n3 : TaskNode = {
    id: "t3",
    description: "Third",
    role: Reviewer,
    dependencies: ["t2"],
  }
  let graph = TaskGraph::create()
    .add_node(n1)
    .unwrap()
    .add_node(n2)
    .unwrap()
    .add_node(n3)
    .unwrap()
  let order = graph.topological_order().unwrap()
  assert_eq(order.length(), 3)
  assert_eq(order[0].id, "t1")
  assert_eq(order[1].id, "t2")
  assert_eq(order[2].id, "t3")
}

///|
test "task graph: topological order diamond" {
  // t1 -> t2, t1 -> t3 -> t4; t2 -> t4
  let n1 : TaskNode = {
    id: "t1",
    description: "Root",
    role: Planner,
    dependencies: [],
  }
  let n2 : TaskNode = {
    id: "t2",
    description: "Left",
    role: Executor,
    dependencies: ["t1"],
  }
  let n3 : TaskNode = {
    id: "t3",
    description: "Right",
    role: Executor,
    dependencies: ["t1"],
  }
  let n4 : TaskNode = {
    id: "t4",
    description: "Sink",
    role: Reviewer,
    dependencies: ["t2", "t3"],
  }
  let graph = TaskGraph::create()
    .add_node(n1)
    .unwrap()
    .add_node(n2)
    .unwrap()
    .add_node(n3)
    .unwrap()
    .add_node(n4)
    .unwrap()
  let order = graph.topological_order().unwrap()
  assert_eq(order.length(), 4)
  assert_eq(order[0].id, "t1")
  // t2 and t3 appear before t4
  assert_eq(order[3].id, "t4")
}

///|
test "task graph: cycle detection returns error" {
  let n1 : TaskNode = {
    id: "t1",
    description: "Task 1",
    role: Planner,
    dependencies: ["t2"],
  }
  let n2 : TaskNode = {
    id: "t2",
    description: "Task 2",
    role: Executor,
    dependencies: ["t1"],
  }
  let graph = TaskGraph::create().add_node(n1).unwrap().add_node(n2).unwrap()
  assert_true(graph.has_cycle())
  assert_true(graph.topological_order() is Err(_))
}

///|
test "task graph: cycle-free graph has no cycle" {
  let n1 : TaskNode = {
    id: "t1",
    description: "Task 1",
    role: Planner,
    dependencies: [],
  }
  let n2 : TaskNode = {
    id: "t2",
    description: "Task 2",
    role: Executor,
    dependencies: ["t1"],
  }
  let graph = TaskGraph::create().add_node(n1).unwrap().add_node(n2).unwrap()
  assert_true(!graph.has_cycle())
}

///|
test "task graph: missing dependency returns error" {
  let n1 : TaskNode = {
    id: "t1",
    description: "Task 1",
    role: Executor,
    dependencies: ["nonexistent"],
  }
  let graph = TaskGraph::create().add_node(n1).unwrap()
  assert_true(graph.topological_order() is Err(_))
}

///|
test "task graph: self-loop cycle" {
  let n1 : TaskNode = {
    id: "t1",
    description: "Self-loop",
    role: Planner,
    dependencies: ["t1"],
  }
  let graph = TaskGraph::create().add_node(n1).unwrap()
  assert_true(graph.has_cycle())
}

///|
test "orchestrator session: create" {
  let orch = OrchestratorSession::create("orch1")
  assert_eq(orch.id, "orch1")
  assert_eq(orch.agent_count(), 0)
}

///|
test "orchestrator session: set task graph" {
  let n1 : TaskNode = {
    id: "t1",
    description: "Task 1",
    role: Planner,
    dependencies: [],
  }
  let graph = TaskGraph::create().add_node(n1).unwrap()
  let orch = OrchestratorSession::create("orch1").set_task_graph(graph)
  assert_eq(orch.task_graph.node_count(), 1)
}

///|
test "orchestrator session: bind session" {
  let orch = OrchestratorSession::create("orch1")
  let s = Session::create("s1").start().unwrap()
  let orch = orch.bind_session(Planner, s)
  assert_eq(orch.agent_count(), 1)
  assert_true(orch.has_agent(Planner))
  assert_true(!orch.has_agent(Executor))
}

///|
test "orchestrator session: bind session replaces existing" {
  let orch = OrchestratorSession::create("orch1")
  let s1 = Session::create("s1").start().unwrap()
  let orch = orch.bind_session(Planner, s1)
  let s2 = Session::create("s2").start().unwrap()
  let orch = orch.bind_session(Planner, s2)
  assert_eq(orch.agent_count(), 1)
  match orch.get_session(Planner) {
    Some(s) => assert_eq(s.id, "s2")
    None => assert_true(false)
  }
}

///|
test "orchestrator session: dispatch creates new session" {
  let orch = OrchestratorSession::create("orch1")
  let (orch, session) = orch.dispatch(Planner)
  assert_eq(orch.agent_count(), 1)
  assert_eq(session.id, "orch1/planner")
  assert_true(orch.has_agent(Planner))
}

///|
test "orchestrator session: dispatch returns existing session" {
  let orch = OrchestratorSession::create("orch1")
  let (orch, s1) = orch.dispatch(Planner)
  let (orch, s2) = orch.dispatch(Planner)
  assert_eq(orch.agent_count(), 1)
  assert_eq(s1.id, s2.id)
}

///|
test "orchestrator session: dispatch multiple roles" {
  let orch = OrchestratorSession::create("orch1")
  let (orch, p_sess) = orch.dispatch(Planner)
  let (orch, e_sess) = orch.dispatch(Executor)
  let (orch, r_sess) = orch.dispatch(Reviewer)
  assert_eq(orch.agent_count(), 3)
  assert_eq(p_sess.id, "orch1/planner")
  assert_eq(e_sess.id, "orch1/executor")
  assert_eq(r_sess.id, "orch1/reviewer")
}

///|
test "orchestrator session: get session" {
  let orch = OrchestratorSession::create("orch1")
  let (orch, _) = orch.dispatch(Executor)
  match orch.get_session(Executor) {
    Some(s) => assert_eq(s.id, "orch1/executor")
    None => assert_true(false)
  }
  match orch.get_session(Planner) {
    None => ()
    Some(_) => assert_true(false)
  }
}

///|
test "session snapshot: empty orchestrator" {
  let orch = OrchestratorSession::create("orch1")
  let snap = orch.snapshot()
  assert_eq(snap.session_id, "orch1")
  assert_eq(snap.state, "orchestrating")
  assert_eq(snap.agents.length(), 0)
  assert_eq(snap.tasks.length(), 0)
  assert_eq(snap.transitions.length(), 0)
}

///|
test "session snapshot: with agents" {
  let orch = OrchestratorSession::create("orch1")
  let (orch, _) = orch.dispatch(Planner)
  let (orch, _) = orch.dispatch(Executor)
  let snap = orch.snapshot()
  assert_eq(snap.agents.length(), 2)
  // Find planner agent
  let mut found_planner = false
  let mut found_executor = false
  let mut i = 0
  while i < snap.agents.length() {
    if snap.agents[i].role == "planner" {
      found_planner = true
      assert_eq(snap.agents[i].session_id, "orch1/planner")
      assert_eq(snap.agents[i].state, "idle")
    }
    if snap.agents[i].role == "executor" {
      found_executor = true
      assert_eq(snap.agents[i].session_id, "orch1/executor")
    }
    i = i + 1
  }
  assert_true(found_planner)
  assert_true(found_executor)
}

///|
test "session snapshot: with tasks" {
  let n1 : TaskNode = {
    id: "t1",
    description: "Plan the solution",
    role: Planner,
    dependencies: [],
  }
  let n2 : TaskNode = {
    id: "t2",
    description: "Execute the plan",
    role: Executor,
    dependencies: ["t1"],
  }
  let graph = TaskGraph::create().add_node(n1).unwrap().add_node(n2).unwrap()
  let orch = OrchestratorSession::create("orch1").set_task_graph(graph)
  let snap = orch.snapshot()
  assert_eq(snap.tasks.length(), 2)
  assert_eq(snap.tasks[0].id, "t1")
  assert_eq(snap.tasks[0].description, "Plan the solution")
  assert_eq(snap.tasks[0].role, "planner")
  assert_eq(snap.tasks[0].status, "pending")
  assert_eq(snap.tasks[0].dependencies.length(), 0)
  assert_eq(snap.tasks[1].id, "t2")
  assert_eq(snap.tasks[1].dependencies.length(), 1)
  assert_eq(snap.tasks[1].dependencies[0], "t1")
}

///|
test "session snapshot: to_json_string empty" {
  let orch = OrchestratorSession::create("orch1")
  let snap = orch.snapshot()
  let json = snap.to_json_string()
  let expected = "{\"session_id\":\"orch1\",\"state\":\"orchestrating\",\"agents\":[],\"tasks\":[],\"transitions\":[]}"
  assert_eq(json, expected)
}

///|
test "session snapshot: to_json_string with agents" {
  let orch = OrchestratorSession::create("orch1")
  let s = Session::create("orch1/planner").start().unwrap()
  let orch = orch.bind_session(Planner, s)
  let snap = orch.snapshot()
  let json = snap.to_json_string()
  let expected = "{\"session_id\":\"orch1\",\"state\":\"orchestrating\",\"agents\":[{\"role\":\"planner\",\"session_id\":\"orch1/planner\",\"state\":\"running\"}],\"tasks\":[],\"transitions\":[]}"
  assert_eq(json, expected)
}

///|
test "session snapshot: to_json_string with agents and tasks" {
  let n1 : TaskNode = {
    id: "t1",
    description: "Plan",
    role: Planner,
    dependencies: [],
  }
  let n2 : TaskNode = {
    id: "t2",
    description: "Execute",
    role: Executor,
    dependencies: ["t1"],
  }
  let graph = TaskGraph::create().add_node(n1).unwrap().add_node(n2).unwrap()
  let orch = OrchestratorSession::create("orch1").set_task_graph(graph)
  let s = Session::create("orch1/planner").start().unwrap()
  let orch = orch.bind_session(Planner, s)
  let snap = orch.snapshot()
  let json = snap.to_json_string()
  let expected = "{\"session_id\":\"orch1\",\"state\":\"orchestrating\",\"agents\":[{\"role\":\"planner\",\"session_id\":\"orch1/planner\",\"state\":\"running\"}],\"tasks\":[{\"id\":\"t1\",\"description\":\"Plan\",\"role\":\"planner\",\"dependencies\":[],\"status\":\"pending\"},{\"id\":\"t2\",\"description\":\"Execute\",\"role\":\"executor\",\"dependencies\":[\"t1\"],\"status\":\"pending\"}],\"transitions\":[]}"
  assert_eq(json, expected)
}

///|
test "session snapshot: to_json_string deterministic across replays" {
  let n1 : TaskNode = {
    id: "t1",
    description: "Plan",
    role: Planner,
    dependencies: [],
  }
  let graph = TaskGraph::create().add_node(n1).unwrap()
  let orch1 = OrchestratorSession::create("orch1").set_task_graph(graph)
  let snap1 = orch1.snapshot()
  let json1 = snap1.to_json_string()

  let orch2 = OrchestratorSession::create("orch1").set_task_graph(
    TaskGraph::create().add_node(n1).unwrap(),
  )
  let snap2 = orch2.snapshot()
  let json2 = snap2.to_json_string()

  assert_eq(json1, json2)
}

///|
test "session snapshot: round-trip via from_json" {
  let orch = OrchestratorSession::create("orch1")
  let s = Session::create("orch1/planner").start().unwrap()
  let n1 : TaskNode = {
    id: "t1",
    description: "Plan",
    role: Planner,
    dependencies: [],
  }
  let graph = TaskGraph::create().add_node(n1).unwrap()
  let orch = orch.bind_session(Planner, s).set_task_graph(graph)
  let snap = orch.snapshot()
  let json = snap.to_json_string()
  let parsed = session_snapshot_from_json(json)
  match parsed {
    Some(restored) => {
      assert_eq(restored.session_id, "orch1")
      assert_eq(restored.state, "orchestrating")
      assert_eq(restored.agents.length(), 1)
      assert_eq(restored.tasks.length(), 1)
    }
    None => assert_true(false)
  }
}

///|
test "session snapshot: from_json on empty snapshot" {
  let json = "{\"session_id\":\"orch1\",\"state\":\"orchestrating\",\"agents\":[],\"tasks\":[],\"transitions\":[]}"
  let parsed = session_snapshot_from_json(json)
  match parsed {
    Some(snap) => {
      assert_eq(snap.session_id, "orch1")
      assert_eq(snap.agents.length(), 0)
      assert_eq(snap.tasks.length(), 0)
      assert_eq(snap.transitions.length(), 0)
    }
    None => assert_true(false)
  }
}

///|
test "agent entry struct equality" {
  let a1 : AgentEntry = { role: "planner", session_id: "s1", state: "idle" }
  let a2 : AgentEntry = { role: "planner", session_id: "s1", state: "idle" }
  let a3 : AgentEntry = { role: "executor", session_id: "s1", state: "idle" }
  assert_true(a1 == a2)
  assert_true(a1 != a3)
}

///|
test "agent entry to_json" {
  let a : AgentEntry = { role: "planner", session_id: "s1", state: "idle" }
  assert_eq(
    a.to_json(),
    "{\"role\":\"planner\",\"session_id\":\"s1\",\"state\":\"idle\"}",
  )
}

///|
test "task snapshot to_json" {
  let t : TaskSnapshot = {
    id: "t1",
    description: "Plan",
    role: "planner",
    dependencies: [],
    status: "pending",
  }
  assert_eq(
    t.to_json(),
    "{\"id\":\"t1\",\"description\":\"Plan\",\"role\":\"planner\",\"dependencies\":[],\"status\":\"pending\"}",
  )
}

///|
test "task snapshot to_json with dependencies" {
  let t : TaskSnapshot = {
    id: "t2",
    description: "Execute",
    role: "executor",
    dependencies: ["t1"],
    status: "pending",
  }
  assert_eq(
    t.to_json(),
    "{\"id\":\"t2\",\"description\":\"Execute\",\"role\":\"executor\",\"dependencies\":[\"t1\"],\"status\":\"pending\"}",
  )
}

///|
test "transition entry to_json" {
  let t : TransitionEntry = {
    from: "t1",
    to: "t2",
    reason: "dependency satisfied",
  }
  assert_eq(
    t.to_json(),
    "{\"from\":\"t1\",\"to\":\"t2\",\"reason\":\"dependency satisfied\"}",
  )
}

///|
test "task graph: all_nodes returns all nodes" {
  let n1 : TaskNode = {
    id: "t1",
    description: "Task 1",
    role: Planner,
    dependencies: [],
  }
  let n2 : TaskNode = {
    id: "t2",
    description: "Task 2",
    role: Executor,
    dependencies: ["t1"],
  }
  let graph = TaskGraph::create().add_node(n1).unwrap().add_node(n2).unwrap()
  let nodes = graph.all_nodes()
  assert_eq(nodes.length(), 2)
}

///|
test "full orchestrator workflow: planner -> executor -> reviewer" {
  // Build a task graph
  let plan : TaskNode = {
    id: "plan",
    description: "Plan the approach",
    role: Planner,
    dependencies: [],
  }
  let execute : TaskNode = {
    id: "execute",
    description: "Execute the plan",
    role: Executor,
    dependencies: ["plan"],
  }
  let review : TaskNode = {
    id: "review",
    description: "Review the result",
    role: Reviewer,
    dependencies: ["execute"],
  }
  let graph = TaskGraph::create()
    .add_node(plan)
    .unwrap()
    .add_node(execute)
    .unwrap()
    .add_node(review)
    .unwrap()

  // Verify graph structure
  assert_eq(graph.node_count(), 3)
  assert_true(!graph.has_cycle())
  let order = graph.topological_order().unwrap()
  assert_eq(order.length(), 3)
  assert_eq(order[0].id, "plan")
  assert_eq(order[1].id, "execute")
  assert_eq(order[2].id, "review")

  // Create orchestrator session
  let orch = OrchestratorSession::create("workflow1").set_task_graph(graph)

  // Dispatch sessions for each role
  let (orch, planner_sess) = orch.dispatch(Planner)
  let planner_sess = planner_sess.start().unwrap()
  let planner_sess = planner_sess
    .send_user_message("Plan the solution")
    .unwrap()
    .receive_assistant_message("Here is the plan")
    .unwrap()

  // Bind updated planner session
  let orch = orch.bind_session(Planner, planner_sess)

  let (orch, executor_sess) = orch.dispatch(Executor)
  let executor_sess = executor_sess.start().unwrap()

  let orch = orch.bind_session(Executor, executor_sess)

  let (orch, reviewer_sess) = orch.dispatch(Reviewer)
  let orch = orch.bind_session(Reviewer, reviewer_sess)

  // Verify all agents registered
  assert_eq(orch.agent_count(), 3)
  assert_true(orch.has_agent(Planner))
  assert_true(orch.has_agent(Executor))
  assert_true(orch.has_agent(Reviewer))

  // Take snapshot and serialize
  let snap = orch.snapshot()
  assert_eq(snap.session_id, "workflow1")
  assert_eq(snap.agents.length(), 3)
  assert_eq(snap.tasks.length(), 3)
  assert_eq(snap.transitions.length(), 0)

  let json = snap.to_json_string()
  // Round-trip
  let parsed = session_snapshot_from_json(json)
  match parsed {
    Some(restored) => {
      assert_eq(restored.session_id, "workflow1")
      assert_eq(restored.tasks.length(), 3)
      assert_eq(restored.agents.length(), 3)
    }
    None => assert_true(false)
  }
}
