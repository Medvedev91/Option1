import SwiftUI

struct AppText: View {
    
    private let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(try! AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace),
        ))
        .font(.system(size: 14))
        .lineSpacing(4)
        .textAlign(.leading)
        .frame(maxWidth: 650)
    }
}
