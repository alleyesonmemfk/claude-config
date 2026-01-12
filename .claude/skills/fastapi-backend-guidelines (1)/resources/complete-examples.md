# Complete Feature Examples - FastAPI Backend

## Full Feature: Blog Posts Management

A complete example of creating a feature from scratch.

---

## 1. SQLAlchemy Model

```python
# back/app/shared/models/post_models.py
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.shared.database.base import Base

class Post(Base):
    """Post model."""
    __tablename__ = "posts"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False, index=True)
    content = Column(Text, nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    user = relationship("User", back_populates="posts")
    category = relationship("Category", back_populates="posts")
```

---

## 2. Alembic Migration

```bash
cd back
alembic revision --autogenerate -m "Add posts table"
alembic upgrade head
```

Generated migration:

```python
# back/alembic/versions/xxx_add_posts_table.py
"""Add posts table

Revision ID: xxx
Revises: yyy
Create Date: 2025-11-23
"""
from alembic import op
import sqlalchemy as sa

def upgrade() -> None:
    op.create_table(
        'posts',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('title', sa.String(length=200), nullable=False),
        sa.Column('content', sa.Text(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('category_id', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['category_id'], ['categories.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_posts_id'), 'posts', ['id'], unique=False)
    op.create_index(op.f('ix_posts_title'), 'posts', ['title'], unique=False)

def downgrade() -> None:
    op.drop_index(op.f('ix_posts_title'), table_name='posts')
    op.drop_index(op.f('ix_posts_id'), table_name='posts')
    op.drop_table('posts')
```

---

## 3. Pydantic DTO

```python
# back/app/features/posts/dto/post_dto.py
from pydantic import BaseModel, Field, field_validator
from typing import Optional, List
from datetime import datetime

# Request DTO
class CreatePostRequest(BaseModel):
    """Request schema for post creation."""
    title: str = Field(..., min_length=1, max_length=200, description="Post title")
    content: str = Field(..., min_length=1, description="Post content")
    category_id: Optional[int] = Field(None, description="Category ID")

    @field_validator('title')
    @classmethod
    def title_not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError('Title cannot be empty or whitespace')
        return v.strip()

    @field_validator('content')
    @classmethod
    def content_not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError('Content cannot be empty')
        return v.strip()

class UpdatePostRequest(BaseModel):
    """Request schema for post update."""
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    content: Optional[str] = Field(None, min_length=1)
    category_id: Optional[int] = None

class PostFilterRequest(BaseModel):
    """Request schema for post filtering."""
    category_id: Optional[int] = None
    user_id: Optional[int] = None
    search: Optional[str] = Field(None, max_length=100)

# Response DTO
class PostResponse(BaseModel):
    """Post response schema."""
    id: int
    title: str
    content: str
    user_id: int
    category_id: Optional[int]
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}

class PostListResponse(BaseModel):
    """Paginated posts response schema."""
    posts: List[PostResponse]
    total: int
    skip: int
    limit: int
```

---

## 4. Repository

```python
# back/app/features/posts/repositories/post_repository.py
from typing import Optional, List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, or_

from app.shared.database.base_repository import BaseRepository
from app.shared.models.post_models import Post

class PostRepository(BaseRepository[Post]):
    """Post repository."""

    def __init__(self, db: AsyncSession):
        super().__init__(Post, db)

    async def get_by_user(self, user_id: int, skip: int = 0, limit: int = 10) -> List[Post]:
        """Get posts by user ID."""
        stmt = select(self.model).filter(
            self.model.user_id == user_id
        ).offset(skip).limit(limit).order_by(self.model.created_at.desc())

        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_by_category(self, category_id: int, skip: int = 0, limit: int = 10) -> List[Post]:
        """Get posts by category."""
        stmt = select(self.model).filter(
            self.model.category_id == category_id
        ).offset(skip).limit(limit).order_by(self.model.created_at.desc())

        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def search(
        self,
        query: str,
        category_id: Optional[int] = None,
        skip: int = 0,
        limit: int = 10
    ) -> List[Post]:
        """Search posts by title or content."""
        stmt = select(self.model).filter(
            or_(
                self.model.title.ilike(f"%{query}%"),
                self.model.content.ilike(f"%{query}%")
            )
        )

        if category_id:
            stmt = stmt.filter(self.model.category_id == category_id)

        stmt = stmt.offset(skip).limit(limit).order_by(self.model.created_at.desc())

        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def count_by_user(self, user_id: int) -> int:
        """Count user's posts."""
        stmt = select(func.count()).select_from(self.model).filter(
            self.model.user_id == user_id
        )
        result = await self.db.execute(stmt)
        return result.scalar() or 0
```

