import Alamofire

func reportApi(_ message: String) {
    print(message)
    let parameters: [String: String] = [
        "message": message,
    ]
    _ = AF.request(
        "https://api.timeto.me/option1/report",
        method: .post,
        parameters: parameters
    ).responseString { _ in }
}
