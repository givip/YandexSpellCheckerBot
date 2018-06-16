import Foundation
import Telegrammer


///Getting token from enviroment variable (most safe, recommended)
guard let token = Enviroment.get("SPELL_CHECKER_BOT_TOKEN"),
    let ip = Enviroment.get("SPELL_CHECKER_BOT_BOT_IP"),
    let portStr = Enviroment.get("SPELL_CHECKER_BOT_BOT_PORT"),
    let port = Int(portStr),
    let url = Enviroment.get("SPELL_CHECKER_BOT_BOT_WEBHOOK_URL"),
    let publicCert = Enviroment.get("SPELL_CHECKER_BOT_PUBLIC_KEY"),
    let privateKey = Enviroment.get("SPELL_CHECKER_BOT_PRIVATE_KEY") else { exit(1) }

do {
    var settings = Bot.Settings(token: token)
    
    settings.webhooksIp = ip
    settings.webhooksUrl = url
    settings.webhooksPort = port
    settings.webhooksPublicCert = publicCert
    settings.webhooksPrivateKey = privateKey
    
    let bot = try Bot(settings: settings)
    
    let dispatcher = Dispatcher(bot: bot)
    let controller = SpellCheckerController(bot: bot)
    
    let commandHandler = CommandHandler(commands: ["/start"], callback: controller.start)
    dispatcher.add(handler: commandHandler)
    
    let textHandler = MessageHandler(filters: .private, callback: controller.spellCheck)
    dispatcher.add(handler: textHandler)
    
    let inlineHandler = CallbackQueryHandler(pattern: "\\w+", callback: controller.inline)
    dispatcher.add(handler: inlineHandler)
    
    ///Longpolling updates
    _ = try Updater(bot: bot, dispatcher: dispatcher).startWebhooks().wait()
    
} catch {
    print(error.localizedDescription)
}
