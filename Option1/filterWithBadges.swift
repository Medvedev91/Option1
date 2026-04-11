extension [CachedWindow] {
    
    @MainActor
    func filterWithBadges(enabled: Bool) -> [CachedWindow] {
        let bundles: [String] = BadgesManager.instance.dictionary.map(\.key);
        return !enabled ? self : filter { bundles.contains($0.appBundle) }
    }
}
