# Table: sales
Sales transactions between agents and customers.

| Column | Type | Description |
|--------|------|-------------|
| id | serial | Primary key |
| customer_id | int | FK → customers.id |
| agent_id | int | FK → agents.id |
| amount | numeric(10,2) | Sale value in local currency |
| sale_date | date | Date the sale was made |
| status | varchar | "completed", "cancelled", or "pending" |
