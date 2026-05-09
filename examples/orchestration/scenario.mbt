///|
pub fn fizzbuzz_scenario() -> @orbit.OrchestratorSession {
  let t0 : @orbit.TaskNode = {
    id: "t0",
    description: "decompose",
    role: @orbit.Planner,
    dependencies: [],
  }
  let t1 : @orbit.TaskNode = {
    id: "t1",
    description: "write fizzbuzz",
    role: @orbit.Executor,
    dependencies: ["t0"],
  }
  let t2 : @orbit.TaskNode = {
    id: "t2",
    description: "write tests",
    role: @orbit.Executor,
    dependencies: ["t0"],
  }
  let t3 : @orbit.TaskNode = {
    id: "t3",
    description: "run tests",
    role: @orbit.Executor,
    dependencies: ["t1", "t2"],
  }
  let t4 : @orbit.TaskNode = {
    id: "t4",
    description: "review final",
    role: @orbit.Reviewer,
    dependencies: ["t3"],
  }
  let graph = @orbit.TaskGraph::create()
    .add_node(t0)
    .unwrap()
    .add_node(t1)
    .unwrap()
    .add_node(t2)
    .unwrap()
    .add_node(t3)
    .unwrap()
    .add_node(t4)
    .unwrap()
  @orbit.OrchestratorSession::create("fizzbuzz-demo").set_task_graph(graph)
}

///|
pub fn run_scenario(
  orch : @orbit.OrchestratorSession,
) -> Array[@orbit.SessionSnapshot] {
  let order = orch.task_graph.topological_order().unwrap()
  let snapshots : Array[@orbit.SessionSnapshot] = []
  let mut orch = orch
  let mut i = 0
  while i < order.length() {
    let task = order[i]
    let (o, session) = orch.dispatch(task.role)
    orch = o
    let session = session.start().unwrap()
    let session = session
      .send_user_message("Task: " + task.description)
      .unwrap()
      .receive_assistant_message("Completed: " + task.description)
      .unwrap()
    let session = session.end().unwrap()
    orch = orch.bind_session(task.role, session)
    snapshots.push(orch.snapshot())
    i = i + 1
  }
  snapshots
}
