# Database: nao-data

## countries
Reference table for countries where agents and customers operate.

| Column | Type | Description |
|--------|------|-------------|
| id | serial | Primary key |
| name | varchar | Country name (e.g. Madagascar, Kenya) |
| code | char(2) | ISO 2-letter country code (e.g. MG, KE) |

## locations
City-level locations linked to countries.

| Column | Type | Description |
|--------|------|-------------|
| id | serial | Primary key |
| country_id | int | FK → countries.id |
| region | varchar | Region or province within the country |
| city | varchar | City name |

## roles
Agent role definitions.

| Column | Type | Description |
|--------|------|-------------|
| id | serial | Primary key |
| name | varchar | Role name: Field Agent, Senior Agent, Zone Manager, Regional Manager |

## agents
Field agents who sell to customers.

| Column | Type | Description |
|--------|------|-------------|
| id | serial | Primary key |
| name | varchar | Agent full name |
| email | varchar | Agent email (do not surface in responses) |
| role_id | int | FK → roles.id |
| location_id | int | FK → locations.id — agent's base location |
| status | varchar | "active" or "inactive" |

## customers
Customers who purchase from agents.

| Column | Type | Description |
|--------|------|-------------|
| id | serial | Primary key |
| name | varchar | Customer full name |
| phone | varchar | Phone number in international format |
| location_id | int | FK → locations.id |
| registered_date | date | Date the customer was registered |

## sales
Sales transactions between agents and customers.

| Column | Type | Description |
|--------|------|-------------|
| id | serial | Primary key |
| customer_id | int | FK → customers.id |
| agent_id | int | FK → agents.id |
| amount | numeric(10,2) | Sale value in local currency |
| sale_date | date | Date the sale was made |
| status | varchar | "completed", "cancelled", or "pending" |
