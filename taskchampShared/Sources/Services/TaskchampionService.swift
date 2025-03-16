import Taskchampion

public func printAnExample() -> String {
    print("hello uuid", Taskchampion.uuid_v4())
    let replica = Taskchampion.new_replica_in_memory()
    var tasks = replica.all_task_data()!
    print("LENTH", tasks.len())

    var ops = Taskchampion.new_operations()
    print("LENGTH", ops.len())
    ops = Taskchampion.create_task(Taskchampion.uuid_v4(), ops)
    print("LENGTH", ops.len())

    replica.commit_operations(ops)
    tasks = replica.all_task_data()!
    let task = tasks.first
    print("HERE", task)
    print("LENTH", tasks.len())

    return "hello!"
}
