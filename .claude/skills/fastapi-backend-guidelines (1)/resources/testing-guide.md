# Testing Guide

## Service Tests

```python
# back/app/features/items/tests/test_item_service.py
import pytest
from unittest.mock import AsyncMock, MagicMock
from datetime import datetime

from app.features.items.services.item_service import ItemService
from app.features.items.dto.item_dto import CreateItemRequest, ItemResponse

@pytest.fixture
def mock_repository():
    return AsyncMock()

@pytest.fixture
def item_service(mock_repository):
    return ItemService(item_repository=mock_repository)

@pytest.mark.asyncio
async def test_create_item_success(item_service, mock_repository):
    # Arrange
    request = CreateItemRequest(title="Test", content="Content", category_id=None)
    mock_repository.create.return_value = MagicMock(
        id=1,
        title="Test",
        content="Content",
        category_id=None,
        created_at=datetime.now(),
        updated_at=datetime.now()
    )

    # Act
    result = await item_service.create_item(request)

    # Assert
    assert result.title == "Test"
    assert result.id == 1
    mock_repository.create.assert_called_once()

@pytest.mark.asyncio
async def test_create_item_with_invalid_category(item_service, mock_repository):
    # Arrange
    request = CreateItemRequest(title="Test", content="Content", category_id=999)
    mock_repository.get_category.return_value = None

    # Act & Assert
    with pytest.raises(ValueError, match="Category 999 not found"):
        await item_service.create_item(request)

@pytest.mark.asyncio
async def test_get_item_not_found(item_service, mock_repository):
    # Arrange
    mock_repository.get_by_id.return_value = None

    # Act
    result = await item_service.get_item(999)

    # Assert
    assert result is None
    mock_repository.get_by_id.assert_called_once_with(999)
```

## API Integration Tests

```python
# back/app/features/items/tests/test_item_api.py
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from main import app
from app.shared.database.session import get_db

@pytest.fixture
async def client(db_session: AsyncSession):
    """Create test client with overridden database."""
    def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db

    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client

    app.dependency_overrides.clear()

@pytest.mark.asyncio
async def test_create_item(client: AsyncClient):
    # Arrange
    item_data = {
        "title": "Test Item",
        "content": "Test content"
    }

    # Act
    response = await client.post("/api/v2/items/", json=item_data)

    # Assert
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == "Test Item"
    assert "id" in data

@pytest.mark.asyncio
async def test_create_item_validation_error(client: AsyncClient):
    # Arrange - empty title
    item_data = {
        "title": "",
        "content": "Test content"
    }

    # Act
    response = await client.post("/api/v2/items/", json=item_data)

    # Assert
    assert response.status_code == 422  # Pydantic validation

@pytest.mark.asyncio
async def test_get_item_not_found(client: AsyncClient):
    # Act
    response = await client.get("/api/v2/items/99999")

    # Assert
    assert response.status_code == 404
```

## Repository Tests

```python
# back/app/features/items/tests/test_item_repository.py
import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.features.items.repositories.item_repository import ItemRepository
from app.shared.models.item_models import Item

@pytest.fixture
def repository(db_session: AsyncSession):
    return ItemRepository(db_session)

@pytest.mark.asyncio
async def test_create_item(repository: ItemRepository):
    # Act
    item = await repository.create({
        "title": "Test Item",
        "content": "Test content"
    })

    # Assert
    assert item.id is not None
    assert item.title == "Test Item"

@pytest.mark.asyncio
async def test_get_by_id(repository: ItemRepository, db_session: AsyncSession):
    # Arrange
    item = Item(title="Test", content="Content")
    db_session.add(item)
    await db_session.commit()

    # Act
    result = await repository.get_by_id(item.id)

    # Assert
    assert result is not None
    assert result.title == "Test"

@pytest.mark.asyncio
async def test_search_by_title(repository: ItemRepository, db_session: AsyncSession):
    # Arrange
    items = [
        Item(title="Python Tutorial", content="..."),
        Item(title="JavaScript Guide", content="..."),
        Item(title="Advanced Python", content="...")
    ]
    db_session.add_all(items)
    await db_session.commit()

    # Act
    results = await repository.search_by_title("Python")

    # Assert
    assert len(results) == 2
```

## Test Configuration

```python
# back/conftest.py
import pytest
import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from app.shared.database.base import Base

TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture(scope="session")
async def engine():
    engine = create_async_engine(TEST_DATABASE_URL, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()

@pytest.fixture
async def db_session(engine):
    async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with async_session() as session:
        yield session
        await session.rollback()
```

## Running Tests

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html

# Run specific test file
pytest app/features/items/tests/test_item_service.py

# Run specific test
pytest app/features/items/tests/test_item_service.py::test_create_item_success

# Run with verbose output
pytest -v

# Run only marked tests
pytest -m "asyncio"
```
