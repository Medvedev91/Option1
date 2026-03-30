import Foundation
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
            "option-tab-pins": OptionTabPinDb.selectAll().map { optionTabPinDb in
                [
                    "bundle": optionTabPinDb.bundle,
                    "sort": optionTabPinDb.sort,
                ]
            },
        ])
        return j.rawString(options: .withoutEscapingSlashes)!
    }
    
    @MainActor
    static func restore(jString: String) throws(AppError) {
        MenuBarManager.instance.setWorkspaceDb(nil)
        
        let j = JSON(parseJSON: jString)
        
        guard let jApps = j["apps"].array else { throw AppError.simple("Json Error") }
        guard let jKv = j["kv"].array else { throw AppError.simple("Json Error") }
        guard let jWorkspaces = j["workspaces"].array else { throw AppError.simple("Json Error") }
        guard let jBinds = j["binds"].array else { throw AppError.simple("Json Error") }
        guard let jOptionTabPins = j["option-tab-pins"].array else { throw AppError.simple("Json Error") }
        
        for jApp in jApps {
            guard let bundle: String = jApp["bundle"].string else { throw AppError.simple("Json Error") }
            guard let name: String = jApp["name"].string else { throw AppError.simple("Json Error") }
            AppDb.upsertRaw(bundle: bundle, name: name)
        }
        
        do {
            // Kv
            KvDb.deleteAll_ForTransaction()
            for jKv in jKv {
                guard let key: String = jKv["key"].string else { throw AppError.simple("Json Error") }
                guard let value: String = jKv["value"].string else { throw AppError.simple("Json Error") }
                KvDb.insert_ForTransaction(key: key, value: value)
            }
            // Workspaces
            WorkspaceDb.deleteAll_ForTransaction()
            for jWorkspace in jWorkspaces {
                guard let uuidString: String = jWorkspace["id"].string else { throw AppError.simple("Json Error") }
                guard let id = UUID(uuidString: uuidString) else { throw AppError.simple("Json UUID Error") }
                guard let name: String = jWorkspace["name"].string else { throw AppError.simple("Json Error") }
                guard let time: Int = jWorkspace["time"].int else { throw AppError.simple("Json Error") }
                guard let sort: Int = jWorkspace["sort"].int else { throw AppError.simple("Json Error") }
                WorkspaceDb.insert_ForTransaction(
                    id: id,
                    name: name,
                    date: Date(timeIntervalSince1970: TimeInterval(time)),
                    sort: sort,
                )
            }
            // Binds
            BindDb.deleteAll_ForTransaction()
            for jBind in jBinds {
                guard let uuidString: String = jBind["id"].string else { throw AppError.simple("Json Error") }
                guard let id = UUID(uuidString: uuidString) else { throw AppError.simple("Json UUID Error") }
                guard let key: String = jBind["key"].string else { throw AppError.simple("Json Error") }
                let workspaceUuidString: String? = jBind["workspace_id"].string
                let workspaceId: UUID? = workspaceUuidString.map { UUID(uuidString: $0) } ?? nil
                guard let bundle: String = jBind["bundle"].string else { throw AppError.simple("Json Error") }
                guard let substring: String = jBind["substring"].string else { throw AppError.simple("Json Error") }
                BindDb.insert_ForTransaction(
                    id: id,
                    key: key,
                    workspaceId: workspaceId,
                    bundle: bundle,
                    substring: substring,
                )
            }
            // Option-Tab Pins
            OptionTabPinDb.deleteAll_ForTransaction()
            for jOptionTabPin in jOptionTabPins {
                guard let bundle: String = jOptionTabPin["bundle"].string else { throw AppError.simple("Json Error") }
                guard let sort: Int = jOptionTabPin["sort"].int else { throw AppError.simple("Json Error") }
                OptionTabPinDb.insert_ForTransaction(bundle: bundle, sort: sort)
            }
            DB.save()
        } catch AppError.simple(let message) {
            DB.rollback()
            throw AppError.simple(message)
        } catch {
            DB.rollback()
            throw AppError.simple("Error")
        }
    }
}
