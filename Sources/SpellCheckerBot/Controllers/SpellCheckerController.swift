//
//  SpellCheckerController.swift
//  SpellCheckerBot
//
//  Created by Givi Pataridze on 16/06/2018.
//

import Foundation
import Telegrammer

class SpellCheckerController {
    
    var sessions: [Int64: YaSpellFlow] = [:]
    let spellChecker = YaSpellChecker()
    let bot: Bot
    
    init(bot: Bot) {
        self.bot = bot
    }
    
    static func menu(_ buttons: [String]) -> InlineKeyboardMarkup {
        var menuButtons = buttons.map({ (spell) -> InlineKeyboardButton in
            return InlineKeyboardButton(text: spell, callbackData: "fix:\(spell)")
        }).chunk(3)
        let additionalButtons = [
            InlineKeyboardButton(text: "Skip", callbackData: "skip"),
            InlineKeyboardButton(text: "Keep", callbackData: "keep"),
            ]
        let systemButtons = [
            InlineKeyboardButton(text: "Get corrected text", callbackData: "finish"),
            InlineKeyboardButton(text: "Cancel", callbackData: "cancel"),
            ]
        menuButtons.append(additionalButtons)
        menuButtons.append(systemButtons)
        return InlineKeyboardMarkup(inlineKeyboard: menuButtons)
    }
    
    func spellCheck(_ update: Update, _ context: BotContext?) throws {
        guard let message = update.message,
            let text = message.text,
            let user = message.from else { return }
        
        spellChecker.check(text, lang: Lang.ru, format: Format.plain) { [unowned self] (checks) in
            let flow = YaSpellFlow()
            flow.start(text, checks: checks)
            
            self.sessions[user.id] = flow
            
            guard let result: (textChunk: String, spellFixes:[String]) = flow.next() else { return }
            let markup = SpellCheckerController.menu(result.spellFixes)
            let params = Bot.SendMessageParams(chatId: .chat(message.chat.id),
                                               text: result.textChunk,
                                               parseMode: "HTML",
                                               replyMarkup: .inlineKeyboardMarkup(markup))
            try self.bot.sendMessage(params: params)
        }
    }
    
    func inlineResponse(_ update: Update, _ context: BotContext?) throws {
        guard let query = update.callbackQuery,
            let message = query.message,
            let data = query.data else { return }
        
        let user = query.from
        let parts = data.split(separator: ":")
        
        guard let flow = sessions[user.id],
            let first = parts.first,
            let command = Command(rawValue: String(first)) else { return }
        
        switch command {
        case .keep:
            flow.keep()
        case .skip:
            flow.skip()
        case .fix:
            if let last = parts.last {
                flow.fix(String(last))
            }
        case .finish:
            let correctedText = flow.finish()
            let params = Bot.EditMessageTextParams(chatId: .chat(message.chat.id), messageId: message.messageId, text: correctedText)
            try! bot.editMessageText(params: params)
            return
        case .cancel:
            sessions.removeValue(forKey: user.id)
            return
        }
        
        guard let result: (textChunk: String, spellFixes:[String]) = flow.next() else { return }
        let markup = SpellCheckerController.menu(result.spellFixes)
        let params = Bot.EditMessageTextParams(chatId: .chat(message.chat.id), messageId: message.messageId, text: result.textChunk, parseMode: "HTML", replyMarkup: markup)
        try bot.editMessageText(params: params)
    }
}
