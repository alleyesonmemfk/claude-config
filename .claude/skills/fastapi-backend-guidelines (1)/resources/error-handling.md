# Error Handling Patterns

## Structured Error Handling in Routes

```python
from fastapi import HTTPException
from app.core.logging import get_logger

logger = get_logger(__name__)

@router.post("/items")
async def create_item(request: CreateItemRequest, service: ItemService = Depends(...)):
    try:
        item = await service.create_item(request)
        return item
    except ValueError as e:
        # Business logic error (400)
        logger.warning("Validation error", extra={"error": str(e), "request": request.model_dump()})
        raise HTTPException(status_code=400, detail=str(e))
    except PermissionError as e:
        # Authorization error (403)
        logger.warning("Access denied", extra={"error": str(e)})
        raise HTTPException(status_code=403, detail="Access denied")
    except Exception as e:
        # Unexpected error (500)
        logger.error("Unexpected error creating item", exc_info=True, extra={"request": request.model_dump()})
        raise HTTPException(status_code=500, detail="Internal server error")
```

## HTTP Status Codes

| Code | Name | When to Use |
|------|------|-------------|
| 200 | OK | Successful GET, PUT |
| 201 | Created | Successful POST |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Validation error, invalid data |
| 401 | Unauthorized | Not authenticated |
| 403 | Forbidden | Authenticated but not authorized |
| 404 | Not Found | Resource not found |
| 409 | Conflict | Resource already exists |
| 422 | Unprocessable Entity | Validation error (Pydantic) |
| 500 | Internal Server Error | Unexpected server error |

## Custom Exception Classes

```python
# back/app/core/exceptions.py
class AppException(Exception):
    """Base application exception."""
    def __init__(self, message: str, code: str = None):
        self.message = message
        self.code = code
        super().__init__(message)

class NotFoundError(AppException):
    """Resource not found."""
    pass

class ValidationError(AppException):
    """Validation error."""
    pass

class AuthenticationError(AppException):
    """Authentication error."""
    pass

class AuthorizationError(AppException):
    """Authorization error."""
    pass

class ConflictError(AppException):
    """Resource conflict."""
    pass
```

## Global Exception Handlers

```python
# back/app/core/error_handlers.py
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from app.core.exceptions import (
    NotFoundError, ValidationError, AuthenticationError,
    AuthorizationError, ConflictError
)
from app.core.logging import get_logger

logger = get_logger(__name__)

def setup_exception_handlers(app: FastAPI):
    @app.exception_handler(NotFoundError)
    async def not_found_handler(request: Request, exc: NotFoundError):
        return JSONResponse(
            status_code=404,
            content={"detail": exc.message, "code": exc.code}
        )

    @app.exception_handler(ValidationError)
    async def validation_handler(request: Request, exc: ValidationError):
        logger.warning("Validation error", extra={"error": exc.message})
        return JSONResponse(
            status_code=400,
            content={"detail": exc.message, "code": exc.code}
        )

    @app.exception_handler(AuthenticationError)
    async def auth_handler(request: Request, exc: AuthenticationError):
        return JSONResponse(
            status_code=401,
            content={"detail": exc.message}
        )

    @app.exception_handler(AuthorizationError)
    async def authz_handler(request: Request, exc: AuthorizationError):
        return JSONResponse(
            status_code=403,
            content={"detail": exc.message}
        )

    @app.exception_handler(ConflictError)
    async def conflict_handler(request: Request, exc: ConflictError):
        return JSONResponse(
            status_code=409,
            content={"detail": exc.message}
        )

    @app.exception_handler(Exception)
    async def generic_handler(request: Request, exc: Exception):
        logger.error("Unhandled exception", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"detail": "Internal server error"}
        )
```

## Usage in Services

```python
from app.core.exceptions import NotFoundError, ValidationError, ConflictError

class UserService:
    async def create_user(self, request: CreateUserRequest) -> UserResponse:
        # Check if email exists
        existing = await self.user_repository.get_by_email(request.email)
        if existing:
            raise ConflictError("User with this email already exists", code="EMAIL_EXISTS")

        # Validate password complexity
        if len(request.password) < 8:
            raise ValidationError("Password must be at least 8 characters", code="WEAK_PASSWORD")

        user = await self.user_repository.create(...)
        return UserResponse.model_validate(user)

    async def get_user(self, user_id: int) -> UserResponse:
        user = await self.user_repository.get_by_id(user_id)
        if not user:
            raise NotFoundError(f"User {user_id} not found", code="USER_NOT_FOUND")
        return UserResponse.model_validate(user)
```
