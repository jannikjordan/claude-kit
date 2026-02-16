# Project: [Project Name]

## Stack
- **Language**: Python 3.11+
- **Framework**: [FastAPI/Django/Flask]
- **Database**: [PostgreSQL/MySQL/MongoDB]
- **ORM**: [SQLAlchemy/Django ORM]
- **Testing**: pytest
- **Linting**: ruff + black

## Commands
- `python -m venv venv && source venv/bin/activate` - Setup virtualenv
- `pip install -r requirements.txt` - Install dependencies
- `python manage.py runserver` or `uvicorn main:app --reload` - Run dev server
- `pytest` - Run tests
- `black .` - Format code
- `ruff check .` - Lint code

## Code Guidelines
- Follow PEP 8
- Use type hints for all functions
- Write docstrings for classes and functions
- Keep functions small and focused
- Write tests for all new features
- Use async/await where appropriate

## File Organization
```
src/
├── api/          # API routes
├── models/       # Database models
├── schemas/      # Pydantic schemas
├── services/     # Business logic
├── tests/        # Test files
└── utils/        # Utility functions
```

## Important Notes
- [Database connection details]
- [Environment variables needed]
- [API authentication method]
