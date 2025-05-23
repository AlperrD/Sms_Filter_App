import Foundation
import CoreML
import OSLog

final class SMSPredictor {
    static let shared = SMSPredictor()

    private var model: sms_filter_lstm_model!
    private var wordIndex: [String: Int] = [:]
    
    // OSLog: Uygulama arka planda çalışan bir extension olduğu için, hata durumlarında loglar ile inceleme yapmayı sağlayan kısım.

    private init() {
        os_log("SMSPredictor init başladı", log: OSLog.smsFilter, type: .debug)
        
        let extensionBundle = Bundle(for: SMSPredictor.self)
        os_log("Bundle yolu: %{public}@", log: OSLog.smsFilter, type: .debug, extensionBundle.bundlePath)
        
        // Bundle içeriğini kontrol et.
        if let resourcePath = extensionBundle.resourcePath {
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                os_log("Bundle içeriği: %{public}@", log: OSLog.smsFilter, type: .debug, files.description)
            } catch {
                os_log("Bundle içeriği okunamadı", log: OSLog.smsFilter, type: .error)
            }
        }
        
        // Modelle ilgili kontrol yapıları.
        if let modelURL = extensionBundle.url(forResource: "sms_filter_lstm_model", withExtension: "mlmodelc") {
            os_log("Model URL mevcut ve bulundu: %{public}@", log: OSLog.smsFilter, type: .debug, modelURL.path)
            do {
                let config = MLModelConfiguration()
                config.computeUnits = .cpuAndGPU
                
                self.model = try sms_filter_lstm_model(contentsOf: modelURL, configuration: config)
                os_log("Model başarıyla yüklendi", log: OSLog.smsFilter, type: .debug)
            } catch {
                os_log("Model yükleme hatası: %{public}@", log: OSLog.smsFilter, type: .error, error.localizedDescription)
            }
        } else {
            os_log("Model URL bulunamadı", log: OSLog.smsFilter, type: .error)
        }
        
        // Tokenizer kontrolleri (Tokenizer içerisinden çekilen kelime - sayı eşleşmesi word_index dosyasında.)
        if let tokenizerURL = extensionBundle.url(forResource: "word_index", withExtension: "json") {
            os_log("Tokenizer URL bulundu: %{public}@", log: OSLog.smsFilter, type: .debug, tokenizerURL.path)
            do {
                let jsonData = try Data(contentsOf: tokenizerURL)
                os_log("JSON data okundu: %{public}d bytes", log: OSLog.smsFilter, type: .debug, jsonData.count)
                
                if let wordIndex = try JSONSerialization.jsonObject(with: jsonData) as? [String: Int] {
                    self.wordIndex = wordIndex
                    os_log("Word index yüklendi: %{public}d kelime", log: OSLog.smsFilter, type: .debug, wordIndex.count)
                } else {
                    os_log("JSON parse edilemedi", log: OSLog.smsFilter, type: .error)
                }
            } catch {
                os_log("JSON okuma hatası: %{public}@", log: OSLog.smsFilter, type: .error, error.localizedDescription)
            }
        } else {
            os_log("Tokenizer URL bulunamadı", log: OSLog.smsFilter, type: .error)
        }
    }

    func predict(message: String) -> Bool {
        let inputArray = tokenize(message, with: wordIndex)
        
        // Model'in alacağı girdi formatı.
        guard let mlArray = try? MLMultiArray(shape: [1, 100], dataType: .float32) else {
            os_log("MLMultiArray oluşturulamadı", log: OSLog.smsFilter, type: .error)
            return false
        }

        for (i, token) in inputArray.enumerated() {
            mlArray[i] = NSNumber(value: Float(token))
        }

        do {
            let prediction = try model.prediction(embedding_input: mlArray)
            let score = prediction.Identity[0].floatValue
            os_log("Tahmin skoru: %{public}f", log: OSLog.smsFilter, type: .debug, score)
            return score > 0.5
        } catch {
            os_log("Tahmin hatası: %{public}@", log: OSLog.smsFilter, type: .error, error.localizedDescription)
            return false
        }
    }

    private func tokenize(_ message: String, with wordIndex: [String: Int], maxLength: Int = 100) -> [Int] {
        let words = message.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        let tokens = words.map { wordIndex[$0] ?? 1 }
        let padded = Array(tokens.prefix(maxLength)) + Array(repeating: 0, count: max(0, maxLength - tokens.count))
        return padded
    }
}
