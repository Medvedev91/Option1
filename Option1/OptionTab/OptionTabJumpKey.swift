import AppKit
import HotKey

struct OptionTabJumpKey: Hashable {
    
    let key: Key
    let text: String
    let modifiers: NSEvent.ModifierFlags
    
    init(
        key: Key,
        modifiers: NSEvent.ModifierFlags,
    ) {
        self.key = key
        self.text = (modifiers.contains(.shift) ? "^" : "") + key.description.uppercased()
        self.modifiers = modifiers
    }
    
    //
    // Hashable
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(text)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.text == rhs.text
    }
}
