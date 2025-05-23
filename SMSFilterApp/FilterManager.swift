import Foundation

class FilterManager {
    static let shared = FilterManager()
    let defaults = UserDefaults(suiteName: "group.com.AlperrD.smsfilter") // Uygulama grup ID'si

    private let userKey = "UserKeywords"
    private let defaultKey = "DefaultKeywords"
    private let useAIKey = "UseAI"
    private let useKeywordFilterKey = "UseKeywordFilter"

    init() {
        // İlk çalıştırmada varsayılan filtreleri kaydet
        if defaults?.array(forKey: defaultKey) == nil {
            defaults?.set(builtInDefaults, forKey: defaultKey)
            defaults?.synchronize()
            print("Varsayılan filtreler ilk kez kaydedildi")
        }
        
        // Kullanıcı tercihlerinin varsayılan olarak ayarlanması
        if defaults?.object(forKey: useAIKey) == nil {
            defaults?.set(true, forKey: useAIKey)
            print("Varsayılan olarak AI kullanımı açık")
        }
        
        if defaults?.object(forKey: useKeywordFilterKey) == nil {
            defaults?.set(true, forKey: useKeywordFilterKey)
            print("Varsayılan olarak kelime filtresi kullanımı açık")
        }

        defaults?.synchronize()
    }
    
    let builtInDefaults = [
        "kumar", "bahis", "casino", "şans oyunu", "dede", "jackpot", "bet", "spin", "çevrim", "çevrimsiz",
        "çekim limiti", "freebet", "canlı bahis", "slot", "piyango", "ödül", "promosyon", "hediye", "bonus",
    ]

    func loadUserFilters() -> [String] {
        let filters = defaults?.stringArray(forKey: userKey) ?? []
        print("Kullanıcı filtreleri yüklendi: \(filters.count)")
        return filters
    }
    
    func saveUserFilters(_ filters: [String]) {
        defaults?.set(filters, forKey: userKey)
        defaults?.synchronize()
        print("Kullanıcı filtreleri kaydedildi: \(filters.count)")
    }
    
    func loadDefaultFilters() -> [String] {
        let filters = defaults?.stringArray(forKey: defaultKey) ?? builtInDefaults
        print("Varsayılan filtreler yüklendi: \(filters.count)")
        return filters
    }

    func saveDefaultFilters(_ filters: [String]) {
        defaults?.set(filters, forKey: defaultKey)
        defaults?.synchronize()
        print("Varsayılan filtreler kaydedildi: \(filters.count)")
    }

    // Kullanıcı tercihlerini ayarla
    func setUseAI(_ useAI: Bool) {
        defaults?.set(useAI, forKey: useAIKey)
        defaults?.synchronize()
        print("Yapay Zeka kullanımı ayarlandı: \(useAI)")
    }

    func setUseKeywordFilter(_ useKeywordFilter: Bool) {
        defaults?.set(useKeywordFilter, forKey: useKeywordFilterKey)
        defaults?.synchronize()
        print("Kelime filtresi kullanımı ayarlandı: \(useKeywordFilter)")
    }

    // Kullanıcı tercihlerini yükle
    func shouldUseAI() -> Bool {
        return defaults?.bool(forKey: useAIKey) ?? false
    }

    func shouldUseKeywordFilter() -> Bool {
        return defaults?.bool(forKey: useKeywordFilterKey) ?? false
    }
}
