
    import UIKit

    class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
        @IBOutlet weak var filterTable: UITableView!
        @IBOutlet weak var filterInput: UITextField!
        @IBOutlet weak var addButton: UIButton!
        @IBOutlet weak var filterTypeSegment: UISegmentedControl!
        
        @IBOutlet weak var keywordSwitch: UISwitch!
        @IBOutlet weak var aiSwitch: UISwitch!
        
        
        var userFilters: [String] = []
        var defaultFilters: [String] = []
        var isUserFilterSelected = false

        override func viewDidLoad() {
            super.viewDidLoad()
            filterTable.delegate = self
            filterTable.dataSource = self
            filterInput.delegate = self   // Klavye Return tuşunu dinlemek için
            
            
            let defaults = UserDefaults(suiteName: "group.com.AlperrD.smsfilter")
            let logs = defaults?.stringArray(forKey: "Logs") ?? []
            print(logs.joined(separator: "\n"))
            
            updateSwitches()
            
            loadFilters()
            
            // Klavye açılış / kapanış bildirimleri
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(keyboardWillShow(notification:)),
                                                   name: UIResponder.keyboardWillShowNotification,
                                                   object: nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(keyboardWillHide(notification:)),
                                                   name: UIResponder.keyboardWillHideNotification,
                                                   object: nil)
        }

        func loadFilters() {
            userFilters = FilterManager.shared.loadUserFilters()
            defaultFilters = FilterManager.shared.loadDefaultFilters()
            filterTable.reloadData()
        }

        @IBAction func addFilterTapped(_ sender: UIButton) {
            guard let word = filterInput.text?.trimmingCharacters(in: .whitespaces), !word.isEmpty else { return }
            if isUserFilterSelected {
                userFilters.append(word)
                FilterManager.shared.saveUserFilters(userFilters)
            } else {
                defaultFilters.append(word)
                FilterManager.shared.saveDefaultFilters(defaultFilters)
            }
            filterInput.text = ""
            filterTable.reloadData()
            let defaults = UserDefaults(suiteName: "group.com.AlperrD.smsfilter")
            let logs = defaults?.stringArray(forKey: "Logs") ?? []
            print(logs.joined(separator: "\n"))
        }

        @IBAction func filterTypeChanged(_ sender: UISegmentedControl) {
            isUserFilterSelected = (sender.selectedSegmentIndex == 1)
            filterTable.reloadData()
        }
        // switch kontrol
        private func updateSwitches() {
            // Mevcut tercih durumlarını yükleyin ve switch'leri ayarlayın
            aiSwitch.isOn = FilterManager.shared.shouldUseAI()
            keywordSwitch.isOn = FilterManager.shared.shouldUseKeywordFilter()
        }
        
        @IBAction func aiSwitchChanged(_ sender: UISwitch) {
            let aiEnabled = sender.isOn
            
            // Eğer AI kapatılmak istenirse ve kelime filtresi de kapalıysa, bunun kapatılmasına izin vermeyen kısım
            if !aiEnabled && !FilterManager.shared.shouldUseKeywordFilter() {
                aiSwitch.setOn(true, animated: true) // Kullanıcıyı engelle ve tekrar aç
                return
            }
            
            FilterManager.shared.setUseAI(aiEnabled)
        }
        
        @IBAction func keywordSwitchChanged(_ sender: UISwitch) {
            let keywordFilterEnabled = sender.isOn
            
            // Eğer kelime filtresi kapatılmak istenirse ve AI de kapalıysa, bunun kapatılmasına izin vermeyen kısım.
            if !keywordFilterEnabled && !FilterManager.shared.shouldUseAI() {
                keywordSwitch.setOn(true, animated: true) // Kullanıcıyı engelle ve tekrar aç
                return
            }
            
            FilterManager.shared.setUseKeywordFilter(keywordFilterEnabled)
        }

        // TableView DataSource
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return isUserFilterSelected ? userFilters.count : defaultFilters.count
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FilterCell", for: indexPath)
            cell.textLabel?.text = isUserFilterSelected ? userFilters[indexPath.row] : defaultFilters[indexPath.row]
            return cell
        }

        // Silme işlemi
        func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                       forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                if isUserFilterSelected {
                    userFilters.remove(at: indexPath.row)
                    FilterManager.shared.saveUserFilters(userFilters)
                } else {
                    defaultFilters.remove(at: indexPath.row)
                    FilterManager.shared.saveDefaultFilters(defaultFilters)
                }
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
        
        // Filtre düzenleme için satıra dokunma işlemi
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            
            let currentWord = isUserFilterSelected ? userFilters[indexPath.row] : defaultFilters[indexPath.row]
            
            let alert = UIAlertController(title: "Filtreyi Düzenle", message: nil, preferredStyle: .alert)
            alert.addTextField { textField in
                textField.text = currentWord
            }
            
            alert.addAction(UIAlertAction(title: "Kaydet", style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                guard let newText = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespaces),
                      !newText.isEmpty else { return }
                
                if self.isUserFilterSelected {
                    self.userFilters[indexPath.row] = newText
                    FilterManager.shared.saveUserFilters(self.userFilters)
                } else {
                    self.defaultFilters[indexPath.row] = newText
                    FilterManager.shared.saveDefaultFilters(self.defaultFilters)
                }
                
                self.filterTable.reloadRows(at: [indexPath], with: .automatic)
            }))
            
            alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
            
            present(alert, animated: true)
        }
        
        // MARK: - Klavye yönetimi
        
        @objc func keyboardWillShow(notification: Notification) {
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                let keyboardHeight = keyboardFrame.height
                
                // Eğer view yukarı kaymamışsa kaydır
                if self.view.frame.origin.y == 0 {
                    self.view.frame.origin.y -= keyboardHeight / 2
                }
            }
        }

        @objc func keyboardWillHide(notification: Notification) {
            if self.view.frame.origin.y != 0 {
                self.view.frame.origin.y = 0
            }
        }
        
        // Return tuşuna basılınca klavyeyi kapatma
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()  // Klavyeyi kapatır
            return true
        }
        
        // Eğer başka yerde (dışarıya) dokunulduğunda da klavye kapatma.
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            self.view.endEditing(true)
        }
        
        
    }
