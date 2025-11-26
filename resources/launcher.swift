import Cocoa
import Foundation

// Класс приложения, чтобы скрыть иконку в доке, если нужно, или управлять окнами
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        runScript()
    }

    func runScript() {
        // 1. Ищем путь к start.sh внутри Resources
        guard let scriptPath = Bundle.main.path(forResource: "start", ofType: "sh") else {
            showError(title: "Ошибка", message: "Не найден файл start.sh в ресурсах приложения.")
            return
        }

        // 2. Настраиваем процесс запуска
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = [scriptPath]

        // Передаем текущее окружение (PATH и т.д.)
        var env = ProcessInfo.processInfo.environment
        // Добавляем стандартные пути, чтобы находились команды типа python3
        let currentPath = env["PATH"] ?? ""
        env["PATH"] = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:" + currentPath
        task.environment = env

        // 3. Захватываем вывод (логы), чтобы показать их при ошибке
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
            task.waitUntilExit()

            // 4. Если скрипт завершился с ошибкой (код не 0)
            if task.terminationStatus != 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? "Неизвестная ошибка"
                showError(title: "Ошибка запуска", message: output)
            }
            
            // Если все ок, просто закрываем лаунчер
            NSApp.terminate(nil)
            
        } catch {
            showError(title: "Критическая ошибка", message: error.localizedDescription)
        }
    }

    func showError(title: String, message: String) {
        // Запуск в главном потоке (UI)
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            // Если текст ошибки очень длинный, можно обрезать или выводить в консоль
            print("ERROR: \(message)")
            alert.runModal()
            NSApp.terminate(nil)
        }
    }
}

// Запуск приложения
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()