---

## 5. Service

```python
# back/app/features/posts/services/post_service.py
from typing import List, Optional

from app.features.posts.dto.post_dto import (
    CreatePostRequest,
    UpdatePostRequest,
    PostResponse,
    PostListResponse
)
from app.features.posts.repositories.post_repository import PostRepository
from app.core.logging import get_logger

logger = get_logger(__name__)

class PostService:
    """Post service with business logic."""

    def __init__(self, post_repository: PostRepository):
        self.post_repository = post_repository

    async def create_post(self, request: CreatePostRequest, user_id: int) -> PostResponse:
        """Create a new post."""
        logger.info("Creating post", extra={
            "user_id": user_id,
            "title": request.title
        })

        post_data = {
            "title": request.title,
            "content": request.content,
            "user_id": user_id,
            "category_id": request.category_id
        }

        post = await self.post_repository.create(post_data)

        logger.info("Post created", extra={"post_id": post.id})
        return PostResponse.model_validate(post)

    async def get_post(self, post_id: int) -> Optional[PostResponse]:
        """Get post by ID."""
        post = await self.post_repository.get_by_id(post_id)
        if not post:
            return None
        return PostResponse.model_validate(post)

    async def get_user_posts(
        self,
        user_id: int,
        skip: int = 0,
        limit: int = 10
    ) -> PostListResponse:
        """Get user's posts with pagination."""
        posts = await self.post_repository.get_by_user(user_id, skip, limit)
        total = await self.post_repository.count_by_user(user_id)

        return PostListResponse(
            posts=[PostResponse.model_validate(p) for p in posts],
            total=total,
            skip=skip,
            limit=limit
        )

    async def update_post(
        self,
        post_id: int,
        request: UpdatePostRequest,
        user_id: int
    ) -> Optional[PostResponse]:
        """Update post (owner only)."""
        post = await self.post_repository.get_by_id(post_id)

        if not post:
            return None

        if post.user_id != user_id:
            raise PermissionError("You can only update your own posts")

        update_data = request.model_dump(exclude_unset=True)
        updated_post = await self.post_repository.update(post_id, update_data)

        logger.info("Post updated", extra={"post_id": post_id, "user_id": user_id})
        return PostResponse.model_validate(updated_post)

    async def delete_post(self, post_id: int, user_id: int) -> bool:
        """Delete post (owner only)."""
        post = await self.post_repository.get_by_id(post_id)

        if not post:
            return False

        if post.user_id != user_id:
            raise PermissionError("You can only delete your own posts")

        await self.post_repository.delete(post_id)

        logger.info("Post deleted", extra={"post_id": post_id, "user_id": user_id})
        return True
```

---

## 6. Router (API)

