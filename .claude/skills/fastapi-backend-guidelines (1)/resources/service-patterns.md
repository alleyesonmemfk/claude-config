# Service Layer Patterns

## Service with DI

```python
# back/app/features/items/services/item_service.py
from typing import List, Optional

from app.features.items.dto.item_dto import CreateItemRequest, UpdateItemRequest, ItemResponse
from app.features.items.repositories.item_repository import ItemRepository
from app.core.logging import get_logger

logger = get_logger(__name__)

class ItemService:
    """Service for item business logic."""

    def __init__(self, item_repository: ItemRepository):
        self.item_repository = item_repository

    async def create_item(self, request: CreateItemRequest) -> ItemResponse:
        """Create a new item."""
        logger.info("Creating item", extra={"title": request.title})

        # Business validation
        if request.category_id:
            category = await self.item_repository.get_category(request.category_id)
            if not category:
                logger.warning("Category not found", extra={"category_id": request.category_id})
                raise ValueError(f"Category {request.category_id} not found")

        # Create item
        item = await self.item_repository.create({
            "title": request.title,
            "content": request.content,
            "category_id": request.category_id
        })

        logger.info("Item created", extra={"item_id": item.id})
        return ItemResponse.model_validate(item)

    async def get_items(self, skip: int = 0, limit: int = 10) -> List[ItemResponse]:
        """Get paginated items."""
        items = await self.item_repository.get_all(skip=skip, limit=limit)
        return [ItemResponse.model_validate(item) for item in items]

    async def get_item(self, item_id: int) -> Optional[ItemResponse]:
        """Get item by ID."""
        item = await self.item_repository.get_by_id(item_id)
        if not item:
            return None
        return ItemResponse.model_validate(item)

    async def update_item(self, item_id: int, request: UpdateItemRequest) -> Optional[ItemResponse]:
        """Update item by ID."""
        item = await self.item_repository.get_by_id(item_id)
        if not item:
            return None

        update_data = request.model_dump(exclude_unset=True)
        updated_item = await self.item_repository.update(item_id, update_data)

        logger.info("Item updated", extra={"item_id": item_id})
        return ItemResponse.model_validate(updated_item)

    async def delete_item(self, item_id: int) -> bool:
        """Delete item by ID."""
        deleted = await self.item_repository.delete(item_id)
        if deleted:
            logger.info("Item deleted", extra={"item_id": item_id})
        return deleted
```

## Patterns Checklist

- Constructor injection of repositories
- Business logic validation
- Structured logging with context
- Return DTOs, not models
- Use `model_validate()` for Pydantic v2
- Handle edge cases (not found, invalid data)

## Service with Multiple Repositories

```python
class OrderService:
    def __init__(
        self,
        order_repository: OrderRepository,
        product_repository: ProductRepository,
        user_repository: UserRepository
    ):
        self.order_repository = order_repository
        self.product_repository = product_repository
        self.user_repository = user_repository

    async def create_order(self, request: CreateOrderRequest, user_id: int) -> OrderResponse:
        # Check user exists
        user = await self.user_repository.get_by_id(user_id)
        if not user:
            raise ValueError("User not found")

        # Check products exist and calculate total
        total = 0
        for item in request.items:
            product = await self.product_repository.get_by_id(item.product_id)
            if not product:
                raise ValueError(f"Product {item.product_id} not found")
            total += product.price * item.quantity

        # Create order
        order = await self.order_repository.create({
            "user_id": user_id,
            "total": total,
            "items": request.items
        })

        return OrderResponse.model_validate(order)
```

## Service with External API

```python
import httpx

class PaymentService:
    def __init__(self, payment_repository: PaymentRepository):
        self.payment_repository = payment_repository
        self.api_url = settings.PAYMENT_API_URL
        self.api_key = settings.PAYMENT_API_KEY

    async def process_payment(self, amount: int, user_id: int) -> PaymentResponse:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.api_url}/charge",
                json={"amount": amount},
                headers={"Authorization": f"Bearer {self.api_key}"}
            )

            if response.status_code != 200:
                logger.error("Payment error", extra={"status": response.status_code})
                raise ValueError("Payment processing error")

            payment_data = response.json()

        # Save to database
        payment = await self.payment_repository.create({
            "user_id": user_id,
            "amount": amount,
            "external_id": payment_data["id"],
            "status": "completed"
        })

        return PaymentResponse.model_validate(payment)
```
