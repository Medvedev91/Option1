import Foundation

func timeMls() -> Int64 {
    Int64(NSDate().timeIntervalSince1970 * 1_000)
}
