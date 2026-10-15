import SwiftUI

struct IvanView : View {
    
    let imageSize: CGFloat
    let fontWeight: Font.Weight
    
    var body: some View {
        HStack {
            
            Image("my_photo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: imageSize, height: imageSize)
                .clipShape(RoundedRectangle(cornerRadius: 99))
            
            Text(try! AttributedString(
                markdown: "Wish you all the best,\n[Ivan](https://github.com/Medvedev91)",
                options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace),
            ))
            .font(.system(size: AppText.FONT_SIZE, weight: fontWeight))
            .lineSpacing(2)
            .textAlign(.leading)
            .padding(.leading, 6)
        }
    }
}
