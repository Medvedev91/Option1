import SwiftUI
import Alamofire
import SwiftyJSON

struct DonationsTab: View {
    
    @State private var isActivated = false
    @State private var isActivationRequestInProgress = false
    @State private var emailForm = ""
    
    @State private var isErrorPresented = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                AppText("Option1 is 100% free and open source. I only ask for donations.")
                
                AppText("Please donate any amount here [https://buymeacoffee.com/medvedev91](https://buymeacoffee.com/medvedev91)\nand enter the supporter's email to hide donation notifications.")
                
                AppText("One donation for lifetime app usage.")
                
                HStack {
                    
                    if isActivated {
                        AppText("Activated")
                            .foregroundColor(.green)
                    } else {
                        
                        TextField("Email", text: $emailForm)
                            .autocorrectionDisabled()
                            .frame(width: 150)
                        
                        Button("Activate") {
                            activationRequest()
                        }
                        .disabled(isActivationRequestInProgress || emailForm.isEmpty)
                    }
                    
                    Spacer()
                }
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
            if KvDb.selectActivationEmailOrNil() != nil {
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
            "token": KvDb.selectTokenOrNil() ?? "",
            "email": emailForm,
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
                guard let email: String = j["data"]["email"].string else {
                    reportApi("activationRequest() .success no email:\(jString)")
                    break
                }
                Task { @MainActor in
                    KvDb.upsertActivationEmail(email)
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
