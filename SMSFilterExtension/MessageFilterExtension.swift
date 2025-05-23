import IdentityLookup
import OSLog

final class MessageFilterExtension: ILMessageFilterExtension {
    private let appGroupIdentifier = "group.com.AlperrD.smsfilter"
    private let defaultSpamKeywords = [
        "kumar", "bahis", "casino", "jackpot", "bet", "slot", "piyango"
    ]
}

extension MessageFilterExtension: ILMessageFilterQueryHandling {
    func handle(_ queryRequest: ILMessageFilterQueryRequest,
                context: ILMessageFilterExtensionContext,
                completion: @escaping (ILMessageFilterQueryResponse) -> Void) {
        
        os_log("SMS Filter Extension başladı", log: OSLog.smsFilter, type: .debug)
        
        let response = ILMessageFilterQueryResponse()
        
        // Mesaj kontrolü
        guard let messageBody = queryRequest.messageBody, !messageBody.isEmpty else {
            os_log("Mesaj boş", log: OSLog.smsFilter, type: .info)
            response.action = .none
            completion(response)
            return
        }
        
        // UserDefaults kontrolü
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            os_log("UserDefaults erişilemedi", log: OSLog.smsFilter, type: .error)
            response.action = .none
            completion(response)
            return
        }
        
        // Filtre ayarlarını al
        let useAI = defaults.bool(forKey: "UseAI")
        let useKeywordFilter = defaults.bool(forKey: "UseKeywordFilter")
        
        os_log("Filtre Ayarları - AI: %{public}@, Keyword: %{public}@",
               log: OSLog.smsFilter,
               type: .debug,
               String(describing: useAI),
               String(describing: useKeywordFilter))
        
        // Hiçbir filtre aktif değilse erken çık (Engellendi - hatalara karşı oluşturuldu.)
        guard useAI || useKeywordFilter else {
            os_log("Hiçbir filtre aktif değil", log: OSLog.smsFilter, type: .info)
            response.action = .none
            completion(response)
            return
        }

        var isSpamAI = false
        var isSpamKeyword = false

        // AI Filtreleme
        if useAI {
            let predictor = SMSPredictor.shared
            isSpamAI = !predictor.predict(message: messageBody)
            os_log("🤖 [AI] Spam sonucu: %{public}@", log: OSLog.smsFilter, type: .info, String(describing: isSpamAI))
        }

        // Keyword Filtreleme
        if useKeywordFilter {
            let normalized = normalizeText(messageBody)
            
            let userKeywords = defaults.stringArray(forKey: "UserKeywords") ?? []
            let defaultKeywords = defaults.stringArray(forKey: "DefaultKeywords") ?? defaultSpamKeywords
            
            let normalizedKeywords = Set((userKeywords + defaultKeywords).map(normalizeText))
            isSpamKeyword = normalizedKeywords.contains { normalized.contains($0) }
            
            os_log("Spam sonucu: %{public}@", log: OSLog.smsFilter, type: .info, String(describing: isSpamKeyword))
        }

        // Sonuç belirleme
        let finalAction: ILMessageFilterAction
        switch (useAI, useKeywordFilter) {
        case (true, true):
            finalAction = (isSpamAI || isSpamKeyword) ? .junk : .none
        case (true, false): // yapay zeka kararını önceliklendir.
            finalAction = isSpamAI ? .junk : .none
        case (false, true):
            finalAction = isSpamKeyword ? .junk : .none
        default:
            finalAction = .none
        }
        
        // Verilen kararı loglar ile takip etme.
        os_log(" Final karar: %{public}@", log: OSLog.smsFilter, type: .info, finalAction == .junk ? "Spam" : "Normal")
        
        response.action = finalAction
        completion(response)
    }
}

// Filtrelenen kelimelerdeki türkçeye özgü harfleri dönüştürme.
func normalizeText(_ text: String) -> String {
    return text.folding(options: .diacriticInsensitive, locale: .current)
        .lowercased()
        .replacingOccurrences(of: "ı", with: "i")
        .replacingOccurrences(of: "ü", with: "u")
        .replacingOccurrences(of: "ö", with: "o")
        .replacingOccurrences(of: "ş", with: "s")
        .replacingOccurrences(of: "ç", with: "c")
        .replacingOccurrences(of: "ğ", with: "g")
}

// Extension tarafında oluşan hataları görüntülemek için OSLog eklentisi.
extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier ?? "com.AlperrD.SMSFilterApp.SMSFilterExtension"
    static let smsFilter = OSLog(subsystem: subsystem, category: "SMSFilter")
}
