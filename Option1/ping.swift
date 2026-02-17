import Alamofire
import SwiftyJSON

private var lastPingTime: Int32 = 0
private var isPingInProgress = false

func ping() {
    Task { @MainActor in
        if isPingInProgress {
            reportLog("ping() isPingInProgress")
            return
        }
        if (lastPingTime + 4 * 3_600) > time() {
            reportLog("ping() lastPingTime \(lastPingTime)")
            return
        }
        reportLog("ping()")
        let parameters: [String: String] = [
            "token": KvDb.getTokenOrNil() ?? "",
            "build": SystemInfo.getBuildOrNil().map { "\($0)" } ?? "",
            "device": SystemInfo.getModelIdentifierOrNil() ?? "",
            "os": SystemInfo.getOsVersion(),
        ]
        isPingInProgress = true
        _ = AF.request(
            "https://api.option1.io/ping",
            method: .get,
            parameters: parameters,
        ).responseString { response in
            switch response.result {
            case .success(let jString):
                guard let jData = jString.data(using: .utf8, allowLossyConversion: false) else {
                    reportApi("ping() .success invalid data:\(jString)")
                    break
                }
                guard let j = try? JSON(data: jData) else {
                    reportApi("ping() .success invalid json:\(jString)")
                    break
                }
                if j["status"] != "success" {
                    reportApi("ping() .success not success:\(jString)")
                    break
                }
                guard let token: String = j["data"]["token"].string else {
                    reportApi("ping() .success no token:\(jString)")
                    break
                }
                Task { @MainActor in
                    KvDb.upsertToken(token)
                    lastPingTime = time()
                }
            case let .failure(error):
                reportApi("ping() failure:\(error)")
            }
            isPingInProgress = false
        }
    }
}
