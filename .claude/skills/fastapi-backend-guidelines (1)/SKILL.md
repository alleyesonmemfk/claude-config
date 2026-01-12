---
name: fastapi-backend-guidelines
description: Complete guide for FastAPI/Python/SQLAlchemy backend development. Use when creating routes, services, repositories, working with FastAPI routers, SQLAlchemy models, Pydantic schemas, DI container, Alembic migrations or implementing features. Covers Feature-First architecture, Dependency Injection, Repository Pattern, Service Layer, DTO patterns, error handling.
---

# FastAPI Backend Development Guidelines

## Purpose

Ensure consistency and best practices across your backend using Feature-First architecture with FastAPI/Python/SQLAlchemy stack.

## When to Use This Skill

Automatically activates when working on:
- Creating or modifying API routes, endpoints
- Writing services, repositories
- Implementing new features in `back/app/features/`
- Working with SQLAlchemy models and Alembic migrations
- Pydantic schema validation
- Setting up Dependency Injection container
- Testing and refactoring backend

---

## Quick Start Checklists

### New Feature Checklist

- [ ] **Feature Module**: Create in `back/app/features/feature_name/`
- [ ] **Router**: FastAPI router with route definitions
- [ ] **DTO**: Pydantic schemas for request/response
- [ ] **Service**: Business logic with DI
- [ ] **Repository**: Data access (if needed)
- [ ] **Models**: SQLAlchemy models (if new entities)
- [ ] **Migration**: Alembic migration for DB changes
- [ ] **Tests**: Unit + integration tests
- [ ] **Registration**: Register in DI container and main router

### New Endpoint Checklist

- [ ] **Route**: Clean definition in router, delegate to service
- [ ] **Request DTO**: Pydantic schema for validation
- [ ] **Response DTO**: Pydantic schema for output
- [ ] **Service Method**: Business logic
- [ ] **Error Handling**: Try/catch with proper HTTP exceptions
- [ ] **Logging**: Structured logging with context
- [ ] **Tests**: Test cases

---

## Architecture Overview

### Feature-First Structure

```
back/app/
├── features/           # Domain modules
│   ├── auth/
│   │   ├── api/            # Routers
│   │   ├── dto/            # Pydantic schemas
│   │   ├── services/       # Business logic
│   │   ├── repositories/   # Data access
│   │   └── tests/          # Tests
│   ├── items/
│   ├── orders/
│   └── ...
├── shared/             # Shared components
│   ├── database/       # DB connection, base repository
│   ├── dependencies/   # FastAPI dependencies
│   ├── di/            # DI Container
│   ├── middleware/    # CORS, sessions, logging
│   ├── models/        # SQLAlchemy models
│   ├── schemas/       # Shared Pydantic schemas
│   └── utils/
└── core/              # Application core
    ├── settings.py    # Pydantic settings
    ├── logging.py     # Structured logging
    └── error_handlers.py

main.py                # FastAPI application entry point
```

### Layered Architecture for Each Feature

```
HTTP Request
    ↓
Router (routing only)
    ↓
Service (business logic + DI)
    ↓
Repository (data access)
    ↓
SQLAlchemy Model
    ↓
PostgreSQL Database
```

**Key Principle:** Each layer has ONE responsibility.

---

## Feature Directory Structure

```
features/feature_name/
├── api/
│   └── feature_router.py       # FastAPI router
├── dto/
│   ├── feature_dto.py          # Request/response schemas
│   └── feature_response_dto.py # Separate response DTOs
├── services/
│   └── feature_service.py      # Business logic
├── repositories/
│   └── feature_repository.py   # Data access
├── tests/
│   ├── test_api.py
│   ├── test_service.py
│   └── test_repository.py
└── __init__.py
```

**Naming Conventions:**
- Routers: `feature_router.py` with `router = APIRouter()`
- Services: `feature_service.py` with class `FeatureService`
- Repositories: `feature_repository.py` with class `FeatureRepository`
- DTO: `feature_dto.py` with `CreateFeatureRequest`, `FeatureResponse`

---

## Core Patterns Summary

### 1. Router Pattern
- Use `APIRouter` with prefix and tags
- Inject services via `create_service_dependency()`
- Delegate all logic to service layer
- Handle exceptions with proper HTTP status codes

→ See `resources/router-patterns.md` for full examples

### 2. DTO Pattern (Pydantic)
- Separate Request and Response DTOs
- Use `Field()` for validation constraints
- Custom validators with `@field_validator`
- `model_config = {"from_attributes": True}` for SQLAlchemy

→ See `resources/dto-patterns.md` for full examples

### 3. Service Layer
- Constructor injection of repositories
- Business logic validation
- Structured logging with context
- Return DTOs, not models

→ See `resources/service-patterns.md` for full examples

### 4. Repository Pattern
- Inherit from `BaseRepository[Model]`
- Constructor accepts `AsyncSession`
- Domain-specific query methods
- Use SQLAlchemy 2.0 syntax (`select()`)

→ See `resources/repository-patterns.md` for full examples

### 5. DI Container
- Register services and repositories
- Use `create_service_dependency()` in routes

→ See `resources/di-container.md` for full examples

### 6. Error Handling
- `ValueError` → 400 Bad Request
- `PermissionError` → 403 Forbidden
- `Exception` → 500 Internal Error
- Always log errors with context

→ See `resources/error-handling.md` for full examples

### 7. Alembic Migrations
- `alembic revision --autogenerate -m "description"`
- `alembic upgrade head`
- Always test downgrade path

→ See `resources/database-patterns.md` for full examples

### 8. Testing
- Use pytest + AsyncMock
- Test services with mocked repositories
- Integration tests for API endpoints

→ See `resources/testing-guide.md` for full examples

---

## HTTP Status Codes Reference

| Code | Name | When to Use |
|------|------|-------------|
| 200 | OK | Successful GET, PUT |
| 201 | Created | Successful POST |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Validation error |
| 401 | Unauthorized | Not authenticated |
| 403 | Forbidden | Authenticated but not authorized |
| 404 | Not Found | Resource not found |
| 500 | Internal Error | Unexpected server error |

---

## Quick Reference

**Create New Feature:**
1. `mkdir -p back/app/features/feature_name/{api,dto,services,repositories,tests}`
2. Create router, DTO, service, repository
3. Register in DI container
4. Include router in main.py
5. Create migration if needed
6. Write tests

**File Naming:**
- Routers: `feature_router.py`
- Services: `feature_service.py`
- Repositories: `feature_repository.py`
- DTO: `feature_dto.py`
- Tests: `test_*.py`

**Import Patterns:**
```python
# Features
from app.features.feature_name.api.router import router
from app.features.feature_name.dto.dto import RequestDTO, ResponseDTO
from app.features.feature_name.services.service import Service

# Shared
from app.shared.database.session import get_db
from app.shared.di.container import create_service_dependency
from app.shared.models.user_models import User
from app.core.settings import settings
from app.core.logging import get_logger
```

---

## Resources (Progressive Disclosure)

For detailed patterns and full code examples, see:
- `resources/router-patterns.md` - Router implementation details
- `resources/dto-patterns.md` - Pydantic schemas and validation
- `resources/service-patterns.md` - Service layer patterns
- `resources/repository-patterns.md` - Repository and DB access
- `resources/di-container.md` - Dependency Injection setup
- `resources/error-handling.md` - Error handling patterns
- `resources/database-patterns.md` - SQLAlchemy and Alembic
- `resources/testing-guide.md` - Testing strategies
- `resources/complete-examples.md` - Full feature examples

---

**Remember:** Follow Feature-First architecture, use DI container, validate with Pydantic, test thoroughly!
