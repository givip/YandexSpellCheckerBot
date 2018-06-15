import Foundation
import Telegrammer


///Getting token from enviroment variable (most safe, recommended)
guard let token = Enviroment.get("TELEGRAM_BOT_TOKEN") else { exit(1) }

/// Initializind Bot settings (token, debugmode)
var settings = Bot.Settings(token: token)
let spellChecker = YaSpellChecker()

var sessions: [Int64: YaSpellFlow] = [:]

///Webhooks settings
//settings.webhooksIp = Enviroment.get("TELEGRAM_BOT_IP")!
//settings.webhooksUrl = Enviroment.get("TELEGRAM_BOT_WEBHOOK_URL")!
//settings.webhooksPort = Int(Enviroment.get("TELEGRAM_BOT_PORT")!)!
//settings.webhooksPublicCert = Enviroment.get("TELEGRAM_BOT_PUBLIC_KEY")!
//settings.webhooksPrivateKey = Enviroment.get("TELEGRAM_BOT_PRIVATE_KEY")!

func spellCheck(_ update: Update, _ context: BotContext?) throws {
    guard let message = update.message,
        let text = message.text,
        let user = message.from else { return }
    
    spellChecker.check(text, lang: Lang.ru, format: Format.plain) { (checks) in
        let flow = YaSpellFlow()
        flow.start(text, checks: checks)
        
        sessions[user.id] = flow
        
        guard let result: (textChunk: String, spellFixes:[String]) = flow.next() else { return }
        let markup = menu(result.spellFixes)
        sendMenu(chat: .chat(message.chat.id), message: result.textChunk, markup: .inlineKeyboardMarkup(markup))
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
    }
    
    guard let result: (textChunk: String, spellFixes:[String]) = flow.next() else { return }
    let markup = menu(result.spellFixes)
    let params = Bot.EditMessageTextParams(chatId: .chat(message.chat.id), messageId: message.messageId, text: result.textChunk, parseMode: "HTML", replyMarkup: markup)
    try! bot.editMessageText(params: params)
}

func menu(_ buttons: [String]) -> InlineKeyboardMarkup {
    var keyboards = buttons.map({ (spell) -> InlineKeyboardButton in
        return InlineKeyboardButton(text: spell, callbackData: "fix:\(spell)")
    }).chunk(3)
    let systemKeyboards = [
        InlineKeyboardButton(text: "Skip", callbackData: "skip"),
        InlineKeyboardButton(text: "Keep", callbackData: "keep"),
    ]
    keyboards.append(systemKeyboards)
    return InlineKeyboardMarkup(inlineKeyboard: keyboards)
}

func sendMenu(chat: ChatId, message: String, markup: ReplyMarkup) {
    let params = Bot.SendMessageParams(chatId: chat, text: message, parseMode: "HTML", replyMarkup: markup)
    try! bot.sendMessage(params: params)
}

let bot = try! Bot(settings: settings)

do {
    ///Dispatcher - handle all incoming messages
    let dispatcher = Dispatcher(bot: bot)
    
    let commandHandler = CommandHandler(commands: ["/start"], callback: { (update, context) in
        
    })
    dispatcher.add(handler: commandHandler)
    
    let textHandler = MessageHandler(filters: .private, callback: spellCheck)
    dispatcher.add(handler: textHandler)
    
    let inlineHandler = CallbackQueryHandler(pattern: "\\w+", callback: inlineResponse)
    dispatcher.add(handler: inlineHandler)
    
    ///Longpolling updates
    _ = try Updater(bot: bot, dispatcher: dispatcher).startLongpolling().wait()
    
} catch {
    print(error.localizedDescription)
}
