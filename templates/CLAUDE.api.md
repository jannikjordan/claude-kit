# Project: [API Name]

## Stack
- **Runtime**: Node.js / Python / Go
- **Framework**: Express / FastAPI / Gin
- **Database**: PostgreSQL / MongoDB / Redis
- **Auth**: JWT / OAuth2 / API Keys
- **Documentation**: OpenAPI/Swagger

## Commands
- `npm run dev` - Start development server
- `npm test` - Run tests
- `npm run db:migrate` - Run database migrations
- `npm run seed` - Seed database with test data

## API Design
- RESTful conventions
- Versioned endpoints (`/api/v1/...`)
- Consistent error responses
- Pagination for list endpoints
- Rate limiting enabled

## Code Guidelines
- Input validation on all endpoints
- Proper error handling
- Transaction management for database operations
- Write integration tests for all endpoints
- Document all endpoints in OpenAPI spec
- Use middleware for auth and logging

## File Organization
```
src/
├── routes/       # API route definitions
├── controllers/  # Request handlers
├── models/       # Database models
├── middleware/   # Express middleware
├── services/     # Business logic
├── validators/   # Input validation
└── tests/        # Test files
```

## Security
- Never log sensitive data
- Validate all input
- Use parameterized queries (prevent SQL injection)
- Rate limit endpoints
- Enable CORS appropriately

## Important Notes
- [Environment variables required]
- [Database schema details]
- [Third-party API integrations]
