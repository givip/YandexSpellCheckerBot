//
//  YandexSpellChecker.swift
//  SpellCheckerBot
//
//  Created by Givi Pataridze on 13/06/2018.
//

import Foundation
import Telegrammer

final class YaSpellChecker: SpellChecker {
    
    typealias T = YaSpellCheck
    
    var url: String {
        return "https://speller.yandex.net/services/spellservice.json/checkText"
    }
    
    let queue: DispatchQueue
    let urlSession: URLSession
    
    public init() {
        self.queue = DispatchQueue(label: "SpellCheckerQueue", qos: .default, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
        self.urlSession = URLSession(configuration: .ephemeral)
    }
    
    func check(_ text: String, lang: Lang, format: Format, callback: @escaping ([T]) throws -> ()) {
        queue.async {
            guard var urlCompoment = URLComponents(string: self.url) else { return }
            let textRequest = text.replacingOccurrences(of: " ", with: "+")
            
            urlCompoment.queryItems = [
                URLQueryItem(name: "text", value: textRequest),
                URLQueryItem(name: "lang", value: lang.rawValue),
                URLQueryItem(name: "format", value: format.rawValue)
            ]
            
            self.urlSession.dataTask(with: urlCompoment.url!, completionHandler: { (data, response, error) in
                guard let data = data else { return }
                do {
                    let checks = try JSONDecoder().decode(Array<T>.self, from: data)
                    try callback(checks)
                } catch {
                    print(error.localizedDescription)
                }
            }).resume()
        }
    }
}
