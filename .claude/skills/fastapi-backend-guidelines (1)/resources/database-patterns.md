# Database Patterns - SQLAlchemy & Alembic

## Creating Migration

```bash
# After adding/modifying SQLAlchemy models:
cd back
alembic revision --autogenerate -m "Add items table"
alembic upgrade head
```

## Migration File Example

```python
# back/alembic/versions/xxx_add_items_table.py
"""Add items table

Revision ID: xxx
Revises: yyy
Create Date: 2024-01-01 00:00:00.000000
"""
from alembic import op
import sqlalchemy as sa

# revision identifiers
revision = 'xxx'
down_revision = 'yyy'
branch_labels = None
depends_on = None

def upgrade() -> None:
    op.create_table(
        'items',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('title', sa.String(length=200), nullable=False),
        sa.Column('content', sa.Text(), nullable=False),
        sa.Column('category_id', sa.Integer(), nullable=True),
        sa.Column('status', sa.String(length=20), nullable=False, server_default='draft'),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.func.now(), onupdate=sa.func.now()),
        sa.ForeignKeyConstraint(['category_id'], ['categories.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_items_title', 'items', ['title'])
    op.create_index('ix_items_category_id', 'items', ['category_id'])

def downgrade() -> None:
    op.drop_index('ix_items_category_id', table_name='items')
    op.drop_index('ix_items_title', table_name='items')
    op.drop_table('items')
```

## SQLAlchemy Model

```python
# back/app/shared/models/item_models.py
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, func
from sqlalchemy.orm import relationship
from app.shared.database.base import Base

class Item(Base):
    __tablename__ = 'items'

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False, index=True)
    content = Column(Text, nullable=False)
    category_id = Column(Integer, ForeignKey('categories.id', ondelete='SET NULL'), nullable=True, index=True)
    status = Column(String(20), nullable=False, default='draft')
    created_at = Column(DateTime, nullable=False, server_default=func.now())
    updated_at = Column(DateTime, nullable=False, server_default=func.now(), onupdate=func.now())

    # Relationships
    category = relationship("Category", back_populates="items")

class Category(Base):
    __tablename__ = 'categories'

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False, unique=True)
    description = Column(Text, nullable=True)

    # Relationships
    items = relationship("Item", back_populates="category")
```

## Common Migration Operations

```python
# Add column
op.add_column('items', sa.Column('slug', sa.String(200), nullable=True))

# Drop column
op.drop_column('items', 'slug')

# Add index
op.create_index('ix_items_slug', 'items', ['slug'], unique=True)

# Drop index
op.drop_index('ix_items_slug', table_name='items')

# Add foreign key
op.create_foreign_key(
    'fk_items_author',
    'items', 'users',
    ['author_id'], ['id'],
    ondelete='CASCADE'
)

# Data migration
from sqlalchemy.sql import table, column
items = table('items', column('status', sa.String))
op.execute(items.update().values(status='published').where(items.c.status == None))

# Alter column type
op.alter_column('items', 'status',
    existing_type=sa.String(20),
    type_=sa.String(50),
    existing_nullable=False
)
```

## Database Session

```python
# back/app/shared/database/session.py
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from app.core.settings import settings

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    pool_pre_ping=True,
    pool_size=5,
    max_overflow=10
)

async_session = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False
)

async def get_db() -> AsyncSession:
    async with async_session() as session:
        try:
            yield session
        finally:
            await session.close()
```

## Useful Alembic Commands

```bash
# Check current revision
alembic current

# View migration history
alembic history

# Rollback one revision
alembic downgrade -1

# Rollback to specific revision
alembic downgrade abc123

# Upgrade to specific revision
alembic upgrade abc123

# Create empty migration
alembic revision -m "manual migration"

# Mark database as current revision (without running migration)
alembic stamp head
```
