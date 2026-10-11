import SwiftUI

struct IvanView : View {
    
    var body: some View {
        HStack {
            
            Image("my_photo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 99))
            
            Text(try! AttributedString(
                markdown: "**Wish you all the best,**\n**[Ivan](https://github.com/Medvedev91)**",
                options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace),
            ))
            .font(.system(size: AppText.FONT_SIZE))
            .lineSpacing(2)
            .textAlign(.leading)
            .padding(.leading, 8)
        }
    }
}
