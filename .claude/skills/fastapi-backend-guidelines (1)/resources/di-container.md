# Dependency Injection Container

## Service Registration

```python
# back/app/shared/di/container.py (already exists)
# Usage when initializing feature:

from app.shared.di.container import DIContainer, create_service_dependency

# During application startup (in main.py or feature's __init__):
def setup_item_services(container: DIContainer):
    """Register item services in DI container."""
    from app.features.items.services.item_service import ItemService
    from app.features.items.repositories.item_repository import ItemRepository

    # Register repository (transient - new instance per request)
    container.register_transient(ItemRepository, ItemRepository)

    # Register service (transient)
    container.register_transient(ItemService, ItemService)
```

## Usage in Routes

```python
# In router:
from app.shared.di.container import create_service_dependency

@router.post("/")
async def create_item(
    request: CreateItemRequest,
    item_service: ItemService = Depends(create_service_dependency(ItemService))
):
    return await item_service.create_item(request)
```

## Container Implementation

```python
# back/app/shared/di/container.py
from typing import Type, TypeVar, Callable, Dict, Any
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.shared.database.session import get_db

T = TypeVar('T')

class DIContainer:
    """Simple dependency injection container."""

    _services: Dict[Type, Callable] = {}

    @classmethod
    def register_transient(cls, interface: Type[T], implementation: Type[T]):
        """Register service that creates new instance per request."""
        cls._services[interface] = implementation

    @classmethod
    def resolve(cls, interface: Type[T], db: AsyncSession) -> T:
        """Resolve service instance."""
        if interface not in cls._services:
            raise ValueError(f"Service {interface} not registered")

        implementation = cls._services[interface]

        # Check constructor parameters
        import inspect
        sig = inspect.signature(implementation)
        kwargs = {}

        for param_name, param in sig.parameters.items():
            param_type = param.annotation

            if param_type == AsyncSession:
                kwargs[param_name] = db
            elif param_type in cls._services:
                # Recursively resolve dependencies
                kwargs[param_name] = cls.resolve(param_type, db)

        return implementation(**kwargs)

def create_service_dependency(service_class: Type[T]) -> Callable:
    """Create FastAPI dependency for service."""
    def dependency(db: AsyncSession = Depends(get_db)) -> T:
        return DIContainer.resolve(service_class, db)
    return dependency
```

## Registration in main.py

```python
# back/main.py
from fastapi import FastAPI
from app.shared.di.container import DIContainer

# Import feature setup functions
from app.features.items.setup import setup_item_services
from app.features.auth.setup import setup_auth_services
from app.features.orders.setup import setup_order_services

app = FastAPI()

# Setup DI container
container = DIContainer()
setup_item_services(container)
setup_auth_services(container)
setup_order_services(container)
```

## Feature Setup Pattern

```python
# back/app/features/items/setup.py
from app.shared.di.container import DIContainer

def setup_item_services(container: DIContainer):
    """Register all item-related services."""
    from app.features.items.services.item_service import ItemService
    from app.features.items.repositories.item_repository import ItemRepository

    container.register_transient(ItemRepository, ItemRepository)
    container.register_transient(ItemService, ItemService)

# back/app/features/items/__init__.py
from app.features.items.api.item_router import router
from app.features.items.setup import setup_item_services

__all__ = ['router', 'setup_item_services']
```
