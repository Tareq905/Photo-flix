import UIKit

class HomeVC: UIViewController {
    
    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet var buttons: [UIButton]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        // app verison lable update
        appVersionLabel.text = "Version \(getAppVersion() ?? "0.0")"
        
        // corner radius to buttons
        for element in buttons {
            element.layer.cornerRadius = 15
        }
    }
}
