import Alamofire

func reportApi(_ message: String) {
    reportLog("reportApi() \(message)")
    let parameters: [String: String] = [
        "message": message,
        "model": getModelIdentifier() ?? "",
        "os": getOsVersion(),
    ]
    _ = AF.request(
        "https://api.option1.io/report",
        method: .post,
        parameters: parameters
    ).responseString { _ in }
}
