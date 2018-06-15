//
//  YaSpellFlow.swift
//  SpellCheckerBot
//
//  Created by Givi Pataridze on 15/06/2018.
//

import Foundation

class YaSpellFlow: SpellFlow {
    
    typealias C = YaSpellCheck
    
    var chunkSideSize: Int = 40
    
    private var checks: [C] = []
    private var fixes: [Int: String] = [:]
    private var text: String = ""
    private var fixedText: String {
        return text
    }
    
    private var _step: Int = 0
    private var step: Int {
        get {
            return _step
        }
        set {
            _step = newValue >= checks.count ? 0 : newValue
        }
    }
    
    func start(_ text: String, checks: [C]) {
        self.text = text
        self.checks = checks
    }
    
    func next() -> (textChunk: String, spellFixes: [String])? {
        guard let mdText = textChunk(for: step) else { return nil }
        return (mdText, checks[step].spell)
    }
    
    func fix(_ text: String) {
        fixes[step] = text
        step += 1
    }
    
    func skip() {
        step += 1
    }
    
    func keep() {
        checks.remove(at: step)
    }
    
    func finish() -> String {
        return fixedText
    }
}

private extension YaSpellFlow {
    func textChunk(for step: Int) -> String? {
        let check = checks[step]
        let start = check.position < chunkSideSize ? 0 : check.position - chunkSideSize
        let finish = check.position + check.length + chunkSideSize < text.count ?
            check.position + check.length + chunkSideSize : text.count
        let nsRange = NSRange(location: start, length: finish - start)
        guard let range = Range(nsRange, in: text) else { return nil }
        let mdText = String(text[range]).replacingOccurrences(of: check.word, with: """
            <code>\(check.word)</code>
            """)
        return "...\(mdText)..."
    }
}
