# Router Patterns - FastAPI

## Basic Router Structure

```python
# back/app/features/items/api/item_router.py
from fastapi import APIRouter, Depends, HTTPException
from typing import List

from app.features.items.dto.item_dto import CreateItemRequest, ItemResponse
from app.features.items.services.item_service import ItemService
from app.shared.di.container import create_service_dependency

router = APIRouter(prefix="/items", tags=["items"])

@router.post("/", response_model=ItemResponse, status_code=201)
async def create_item(
    request: CreateItemRequest,
    item_service: ItemService = Depends(create_service_dependency(ItemService))
):
    """Create a new item."""
    try:
        item = await item_service.create_item(request)
        return item
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error")

@router.get("/", response_model=List[ItemResponse])
async def get_items(
    skip: int = 0,
    limit: int = 10,
    item_service: ItemService = Depends(create_service_dependency(ItemService))
):
    """Get list of items with pagination."""
    return await item_service.get_items(skip=skip, limit=limit)

@router.get("/{item_id}", response_model=ItemResponse)
async def get_item(
    item_id: int,
    item_service: ItemService = Depends(create_service_dependency(ItemService))
):
    """Get item by ID."""
    item = await item_service.get_item(item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    return item

@router.put("/{item_id}", response_model=ItemResponse)
async def update_item(
    item_id: int,
    request: UpdateItemRequest,
    item_service: ItemService = Depends(create_service_dependency(ItemService))
):
    """Update item by ID."""
    try:
        item = await item_service.update_item(item_id, request)
        if not item:
            raise HTTPException(status_code=404, detail="Item not found")
        return item
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.delete("/{item_id}", status_code=204)
async def delete_item(
    item_id: int,
    item_service: ItemService = Depends(create_service_dependency(ItemService))
):
    """Delete item by ID."""
    deleted = await item_service.delete_item(item_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Item not found")
```

## Patterns Checklist

- Use `APIRouter` with prefix and tags
- Inject services via `create_service_dependency()`
- Request/Response use Pydantic schemas
- Proper HTTP status codes (201, 404, 400, 500)
- Try/catch with specific exceptions
- Docstrings for each endpoint
- Delegate ALL business logic to service

## Router with Authentication

```python
from app.shared.dependencies.auth import get_current_user
from app.shared.models.user_models import User

@router.get("/me")
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user

@router.post("/", response_model=ItemResponse, status_code=201)
async def create_item(
    request: CreateItemRequest,
    current_user: User = Depends(get_current_user),
    item_service: ItemService = Depends(create_service_dependency(ItemService))
):
    """Create a new item (authenticated)."""
    return await item_service.create_item(request, user_id=current_user.id)
```

## Pagination Pattern

```python
from fastapi import Query

@router.get("/", response_model=PaginatedResponse)
async def get_items(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    service: Service = Depends(...)
):
    items = await service.get_all(skip=skip, limit=limit)
    total = await service.count()
    return PaginatedResponse(items=items, total=total, skip=skip, limit=limit)
```

## Feature Router Registration

```python
# back/main.py
from app.features.items.api.item_router import router as item_router

app.include_router(item_router, prefix="/api/v2")
```
