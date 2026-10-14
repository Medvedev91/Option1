import SwiftUI

struct AppText: View {
    
    static let FONT_SIZE: CGFloat = 14
    static let MAX_WIDTH: CGFloat = 650
    
    ///
    
    private let text: String
    private let highlighted: [String]
    
    init(_ text: String, highlighted: [String] = []) {
        self.text = text
        self.highlighted = highlighted
    }
    
    var body: some View {
        Text(attributedText(text, highlighted: highlighted))
            .font(.system(size: AppText.FONT_SIZE))
            .lineSpacing(4)
            .textAlign(.leading)
            .frame(maxWidth: AppText.MAX_WIDTH)
    }
    
    private func attributedText(_ text: String, highlighted: [String]) -> AttributedString {
        var attributedString = try! AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace),
        )
        
        highlighted.forEach { hItem in
            if let range = attributedString.range(of: hItem) {
                attributedString[range].backgroundColor = Color(.init(gray: 0.5, alpha: 0.2))
            }
        }
        
        return attributedString
    }
}
