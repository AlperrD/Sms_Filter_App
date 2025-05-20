import Foundation

class FilterManager {
    static let shared = FilterManager()
    let defaults = UserDefaults(suiteName: "group.com.AlperrD.smsfilter") // App group ID

    private let userKey = "UserKeywords"
    private let defaultKey = "DefaultKeywords"
    
    init() {
        // İlk çalıştırmada varsayılan filtreleri kaydet
        if defaults?.array(forKey: defaultKey) == nil {
            defaults?.set(builtInDefaults, forKey: defaultKey)
            defaults?.synchronize()
            print("Varsayılan filtreler ilk kez kaydedildi")
        }
    }
    
    let builtInDefaults = [
        "kumar", "bahis", "casino", "şans oyunu", "dede", "jackpot", "bet", "spin", "çevrim", "çevrimsiz",
        "çekim limiti", "freebet", "canlı bahis", "slot", "piyango", "ödül", "promosyon", "hediye", "bonus",
        "kazan", "para", "ödeme", "yeni üye", "kazanç", "jackpot", "turnuva", "kayıt ol", "ücretsiz deneme",
        "mobil bahis", "kredi", "bahis sitesi", "para yatır", "para çek", "maksimum bahis", "bahis kuponu",
        "kazanç fırsatı", "maç sonucu", "tahmin", "oran", "bahis oranı", "kazanç garantisi", "oyun", "mobil casino",
        "slot oyunları", "ücretsiz bahis", "hesap aç", "giriş yap", "yükle", "slot makinesi", "sanal bahis", "bitcoin bahis",
        "canlı casino", "rulet", "blackjack", "poker", "jackpot kazan", "bahis yap", "bahis oynayın", "para kazan",
        "haftalık bonus", "vip bahis", "spor bahisleri", "kazandıran sistem", "turnuva", "ödül kazan", "canlı destek",
        "bonus kodu", "bedava spin", "şans", "kazançlı", "vip üyelik", "giriş bonusu", "ödül programı", "şifre değiştir",
        "limit aşımı", "kayıt bonusu", "çevrimsiz bonus", "para yatırma", "minimum bahis", "maksimum kazanç",
        "ödül kuponu", "ödül spin", "bonus fırsatı", "sanal para", "güvenilir bahis", "para yatırma bonusu",
        "kayıp bonusu", "ilk para yatırma", "promosyon kodu", "güvenilir site", "garantili bahis", "güvenilir casino",
        "ödül kazanma", "vip destek"
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
}
