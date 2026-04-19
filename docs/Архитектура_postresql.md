# Схема связей базы данных

```mermaid
erDiagram
    hackathons {
        UUID id PK
        string title
        text description
        timestamp start_at
        timestamp end_at
        enum status "DRAFT, ACTIVE, FINISHED"
        boolean results_published
        boolean results_frozen
    }

    roles {
        UUID id PK
        string code UK "admin, expert, team"
        string name UK
    }

    permissions {
        UUID id PK
        string code UK
        string name
        text description
    }

    role_permissions {
        UUID role_id PK, FK
        UUID permission_id PK, FK
    }

    users {
        UUID id PK
        string login UK
        string password_hash
        string full_name
        string email
        UUID role_id FK
        UUID team_id FK "NULL, Уникально если не NULL"
        boolean is_active
    }

    teams {
        UUID id PK
        UUID hackathon_id FK
        string name
        string captain_name
        string contact_email
        string project_title
        text description
    }

    team_members {
        UUID id PK
        UUID team_id FK
        string full_name
        string email
        boolean is_captain
    }

    criteria {
        UUID id PK
        UUID hackathon_id FK
        string title
        decimal max_score
        decimal weight_percent
        int sort_order
        boolean is_active
    }

    expert_team_assignments {
        UUID id PK
        UUID hackathon_id FK
        UUID expert_user_id FK "Ссылка на users(id)"
        UUID team_id FK
        timestamp assigned_at
    }

    evaluations {
        UUID id PK
        UUID hackathon_id FK
        UUID expert_user_id FK
        UUID team_id FK
        enum status "draft, submitted"
        text overall_comment
        timestamp submitted_at
    }

    evaluation_items {
        UUID id PK
        UUID evaluation_id FK
        UUID criterion_id FK
        decimal raw_score
        text comment
    }

    team_results {
        UUID id PK
        UUID hackathon_id FK
        UUID team_id FK
        decimal final_score
        int place
        int evaluated_by_count
        enum status "not_started, in_progress, completed"
    }

    team_result_items {
        UUID id PK
        UUID team_result_id FK
        UUID criterion_id FK
        decimal avg_raw_score
        decimal weighted_score
    }

    deadlines {
        UUID id PK
        UUID hackathon_id FK
        enum kind "registration, development, pitch..."
        string title
        timestamp deadline_at
        int notify_before_minutes
    }

    audit_logs {
        bigserial id PK
        UUID hackathon_id FK
        UUID actor_user_id FK
        string action
        string entity_type
        UUID entity_id
        jsonb payload
    }

    refresh_tokens {
        UUID id PK
        UUID user_id FK
        string token_hash UK
        timestamp expires_at
        timestamp revoked_at
    }

    %% Связи
    hackathons ||--o{ teams : "проводится"
    hackathons ||--o{ criteria : "содержит критерии"
    hackathons ||--o{ deadlines : "имеет дедлайны"
    hackathons ||--o{ expert_team_assignments : "контекст назначений"
    hackathons ||--o{ evaluations : "контекст оценок"
    hackathons ||--o{ team_results : "имеет итоги"
    hackathons ||--o{ audit_logs : "логируется"

    roles ||--o{ users : "назначается"
    roles ||--o{ role_permissions : "обладает правами"
    permissions ||--o{ role_permissions : "включено в роль"

    users ||--o{ refresh_tokens : "владеет"
    users ||--o{ expert_team_assignments : "эксперт назначен"
    users ||--o{ evaluations : "эксперт оценивает"
    users ||--o{ audit_logs : "действия пользователя"

    users |o--|| teams : "принадлежит (если Team)"

    teams ||--o{ team_members : "состоит из"
    teams ||--o{ expert_team_assignments : "назначена экспертам"
    teams ||--o{ evaluations : "оценена"
    teams ||--o{ team_results : "имеет результат"

    criteria ||--o{ evaluation_items : "используется в оценках"
    criteria ||--o{ team_result_items : "используется в итогах"

    expert_team_assignments ||--o{ evaluations : "является основой для"

    evaluations ||--o{ evaluation_items : "содержит баллы"

    team_results ||--o{ team_result_items : "детализируется"
```

# Описание таблиц

Основные сущности

- `hackathons`: Главная сущность мероприятия. Хранит название, даты проведения, текущий статус (`DRAFT`, `ACTIVE`, `FINISHED`), а также флаги публикации и заморозки результатов.
- `teams`: Команды, участвующие в конкретном хакатоне. Содержит название команды, капитана и описание проекта.
- `users`: Аккаунты пользователей системы (администраторы, эксперты, команды). Связь с командой (`team_id`) уникальна: у одного аккаунта может быть либо 0, либо 1 команда, и наоборот.

Роли и доступ (RBAC)

- `roles`: Роли (`admin`, `expert`, `team`).
- `permissions`: Список конкретных прав (например, `users.create`, `evaluations.submit`).
- `role_permissions`: Связка Многие-ко-Многим между ролями и правами.

Процесс оценки

- `criteria`: Критерии оценки для конкретного хакатона. Определяет название, максимальный балл и вес в процентах от итоговой оценки.
- `expert_team_assignments`: Назначения экспертов на команды. Эксперт может оценивать только те команды, к которым он привязан в этой таблице.
- `evaluations`: Заголовок оценочной формы, которую эксперт заполняет на команду. Может быть черновиком (`draft`) или отправленной (`submitted`).
- `evaluation_items`: Строки оценочной формы. Содержат конкретный `raw_score` (сырой балл) эксперта по определенному критерию.

Результаты и лидерборд

- `team_results`: Кеширующая таблица для быстрого построения турнирной таблицы. Содержит итоговый балл (`final_score`), занятое место (`place`) и статус расчета.
- `team_result_items`: Детализация итогового результата по каждому критерию (средний балл от всех экспертов, взвешенный балл).

Вспомогательные и системные таблицы

- `team_members`: Участники команды (не обязательно пользователи системы, просто ФИО). Флаг `is_captain` определяет капитана.
- `deadlines`: Ключевые даты хакатона (конец регистрации, сдача проектов). Используется для уведомлений.
- `audit_logs`: Журнал аудита всех важных действий в системе (кто, когда и что изменил).
- `refresh_tokens`: Хранилище Refresh токенов для механизма аутентификации (обновление Access токенов без повторного ввода пароля).
