# Table: agents
Field agents who sell to customers.

| Column | Type | Description |
|--------|------|-------------|
| id | serial | Primary key |
| name | varchar | Agent full name |
| email | varchar | Agent email (do not surface in responses) |
| role_id | int | FK → roles.id |
| location_id | int | FK → locations.id — agent's base location |
| status | varchar | "active" or "inactive" |
