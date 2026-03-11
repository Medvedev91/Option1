import Foundation

private let fileManager = FileManager.default

func isFileExists(_ path: String) -> Bool {
    path.first == "/" && fileManager.fileExists(atPath: path)
}
