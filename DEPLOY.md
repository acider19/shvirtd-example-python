# Руководство по развертыванию приложения

## 1. Собрать Docker image

Собирать под архитектуру VM в Yandex Cloud:

```bash
docker build --platform linux/amd64 \
  -f Dockerfile.python \
  -t cr.yandex/<registry_id>/python_server:latest .
```

## 2. Авторизоваться в Yandex Container Registry локально

Это нужно для `docker push` с локальной машины.

Если используется Docker credential helper:

```bash
yc container registry configure-docker
```

Если нужен временный вариант через IAM token:

```bash
yc iam create-token
```

Команда выведет IAM token в терминал. Его нужно скопировать и использовать вместо `<IAM_TOKEN>`.

На локальной машине:

```bash
echo "<IAM_TOKEN>" | docker login \
  --username iam \
  --password-stdin \
  cr.yandex
```

## 3. Запушить image

```bash
docker push cr.yandex/<registry_id>/python_server:latest
```

## 4. Подготовить VM и получить файлы приложения

Проверить Docker и Compose:

```bash
ssh student@<vm_public_ip> 'docker --version && docker compose version'
```

Если Compose нет:

```bash
ssh student@<vm_public_ip> 'sudo apt update && sudo apt install -y docker-compose-v2'
```

Склонировать репозиторий приложения на VM:

```bash
ssh student@<vm_public_ip> 'git clone -b ter-sum-proj https://github.com/acider19/shvirtd-example-python.git ~/app'
```

Если каталог `~/app` уже существует, обновить его:

```bash
ssh student@<vm_public_ip> 'cd ~/app && git pull'
```

## 5. Создать `.env` на VM

Файл `.env` не хранится в git, поэтому его нужно создать вручную на VM на основе `.env.example`:

```text
APP_IMAGE=cr.yandex/<registry_id>/python_server:latest
DB_HOST=<mdb_host>
DB_NAME=<database_name>
DB_USER=<database_user>
DB_PASSWORD=<database_password>
```

## 6. Скачать image на VM

Если registry требует авторизацию, сначала получить IAM token на машине, где настроен `yc`:

```bash
yc iam create-token
```

Потом выполнить login на VM, подставив полученный токен:

```bash
echo "<IAM_TOKEN>" | docker login \
  --username iam \
  --password-stdin \
  cr.yandex
```

Потом:

```bash
ssh student@<vm_public_ip> 'cd ~/app && docker compose -f compose.cloud.yaml pull'
```

## 7. Запустить приложение

```bash
ssh student@<vm_public_ip> 'cd ~/app && docker compose -f compose.cloud.yaml up -d'
```

Проверить контейнеры:

```bash
ssh student@<vm_public_ip> 'cd ~/app && docker compose -f compose.cloud.yaml ps'
```

## 8. Проверить приложение

На VM:

```bash
ssh student@<vm_public_ip> 'curl http://127.0.0.1'
ssh student@<vm_public_ip> 'curl http://127.0.0.1/requests'
```

Снаружи:

```bash
curl http://<vm_public_ip>
curl http://<vm_public_ip>/requests
```

## 9. Обновить файлы приложения на VM

Если файлы в репозитории изменились:

```bash
ssh student@<vm_public_ip> 'cd ~/app && git pull'
ssh student@<vm_public_ip> 'cd ~/app && docker compose -f compose.cloud.yaml up -d'
```

Если изменился Docker image:

```bash
ssh student@<vm_public_ip> 'cd ~/app && docker compose -f compose.cloud.yaml pull'
ssh student@<vm_public_ip> 'cd ~/app && docker compose -f compose.cloud.yaml up -d'
```

## 10. Если web-контейнер падает

Посмотреть логи:

```bash
ssh student@<vm_public_ip> 'cd ~/app && docker compose -f compose.cloud.yaml logs --tail=120 web'
```

Частые причины:

- image собран не под `linux/amd64`;
- неправильный `DB_HOST`;
- неправильные `DB_NAME`, `DB_USER`, `DB_PASSWORD`;
- у пользователя MDB стоят маленькие лимиты;
- таблица не создается из-за имени БД с дефисами;
- порт `80` не открыт в security group.
