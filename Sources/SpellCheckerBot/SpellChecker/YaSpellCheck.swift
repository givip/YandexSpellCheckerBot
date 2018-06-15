//
//  YaSpellCheck.swift
//  SpellCheckerBot
//
//  Created by Givi Pataridze on 15/06/2018.
//

import Foundation

class YaSpellCheck: Codable {
    let code: Int
    let position: Int
    let row: Int
    let column: Int
    let length: Int
    let word: String
    let spell: [String]
    
    enum CodingKeys: String, CodingKey {
        case code = "code"
        case position = "pos"
        case row = "row"
        case column = "col"
        case length = "len"
        case word = "word"
        case spell = "s"
    }
}
