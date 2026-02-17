import SwiftUI
import Alamofire
import SwiftyJSON

struct DonationsTab: View {
    
    @State private var isActivated = false
    @State private var isActivationRequestInProgress = false
    @State private var transactionIdForm = ""
    
    @State private var isErrorPresented = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                AppText("Option1 is 100% free and open source. I only ask for donations.")
                
                AppText("Please donate any amount here [https://buymeacoffee.com/medvedev91](https://buymeacoffee.com/medvedev91)\nand enter the transaction ID to hide donation notifications.")
                
                HStack {
                    
                    if isActivated {
                        AppText("Activated")
                            .foregroundColor(.green)
                    } else {
                        
                        Text("Transaction ID")
                            .font(.system(size: AppText.FONT_SIZE))
                        
                        TextField("...", text: $transactionIdForm)
                            .autocorrectionDisabled()
                            .frame(width: 150)
                        
                        Button("Activate") {
                            activationRequest()
                        }
                        .disabled(isActivationRequestInProgress || transactionIdForm.isEmpty)
                    }
                    
                    Spacer()
                }
                
                AppText("One donation for lifetime app usage.")
            }
            .padding()
            .alert(
                "Error",
                isPresented: $isErrorPresented,
                actions: {},
                message: { Text(errorMessage) },
            )
        }
        .navigationTitle("Donations")
        .onAppear {
            if KvDb.selectActivationTransactionIdOrNil() != nil {
                isActivated = true
            }
        }
    }
    
    private func showAlertError(_ message: String) {
        errorMessage = message
        isErrorPresented = true
    }
    
    private func activationRequest() {
        withAnimation {
            isActivationRequestInProgress = true
        }
        
        let parameters: [String: String] = [
            "token": KvDb.getTokenOrNil() ?? "",
            "transaction_id": transactionIdForm,
        ]
        _ = AF.request(
            "https://api.option1.io/activate",
            method: .get,
            parameters: parameters,
        ).responseString { response in
            switch response.result {
            case .success(let jString):
                guard let jData = jString.data(using: .utf8, allowLossyConversion: false) else {
                    showAlertError("Request error")
                    reportApi("activationRequest() .success invalid data:\(jString)")
                    break
                }
                guard let j = try? JSON(data: jData) else {
                    showAlertError("Request error")
                    reportApi("activationRequest() .success invalid json:\(jString)")
                    break
                }
                let status = j["status"].string
                if status == "error" {
                    showAlertError(j["message"].stringValue)
                    reportApi("activationRequest() .success error:\(jString)")
                    break
                }
                if status != "success" {
                    showAlertError("Request error, please contact us.")
                    reportApi("activationRequest() .success not success:\(jString)")
                    break
                }
                guard let transactionId: String = j["data"]["transaction_id"].string else {
                    reportApi("activationRequest() .success no transaction_id:\(jString)")
                    break
                }
                Task { @MainActor in
                    KvDb.upsertActivationTransactionId(transactionId)
                    isActivated = true
                }
            case let .failure(error):
                showAlertError("Request error")
                reportApi("activationRequest() failure:\(error)")
            }
            isActivationRequestInProgress = false
        }
    }
}
