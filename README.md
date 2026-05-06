# IP Monitoring

Сервис для мониторинга IP-адресов.

## Стек

- Ruby 4.0.1
- Roda
- Sequel
- PostgreSQL
- Redis
- Sidekiq
- Docker
- Dry-validation

## Запуск

```bash
git clone https://github.com/OrtinPaler/ip_monitoring.git
cd ip_monitoring
bundle install
cp config/database.yml.example config/database.yml
createdb ip_monitoring_development
bundle exec rake db:migrate
bundle exec rackup
```

### Docker

```bash
docker compose up -d
docker compose exec app bundle exec rake db:migrate
```

## API

### Создать IP

```bash
POST /ips
Content-Type: application/json

{
  "ip": "8.8.8.8",
  "enabled": true
}
```

### Получить статистику

```bash
GET /ips/:id/stats?time_from=2026-05-05T00:00:00Z&time_to=2026-05-06T00:00:00Z
```

### Включить/выключить мониторинг

```bash
PATCH /ips/:id/enable
PATCH /ips/:id/disable
```

### Удалить IP

```bash
DELETE /ips/:id
```
