import SwiftUI

struct DonationsTab: View {
    
    @State private var transactionIdForm = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                AppText("Option1 is 100% free and open source. I only ask for donations.")

                AppText("Please donate any amount here [https://buymeacoffee.com/medvedev91](https://buymeacoffee.com/medvedev91)\nand enter the transaction ID to hide donation notifications.")
                
                AppText("One donation for lifetime app usage.")
                
                HStack {
                    
                    Text("Transaction ID")
                        .font(.system(size: AppText.FONT_SIZE))
                    
                    TextField("", text: $transactionIdForm)
                        .autocorrectionDisabled()
                        .frame(width: 180)
                    
                    Button("Activate") {
                    }
                    
                    Spacer()
                }
            }
            .padding()
        }
        .navigationTitle("Donations")
    }
}
