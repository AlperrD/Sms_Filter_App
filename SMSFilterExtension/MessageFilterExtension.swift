import IdentityLookup

final class MessageFilterExtension: ILMessageFilterExtension {}

extension MessageFilterExtension: ILMessageFilterQueryHandling {
    
    // Metni normalize eden yardımcı fonksiyon
    private func normalizeText(_ text: String) -> String {
        let normalized = text.folding(options: .diacriticInsensitive, locale: .current)
                            .lowercased()
                            .replacingOccurrences(of: "ı", with: "i")
                            .replacingOccurrences(of: "ü", with: "u")
                            .replacingOccurrences(of: "ö", with: "o")
                            .replacingOccurrences(of: "ş", with: "s")
                            .replacingOccurrences(of: "ç", with: "c")
                            .replacingOccurrences(of: "ğ", with: "g")
        return normalized
    }
    
    func handle(_ queryRequest: ILMessageFilterQueryRequest,
                context: ILMessageFilterExtensionContext,
                completion: @escaping (ILMessageFilterQueryResponse) -> Void) {
        let response = ILMessageFilterQueryResponse()
        
        print("Mesaj filtreleme başladı")
        
        guard let messageOriginal = queryRequest.messageBody else {
            print("Mesaj içeriği boş veya okunamadı")
            response.action = .none
            completion(response)
            return
        }
        
        // Mesajı normalize et
        let message = normalizeText(messageOriginal)
        print("Normalize edilmiş mesaj: \(message)")
        
        // Yerleşik yasaklı kelimeler listesi
        let builtInDefaults = [
            "kumar", "bahis", "casino", "sans oyunu", "dede", "jackpot", "bet", "spin", "cevrim", "cevrimsiz",
            "cekim limiti", "freebet", "canli bahis", "slot", "piyango", "odul", "promosyon", "hediye", "bonus",
            // ... diğer kelimeler
        ]
        
        // UserDefaults üzerinden filtreleri alma
        if let defaults = UserDefaults(suiteName: "group.com.AlperrD.smsfilter") {
            let userFilters = defaults.stringArray(forKey: "UserKeywords") ?? []
            let defaultFilters = defaults.stringArray(forKey: "DefaultKeywords") ?? builtInDefaults
            
            print("Yüklenen filtreler - Kullanıcı: \(userFilters.count), Varsayılan: \(defaultFilters.count)")
            
            // Tüm filtreleri normalize et ve birleştir
            let combinedFilters = (userFilters + defaultFilters).map { normalizeText($0) }
            
            for filter in combinedFilters {
                print("Kontrol edilen filtre: \(filter)")
                if message.contains(filter) {
                    print("Yasaklı kelime bulundu: \(filter) - Orijinal mesaj: \(messageOriginal)")
                    response.action = .junk
                    completion(response)
                    return
                }
            }
        } else {
            print("UserDefaults erişimi başarısız - Sadece yerleşik filtreler kullanılıyor")
            
            // Sadece yerleşik filtreleri kullan
            let normalizedDefaults = builtInDefaults.map { normalizeText($0) }
            
            for filter in normalizedDefaults {
                if message.contains(filter) {
                    print("Yerleşik filtreden yasaklı kelime bulundu: \(filter)")
                    response.action = .junk
                    completion(response)
                    return
                }
            }
        }
        
        print("Yasaklı kelime bulunamadı - Mesaj geçerli")
        response.action = .allow
        completion(response)
    }
}
