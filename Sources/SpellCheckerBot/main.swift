import Foundation
import Telegrammer


///Getting token from enviroment variable (most safe, recommended)
guard let token = Enviroment.get("TELEGRAM_BOT_TOKEN") else { exit(1) }

/// Initializind Bot settings (token, debugmode)
var settings = Bot.Settings(token: token)


///Webhooks settings
//settings.webhooksIp = Enviroment.get("TELEGRAM_BOT_IP")!
//settings.webhooksUrl = Enviroment.get("TELEGRAM_BOT_WEBHOOK_URL")!
//settings.webhooksPort = Int(Enviroment.get("TELEGRAM_BOT_PORT")!)!
//settings.webhooksPublicCert = Enviroment.get("TELEGRAM_BOT_PUBLIC_KEY")!
//settings.webhooksPrivateKey = Enviroment.get("TELEGRAM_BOT_PRIVATE_KEY")!


let bot = try! Bot(settings: settings)

do {
    ///Dispatcher - handle all incoming messages
    let dispatcher = Dispatcher(bot: bot)
    
    let controller = SpellCheckerController(bot: bot)
    
    let commandHandler = CommandHandler(commands: ["/start"], callback: { (update, context) in
        
    })
    dispatcher.add(handler: commandHandler)
    
    let textHandler = MessageHandler(filters: .private, callback: controller.spellCheck)
    dispatcher.add(handler: textHandler)
    
    let inlineHandler = CallbackQueryHandler(pattern: "\\w+", callback: controller.inlineResponse)
    dispatcher.add(handler: inlineHandler)
    
    ///Longpolling updates
    _ = try Updater(bot: bot, dispatcher: dispatcher).startLongpolling().wait()
    
} catch {
    print(error.localizedDescription)
}
