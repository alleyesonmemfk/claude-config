# Repository Patterns

## Repository with BaseRepository

```python
# back/app/features/items/repositories/item_repository.py
from typing import Optional, List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete

from app.shared.database.base_repository import BaseRepository
from app.shared.models.item_models import Item, Category

class ItemRepository(BaseRepository[Item]):
    """Repository for item data access."""

    def __init__(self, db: AsyncSession):
        super().__init__(Item, db)

    async def get_by_category(self, category_id: int) -> List[Item]:
        """Get all items in a category."""
        stmt = select(self.model).filter(self.model.category_id == category_id)
        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def get_category(self, category_id: int) -> Optional[Category]:
        """Get category by ID."""
        stmt = select(Category).filter(Category.id == category_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def search_by_title(self, query: str) -> List[Item]:
        """Search items by title."""
        stmt = select(self.model).filter(
            self.model.title.ilike(f"%{query}%")
        )
        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def get_with_category(self, item_id: int) -> Optional[Item]:
        """Get item with loaded category relationship."""
        from sqlalchemy.orm import selectinload

        stmt = (
            select(self.model)
            .options(selectinload(self.model.category))
            .filter(self.model.id == item_id)
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
```

## Patterns Checklist

- Inherit from `BaseRepository[Model]`
- Constructor accepts `AsyncSession`
- Domain-specific query methods
- Use SQLAlchemy 2.0 syntax (`select()`)
- Type hints for all methods
- Use `selectinload` for eager loading relationships

## BaseRepository Implementation

```python
# back/app/shared/database/base_repository.py
from typing import TypeVar, Generic, Optional, List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete

T = TypeVar('T')

class BaseRepository(Generic[T]):
    """Base repository with common CRUD operations."""

    def __init__(self, model: type[T], db: AsyncSession):
        self.model = model
        self.db = db

    async def get_by_id(self, id: int) -> Optional[T]:
        stmt = select(self.model).filter(self.model.id == id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_all(self, skip: int = 0, limit: int = 100) -> List[T]:
        stmt = select(self.model).offset(skip).limit(limit)
        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def create(self, data: Dict[str, Any]) -> T:
        instance = self.model(**data)
        self.db.add(instance)
        await self.db.commit()
        await self.db.refresh(instance)
        return instance

    async def update(self, id: int, data: Dict[str, Any]) -> Optional[T]:
        stmt = (
            update(self.model)
            .where(self.model.id == id)
            .values(**data)
            .returning(self.model)
        )
        result = await self.db.execute(stmt)
        await self.db.commit()
        return result.scalar_one_or_none()

    async def delete(self, id: int) -> bool:
        stmt = delete(self.model).where(self.model.id == id)
        result = await self.db.execute(stmt)
        await self.db.commit()
        return result.rowcount > 0

    async def count(self) -> int:
        from sqlalchemy import func
        stmt = select(func.count()).select_from(self.model)
        result = await self.db.execute(stmt)
        return result.scalar()
```

## Complex Queries

```python
class ItemRepository(BaseRepository[Item]):

    async def get_items_with_filters(
        self,
        category_id: Optional[int] = None,
        status: Optional[str] = None,
        search: Optional[str] = None,
        skip: int = 0,
        limit: int = 10
    ) -> List[Item]:
        """Get items with multiple filters."""
        stmt = select(self.model)

        if category_id:
            stmt = stmt.filter(self.model.category_id == category_id)
        if status:
            stmt = stmt.filter(self.model.status == status)
        if search:
            stmt = stmt.filter(self.model.title.ilike(f"%{search}%"))

        stmt = stmt.order_by(self.model.created_at.desc())
        stmt = stmt.offset(skip).limit(limit)

        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def get_items_count_by_category(self) -> List[Dict]:
        """Get item count grouped by category."""
        from sqlalchemy import func

        stmt = (
            select(
                self.model.category_id,
                func.count(self.model.id).label('count')
            )
            .group_by(self.model.category_id)
        )
        result = await self.db.execute(stmt)
        return [{"category_id": row[0], "count": row[1]} for row in result.all()]
```
