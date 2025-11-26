try
    -- Эта команда автоматически находит путь к файлу внутри Contents/Resources
    set scriptPath to POSIX path of (path to resource "start.sh")
    
    -- Запускаем скрипт
    do shell script "sh " & quoted form of scriptPath & " > /dev/null 2>&1 &"
    
on error errMsg
    display dialog "Ошибка запуска: не найден start.sh внутри приложения." & return & return & "Детали: " & errMsg buttons {"OK"} default button "OK" with icon stop
end try