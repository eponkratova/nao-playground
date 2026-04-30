# NAO Agent Rules

## Behavior

- Always respond in English unless the user writes in another language.
- When asked about sales performance, default to the last 30 days unless a different period is specified.
- Round monetary amounts to 2 decimal places.
- When listing agents or customers, order by most recent activity unless specified otherwise.

## Data Conventions

- `agents.status`: "active" or "inactive". Exclude inactive agents from performance metrics unless explicitly asked.
- `sales.status`: "completed", "cancelled", or "pending". Default metric calculations use "completed" sales only.
- Locations are hierarchical: city → region → country.

## Boundaries

- Do not expose raw email addresses in responses. Refer to agents by name only.
- Do not speculate about data not present in the database. If data is missing, say so.
