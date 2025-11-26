#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <mach-o/dyld.h>
#include <limits.h>
#include <libgen.h>

int main(int argc, char *argv[]) {
    char path[PATH_MAX];
    uint32_t size = sizeof(path);

    // 1. Получаем путь к самому этому исполняемому файлу (в папке MacOS)
    if (_NSGetExecutablePath(path, &size) != 0) {
        fprintf(stderr, "Buffer too small; need size %u\n", size);
        return 1;
    }

    // 2. Получаем папку, где лежит файл (удаляем имя файла из пути)
    char *dir = dirname(path);

    // 3. Формируем путь к start.sh
    // Мы сейчас в .../Contents/MacOS, а нам нужно в .../Contents/Resources/start.sh
    // Поэтому выходим на уровень вверх (../) и заходим в Resources
    char scriptPath[PATH_MAX];
    snprintf(scriptPath, sizeof(scriptPath), "%s/../Resources/start.sh", dir);

    // 4. Формируем команду запуска
    // "sh 'путь/к/скрипту' &" (& запускает в фоне, чтобы лаунчер мог закрыться)
    char command[PATH_MAX + 10];
    snprintf(command, sizeof(command), "sh \"%s\" &", scriptPath);

    // 5. Запускаем
    int result = system(command);
    
    return result;
}