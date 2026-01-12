# DTO Patterns - Pydantic Schemas

## Request/Response DTO

```python
# back/app/features/items/dto/item_dto.py
from pydantic import BaseModel, Field, field_validator
from typing import Optional, List
from datetime import datetime

# Request DTO
class CreateItemRequest(BaseModel):
    """Schema for item creation request."""
    title: str = Field(..., min_length=1, max_length=200)
    content: str = Field(..., min_length=1)
    category_id: Optional[int] = None

    @field_validator('title')
    @classmethod
    def title_must_not_be_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError('Title cannot be empty')
        return v.strip()

class UpdateItemRequest(BaseModel):
    """Schema for item update request."""
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    content: Optional[str] = Field(None, min_length=1)
    category_id: Optional[int] = None

# Response DTO
class ItemResponse(BaseModel):
    """Schema for item response."""
    id: int
    title: str
    content: str
    category_id: Optional[int]
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}  # Pydantic v2

class ItemListResponse(BaseModel):
    """Schema for paginated items response."""
    items: List[ItemResponse]
    total: int
    skip: int
    limit: int
```

## Patterns Checklist

- Separate Request and Response DTOs
- Use `Field()` for validation constraints
- Custom validators with `@field_validator`
- `model_config = {"from_attributes": True}` for SQLAlchemy
- Optional fields for updates
- Docstrings for each schema

## Advanced Validators

```python
from pydantic import field_validator, model_validator
import re

class UserCreateRequest(BaseModel):
    email: str
    password: str = Field(..., min_length=8)
    password_confirm: str

    @field_validator('email')
    @classmethod
    def validate_email(cls, v: str) -> str:
        if not re.match(r'^[\w\.-]+@[\w\.-]+\.\w+$', v):
            raise ValueError('Invalid email format')
        return v.lower()

    @model_validator(mode='after')
    def passwords_match(self):
        if self.password != self.password_confirm:
            raise ValueError('Passwords do not match')
        return self
```

## Nested DTOs

```python
class CategoryResponse(BaseModel):
    id: int
    name: str

    model_config = {"from_attributes": True}

class ItemWithCategoryResponse(BaseModel):
    id: int
    title: str
    content: str
    category: Optional[CategoryResponse]

    model_config = {"from_attributes": True}
```

## Enum in DTO

```python
from enum import Enum

class ItemStatus(str, Enum):
    DRAFT = "draft"
    PUBLISHED = "published"
    ARCHIVED = "archived"

class ItemResponse(BaseModel):
    id: int
    title: str
    status: ItemStatus

    model_config = {"from_attributes": True}
```
