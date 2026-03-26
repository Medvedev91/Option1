import SwiftyJSON

class Backup {
    
    @MainActor
    static func prepareBackup() -> String {
        AppDb.cleanRemoved()
        let j = JSON([
            "time": time(),
            "build": SystemInfo.getBuildOrNil() ?? 0,
            "apps": AppDb.selectAll().map { appDb in
                [
                    "bundle": appDb.bundle,
                    "name": appDb.name,
                ]
            },
            "kv": KvDb.selectAll().map { kvDb in
                [
                    "key": kvDb.key,
                    "value": kvDb.value,
                ]
            },
            "workspaces": WorkspaceDb.selectAll().map { workspaceDb in
                [
                    "id": workspaceDb.id.uuidString,
                    "name": workspaceDb.name,
                    "time": Int(workspaceDb.date.timeIntervalSince1970),
                    "sort": workspaceDb.sort,
                ]
            },
            "binds": BindDb.selectAll().map { bindDb in
                [
                    "id": bindDb.id.uuidString,
                    "key": bindDb.key,
                    "workspace_id": bindDb.workspaceId?.uuidString,
                    "bundle": bindDb.bundle,
                    "substring": bindDb.substring,
                ]
            },
        ])
        return j.rawString(options: .withoutEscapingSlashes)!
    }
}
