import SwiftUI

struct AppText: View {
    
    static let FONT_SIZE: CGFloat = 14
    
    ///
    
    private let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(try! AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace),
        ))
        .font(.system(size: AppText.FONT_SIZE))
        .lineSpacing(4)
        .textAlign(.leading)
        .frame(maxWidth: 650)
    }
}
