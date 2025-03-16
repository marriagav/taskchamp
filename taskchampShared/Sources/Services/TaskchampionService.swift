// import taskchampion
// import Taskchampion
// TODO: THIS WHOLE FILE
import Taskchampion
public func printAnExample() -> String {
//    var replica = taskchampion.tc.new_replica_in_memory()
//    let task = taskchampion.tc.get_all_task_data(&replica)
//    print("task", task)
//    return "HELLO \(taskchampion.tc.Uuid())"
//    test.printAnExample()
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
