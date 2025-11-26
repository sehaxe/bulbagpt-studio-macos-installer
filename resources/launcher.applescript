on run
    -- Получаем путь к самой программе (.app)
    set appPath to path to me as string
    set posixAppPath to POSIX path of appPath
    
    -- Программа лежит в /Applications/BulbaGPT/BulbaGPT Studio.app
    -- Нам нужно подняться на уровень выше, в папку проекта
    set projectDir to do shell script "dirname " & quoted form of (posixAppPath & "../")
    
    -- Путь к скрипту запуска
    set startScript to projectDir & "/start.sh"
    
    -- Запускаем терминал и выполняем скрипт
    tell application "Terminal"
        if not (exists window 1) then reopen
        activate
        -- clear screen и запуск
        do script "clear && sh " & quoted form of startScript
    end tell
end run
