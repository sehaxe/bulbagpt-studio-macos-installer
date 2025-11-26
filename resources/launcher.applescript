try
    -- Получаем путь к файлу start.sh, который лежит внутри .app/Contents/Resources
    set scriptPath to POSIX path of (path to resource "start.sh")
    
    -- Запускаем скрипт в терминале (фоном)
    -- " > /dev/null 2>&1 &" означает, что окно терминала не зависнет
    do shell script "sh " & quoted form of scriptPath & " > /dev/null 2>&1 &"
    
on error errMsg
    display dialog "Critical Error: Could not find start.sh inside the application bundle." & return & return & "Details: " & errMsg with title "Launch Error" buttons {"OK"} default button "OK" with icon stop
end try