```python
# back/app/features/posts/api/post_router.py
from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List

from app.features.posts.dto.post_dto import (
    CreatePostRequest,
    UpdatePostRequest,
    PostResponse,
    PostListResponse
)
from app.features.posts.services.post_service import PostService
from app.shared.dependencies.auth import get_current_user
from app.shared.models.user_models import User
from app.shared.di.container import create_service_dependency

router = APIRouter(prefix="/posts", tags=["posts"])

@router.post("/", response_model=PostResponse, status_code=201)
async def create_post(
    request: CreatePostRequest,
    current_user: User = Depends(get_current_user),
    post_service: PostService = Depends(create_service_dependency(PostService))
):
    """
    Create a new post.

    - **title**: Post title (required)
    - **content**: Post content (required)
    - **category_id**: Category ID (optional)
    """
    try:
        return await post_service.create_post(request, current_user.id)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error")

@router.get("/me", response_model=PostListResponse)
async def get_my_posts(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    post_service: PostService = Depends(create_service_dependency(PostService))
):
    """Get my posts with pagination."""
    return await post_service.get_user_posts(current_user.id, skip, limit)

@router.get("/{post_id}", response_model=PostResponse)
async def get_post(
    post_id: int,
    post_service: PostService = Depends(create_service_dependency(PostService))
):
    """Get post by ID."""
    post = await post_service.get_post(post_id)
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    return post

@router.put("/{post_id}", response_model=PostResponse)
async def update_post(
    post_id: int,
    request: UpdatePostRequest,
    current_user: User = Depends(get_current_user),
    post_service: PostService = Depends(create_service_dependency(PostService))
):
    """Update post (owner only)."""
    try:
        post = await post_service.update_post(post_id, request, current_user.id)
        if not post:
            raise HTTPException(status_code=404, detail="Post not found")
        return post
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.delete("/{post_id}", status_code=204)
async def delete_post(
    post_id: int,
    current_user: User = Depends(get_current_user),
    post_service: PostService = Depends(create_service_dependency(PostService))
):
    """Delete post (owner only)."""
    try:
        deleted = await post_service.delete_post(post_id, current_user.id)
        if not deleted:
            raise HTTPException(status_code=404, detail="Post not found")
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
```

---

## 7. DI Registration

```python
# back/app/features/posts/__init__.py
from app.shared.di.container import DIContainer

def setup_di(container: DIContainer):
    """Register post services in DI container."""
    from app.features.posts.services.post_service import PostService
    from app.features.posts.repositories.post_repository import PostRepository

    container.register_transient(PostRepository, PostRepository)
    container.register_transient(PostService, PostService)
```

```python
# back/main.py (add during app initialization)
from app.features.posts import setup_di as setup_posts_di
from app.features.posts.api.post_router import router as post_router

# Setup DI
setup_posts_di(di_container)

# Include router
app.include_router(post_router, prefix="/api/v2")
```

---

## 8. Complete File Structure

```
back/app/features/posts/
├── __init__.py                    # DI registration
├── api/
│   └── post_router.py             # FastAPI router
├── dto/
│   └── post_dto.py                # Pydantic schemas
├── services/
│   └── post_service.py            # Business logic
├── repositories/
│   └── post_repository.py         # Data access
└── tests/
    ├── test_post_service.py       # Service tests
    ├── test_post_repository.py    # Repository tests
    └── test_post_router.py        # API tests

back/app/shared/models/
└── post_models.py                  # SQLAlchemy model

back/alembic/versions/
└── xxx_add_posts_table.py          # Migration
```

---

## 9. Usage Example (cURL)

```bash
# Create post
curl -X POST http://localhost:4000/api/v2/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "title": "My first post",
    "content": "This is the content",
    "category_id": 1
  }'

# Get my posts
curl http://localhost:4000/api/v2/posts/me?skip=0&limit=10 \
  -H "Authorization: Bearer <token>"

# Get post by ID
curl http://localhost:4000/api/v2/posts/1

# Update post
curl -X PUT http://localhost:4000/api/v2/posts/1 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "title": "Updated title"
  }'

# Delete post
curl -X DELETE http://localhost:4000/api/v2/posts/1 \
  -H "Authorization: Bearer <token>"
```

---

**This is a complete, production-ready feature following all patterns!**
