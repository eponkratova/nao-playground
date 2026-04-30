# Table: locations
City-level locations linked to countries.

| Column | Type | Description |
|--------|------|-------------|
| id | serial | Primary key |
| country_id | int | FK → countries.id |
| region | varchar | Region or province within the country |
| city | varchar | City name |
