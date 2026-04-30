# Table: customers
Customers who purchase from agents.

| Column | Type | Description |
|--------|------|-------------|
| id | serial | Primary key |
| name | varchar | Customer full name |
| phone | varchar | Phone number in international format |
| location_id | int | FK → locations.id |
| registered_date | date | Date the customer was registered |
