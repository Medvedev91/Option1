import Combine

class DonationsAlertUtils: ObservableObject {
    
    @Published var needToShow = false
    
    ///
    
    static let instance = DonationsAlertUtils()
    
    @MainActor
    static func checkUp() -> Bool {
        let isNeedToShow = calcIsNeedToShow()
        if isNeedToShow {
            DonationsAlertUtils.instance.needToShow = true
        }
        return isNeedToShow
    }
}

@MainActor
private func calcIsNeedToShow() -> Bool {
    let now = time()
    let weekTime = 3_600 * 24 * 7
    
    if (launchTime + 3_600) > now {
        return false
    }
    
    if KvDb.selectActivationTransactionIdOrNil() != nil {
        return false
    }
    
    if let donationsLastAlertTime = KvDb.selectDonationsLastAlertTimeOrNil() {
        return (donationsLastAlertTime + weekTime) < now
    }
    
    return (KvDb.selectOrInsertInitTime() + weekTime) < now
}
