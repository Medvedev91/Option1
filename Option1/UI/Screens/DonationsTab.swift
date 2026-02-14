import SwiftUI

struct DonationsTab: View {
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                AppText("Option1 is 100% free and open source. I only ask for donations.")

                AppText("Please donate any amount here [https://buymeacoffee.com/medvedev91](https://buymeacoffee.com/medvedev91)\nand enter the transaction ID to hide donation notifications.")
                
                AppText("One donation for lifetime usage of the app.")
                
                HStack {
                    Spacer()
                }
            }
            .padding()
        }
        .navigationTitle("Donations")
    }
}
