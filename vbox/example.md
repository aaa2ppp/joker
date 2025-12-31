# Example

```bash
# Создаем VM
make init-jail-env

# Создаем шаблон клетки для разработки 
./joker-run example/create-go-dev-templ

# Создаем клетку под проект
./joker-run example/create-qmail-smtpd-dev

# Собираем и запускаем проект в клетке
./joker-run-tty example/run-qmail-smtpd

# ^C
make stop-joker
#Waiting for 'FreeBSD-joker' to power off: ..........POWER OFF

make start-joker
#Waiting for SSH at 127.0.0.1:2222: .......................................READY

# Собираем и запускаем проект повторно после презагрузки VM
./joker-run-tty example/run-qmail-smtpd

# ^C
make stop-joker
 
# Удаляем VM (это НЕ удаляет созданные клетки, на диске ./data/*-data.vdi)
make clean

# Создаем окружение заново
make init-jail-env

# Собираем и запускаем проект повторно после пересоздания VM
./joker-run-tty example/run-qmail-smtpd
```
