import SwiftData

let dbContainer: ModelContainer = {
    let schema = Schema([KvDb.self, WorkspaceDb.self])
    return try! ModelContainer(for: schema, configurations: [])
}()
