# Redux Toolkit Patterns

## createSlice Pattern

```typescript
// front/src/entities/Item/model/itemSlice.ts
import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import type { RootState } from 'app/providers/ReduxProvider/store';

interface Item {
  id: number;
  title: string;
  content: string;
  completed: boolean;
}

interface ItemState {
  items: Item[];
  selectedId: number | null;
  filter: 'all' | 'completed' | 'active';
}

const initialState: ItemState = {
  items: [],
  selectedId: null,
  filter: 'all'
};

export const itemSlice = createSlice({
  name: 'item',
  initialState,
  reducers: {
    setItems: (state, action: PayloadAction<Item[]>) => {
      state.items = action.payload;
    },
    selectItem: (state, action: PayloadAction<number>) => {
      state.selectedId = action.payload;
    },
    toggleCompleted: (state, action: PayloadAction<number>) => {
      const item = state.items.find(b => b.id === action.payload);
      if (item) {
        item.completed = !item.completed;
      }
    },
    setFilter: (state, action: PayloadAction<ItemState['filter']>) => {
      state.filter = action.payload;
    }
  }
});

// Actions
export const { setItems, selectItem, toggleCompleted, setFilter } = itemSlice.actions;

// Selectors
export const selectAllItems = (state: RootState) => state.item.items;
export const selectSelectedId = (state: RootState) => state.item.selectedId;
export const selectFilter = (state: RootState) => state.item.filter;
export const selectFilteredItems = (state: RootState) => {
  const { items, filter } = state.item;
  switch (filter) {
    case 'completed': return items.filter(b => b.completed);
    case 'active': return items.filter(b => !b.completed);
    default: return items;
  }
};

// Reducer
export default itemSlice.reducer;
```

## Patterns Checklist

- Redux Toolkit `createSlice`
- Typed state interface
- Selectors exported
- Actions exported
- Immer for immutability (built into RTK)

## Using in Component

```typescript
// front/src/widgets/ItemList/ui/ItemList.tsx
import { useAppDispatch, useAppSelector } from 'app/providers/ReduxProvider/hooks';
import { selectFilteredItems, toggleCompleted } from 'entities/Item';

export const ItemList: FC = () => {
  const dispatch = useAppDispatch();
  const items = useAppSelector(selectFilteredItems);

  const handleToggle = (id: number) => {
    dispatch(toggleCompleted(id));
  };

  return (
    <div>
      {items.map(item => (
        <div key={item.id} onClick={() => handleToggle(item.id)}>
          {item.title} - {item.completed ? 'Done' : 'Pending'}
        </div>
      ))}
    </div>
  );
};
```

## Typed Hooks

```typescript
// front/src/app/providers/ReduxProvider/hooks.ts
import { useDispatch, useSelector, TypedUseSelectorHook } from 'react-redux';
import type { RootState, AppDispatch } from './store';

export const useAppDispatch = () => useDispatch<AppDispatch>();
export const useAppSelector: TypedUseSelectorHook<RootState> = useSelector;
```

## Store Configuration

```typescript
// front/src/app/providers/ReduxProvider/store.ts
import { configureStore } from '@reduxjs/toolkit';
import itemReducer from 'entities/Item/model/itemSlice';
import sidebarReducer from 'widgets/Sidebar/model/sidebarSlice';

export const store = configureStore({
  reducer: {
    item: itemReducer,
    sidebar: sidebarReducer,
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware({
      serializableCheck: false,
    }),
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
```

## Async Actions with createAsyncThunk

```typescript
import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import { api } from 'shared/api';

export const fetchItems = createAsyncThunk(
  'item/fetchItems',
  async (_, { rejectWithValue }) => {
    try {
      const response = await api.get('/api/v2/items');
      return response.data;
    } catch (error) {
      return rejectWithValue(error.message);
    }
  }
);

const itemSlice = createSlice({
  name: 'item',
  initialState: {
    items: [],
    loading: false,
    error: null as string | null,
  },
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(fetchItems.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchItems.fulfilled, (state, action) => {
        state.loading = false;
        state.items = action.payload;
      })
      .addCase(fetchItems.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      });
  },
});
```

## Memoized Selectors (reselect)

```typescript
import { createSelector } from '@reduxjs/toolkit';

const selectItems = (state: RootState) => state.item.items;
const selectFilter = (state: RootState) => state.item.filter;

// Memoized selector - recalculates only when items or filter change
export const selectFilteredItems = createSelector(
  [selectItems, selectFilter],
  (items, filter) => {
    switch (filter) {
      case 'completed': return items.filter(b => b.completed);
      case 'active': return items.filter(b => !b.completed);
      default: return items;
    }
  }
);
```
