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
    
    private static func menu(_ buttons: [String]) -> InlineKeyboardMarkup {
        var menuButtons = buttons.map({ (spell) -> InlineKeyboardButton in
            return InlineKeyboardButton(text: spell, callbackData: "fix:\(spell)")
        }).chunk(3)
        let additionalButtons = [
            InlineKeyboardButton(text: "⁉️ Пропустить", callbackData: "skip"),
            InlineKeyboardButton(text: "❎ Не исправлять", callbackData: "keep"),
            ]
        let systemButtons = [
            InlineKeyboardButton(text: "🚀 Готовый текст", callbackData: "finish"),
            InlineKeyboardButton(text: "⚠️ Отменить", callbackData: "cancel"),
            ]
        menuButtons.append(additionalButtons)
        menuButtons.append(systemButtons)
        return InlineKeyboardMarkup(inlineKeyboard: menuButtons)
    }
    
    func start(_ update: Update, _ context: BotContext?) throws {
        guard let message = update.message else { return }
        let text =
        """
        Отправь боту текст, который хочешь проверить на орфографию ✅
        """
        try sendMessage(message, text: text)
    }
    
    func spellCheck(_ update: Update, _ context: BotContext?) throws {
        guard let message = update.message,
            let text = message.text,
            let user = message.from else { return }
        
        spellChecker.check(text, lang: Lang.ru, format: Format.plain) { [unowned self] (checks) in
            guard !checks.isEmpty else {
                try self.congrat(message: message)
                return
            }
            
            let flow = YaSpellFlow()
            flow.start(text, checks: checks)
            
            self.sessions[user.id] = flow
            
            if let result: (textChunk: String, spellFixes:[String]) = flow.next() {
                let markup = SpellCheckerController.menu(result.spellFixes)
                try self.sendMessage(message, text: result.textChunk, markup: .inlineKeyboardMarkup(markup))
            }
        }
    }
    
    func inline(_ update: Update, _ context: BotContext?) throws {
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
            try next(flow, to: message)
        case .skip:
            flow.skip()
            try next(flow, to: message)
        case .fix:
            guard let last = parts.last else { return }
            flow.fix(String(last))
            try next(flow, to: message)
        case .finish:
            try finish(flow, to: message)
        case .cancel:
            sessions.removeValue(forKey: user.id)
            try cancel(message: message)
        }
    }
}

private extension SpellCheckerController {
    
    func next(_ flow: YaSpellFlow, to message: Message) throws {
        if let result: (textChunk: String, spellFixes:[String]) = flow.next() {
            let markup = SpellCheckerController.menu(result.spellFixes)
            try editMessage(message, text: result.textChunk, markup: markup)
        } else {
            try finish(flow, to: message)
        }
    }
    
    func finish(_ flow: YaSpellFlow, to message: Message) throws {
        let correctedText = flow.finish()
        let text =
        """
        ✅ Исправленный текст:
        ```
        \(correctedText)
        ```
        """
        try editMessage(message, text: text)
    }
    
    func congrat(message: Message) throws {
        let text =
        """
        👏 Поздравляю! В вашем тексте ни одной ошибки!
        """
        try sendMessage(message, text: text)
    }
    
    func cancel(message: Message) throws {
        let text =
        """
        😔 Ты отменил проверку орфографии.
        """
        try editMessage(message, text: text)
    }
}

private extension SpellCheckerController {
    
    func editMessage(_ message: Message, text: String, markup: InlineKeyboardMarkup? = nil) throws {
        let params = Bot.EditMessageTextParams(chatId: .chat(message.chat.id),
                                               messageId: message.messageId,
                                               text: text,
                                               parseMode: "Markdown",
                                               replyMarkup: markup)
        try bot.editMessageText(params: params)
    }
    
    func sendMessage(_ message: Message, text: String, markup: ReplyMarkup? = nil) throws {
        let params = Bot.SendMessageParams(chatId: .chat(message.chat.id),
                                           text: text,
                                           parseMode: "Markdown",
                                           replyMarkup: markup)
        try self.bot.sendMessage(params: params)
    }
}
