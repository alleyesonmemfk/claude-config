# Complete Examples - React Frontend (FSD)

Complete examples of components across all FSD architecture layers.

---

## 1. Page Example: Items Page

```typescript
// front/src/pages/Items/ui/ItemsPage.tsx
import { FC, useState } from 'react';
import { useSearchParams } from 'react-router-dom';

import { ItemSearch } from 'features/ItemSearch';
import { CategoryFilter } from 'features/CategoryFilter';
import { CategorySidebar } from 'widgets/CategorySidebar';
import { PageWrapper } from 'shared/components/PageWrapper';
import { Loading } from 'shared/components/Loading';
import { useGetCategories, useSearchItems } from 'shared/api/generated/items/items';

import styles from './ItemsPage.module.scss';

export const ItemsPage: FC = () => {
  const [searchParams, setSearchParams] = useSearchParams();
  const [selectedCategory, setSelectedCategory] = useState<number | null>(null);

  const categoryId = searchParams.get('category');
  const searchQuery = searchParams.get('q') || '';

  // React Query for categories
  const { data: categories, isLoading: categoriesLoading } = useGetCategories();

  // React Query for items
  const { data: itemsData, isLoading: itemsLoading } = useSearchItems({
    query: searchQuery,
    category_id: categoryId ? parseInt(categoryId) : undefined
  });

  const handleSearch = (query: string) => {
    setSearchParams({ q: query, category: categoryId || '' });
  };

  const handleCategorySelect = (id: number) => {
    setSelectedCategory(id);
    setSearchParams({ q: searchQuery, category: id.toString() });
  };

  if (categoriesLoading) {
    return <Loading fullScreen />;
  }

  return (
    <PageWrapper title="Items" className={styles.page}>
      <div className={styles.layout}>
        {/* Sidebar with categories */}
        <aside className={styles.sidebar}>
          <CategorySidebar
            categories={categories?.data || []}
            selectedId={selectedCategory}
            onSelect={handleCategorySelect}
          />
        </aside>

        {/* Main content */}
        <main className={styles.content}>
          {/* Search */}
          <ItemSearch
            initialValue={searchQuery}
            onSearch={handleSearch}
          />

          {/* Filters */}
          <CategoryFilter
            categories={categories?.data || []}
            selected={categoryId ? parseInt(categoryId) : null}
            onChange={handleCategorySelect}
          />

          {/* Items */}
          {itemsLoading ? (
            <Loading />
          ) : (
            <div className={styles.items}>
              {itemsData?.data.map(item => (
                <div key={item.id} className={styles.itemCard}>
                  <h3>{item.title}</h3>
                  <div className={styles.meta}>
                    <span className={styles.author}>{item.author}</span>
                    <span className={styles.category}>{item.category_name}</span>
                  </div>
                </div>
              ))}

              {itemsData?.data.length === 0 && (
                <div className={styles.empty}>
                  No items found
                </div>
              )}
            </div>
          )}
        </main>
      </div>
    </PageWrapper>
  );
};
```

```scss
// front/src/pages/Items/ui/ItemsPage.module.scss
@import 'app/styles/variables';
@import 'app/styles/mixins';

.page {
  min-height: 100vh;
}

.layout {
  display: grid;
  grid-template-columns: 280px 1fr;
  gap: $spacing-xl;
  max-width: 1400px;
  margin: 0 auto;
  padding: $spacing-lg;

  @include respond-to(tablet) {
    grid-template-columns: 1fr;
  }
}

.sidebar {
  @include respond-to(tablet) {
    display: none; // Hide on mobile
  }
}

.content {
  display: flex;
  flex-direction: column;
  gap: $spacing-lg;
}

.items {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: $spacing-md;
}

.itemCard {
  padding: $spacing-md;
  background: var(--bg-secondary);
  border-radius: $border-radius-md;
  border: 1px solid var(--border-color);
  transition: all 0.2s;

  &:hover {
    border-color: var(--color-primary);
    box-shadow: $shadow-md;
    transform: translateY(-2px);
  }

  h3 {
    font-size: $font-size-lg;
    margin-bottom: $spacing-sm;
    color: var(--text-primary);
  }
}

.meta {
  display: flex;
  gap: $spacing-sm;
  font-size: $font-size-sm;
}

.author {
  color: var(--color-primary);
  font-weight: $font-weight-medium;
}

.category {
  color: var(--text-secondary);
}

.empty {
  text-align: center;
  padding: $spacing-xl;
  color: var(--text-secondary);
  font-size: $font-size-lg;
}
```

```typescript
// front/src/pages/Items/index.ts
export { ItemsPage } from './ui/ItemsPage';
```

---

## 2. Widget Example: Code Editor Widget

```typescript
// front/src/widgets/CodeEditorWidget/ui/CodeEditorWidget.tsx
import { FC, useState } from 'react';
import { useForm } from 'react-hook-form';

import { CodeEditor } from 'shared/components/CodeEditor';
import { Button } from 'shared/components/Button';
import { Loading } from 'shared/components/Loading';
import { useExecuteCodeMutation } from 'shared/api/generated/codeEditor/codeEditor';
import { getCodeTemplate } from 'shared/utils/codeTemplateGenerator';

import styles from './CodeEditorWidget.module.scss';

interface CodeEditorWidgetProps {
  taskId?: number;
  initialLanguage?: string;
  onSuccess?: (result: any) => void;
}

export const CodeEditorWidget: FC<CodeEditorWidgetProps> = ({
  taskId,
  initialLanguage = 'python',
  onSuccess
}) => {
  const [language, setLanguage] = useState(initialLanguage);
  const [code, setCode] = useState(() => getCodeTemplate(language));

  const { mutate: executeCode, isPending, data: result } = useExecuteCodeMutation({
    onSuccess: (data) => {
      onSuccess?.(data);
    }
  });

  const handleRun = () => {
    executeCode({
      data: {
        code,
        language,
        task_id: taskId
      }
    });
  };

  const handleLanguageChange = (newLang: string) => {
    setLanguage(newLang);
    setCode(getCodeTemplate(newLang));
  };

  return (
    <div className={styles.widget}>
      {/* Toolbar */}
      <div className={styles.toolbar}>
        <select
          value={language}
          onChange={(e) => handleLanguageChange(e.target.value)}
          className={styles.languageSelect}
        >
          <option value="python">Python</option>
          <option value="javascript">JavaScript</option>
          <option value="typescript">TypeScript</option>
          <option value="java">Java</option>
          <option value="cpp">C++</option>
        </select>

        <Button
          onClick={handleRun}
          loading={isPending}
          variant="primary"
        >
          Run
        </Button>
      </div>

      {/* Monaco Editor */}
      <div className={styles.editorContainer}>
        <CodeEditor
          value={code}
          onChange={setCode}
          language={language}
          height="500px"
        />
      </div>

      {/* Execution result */}
      {isPending && (
        <div className={styles.output}>
          <Loading />
          <p>Executing code...</p>
        </div>
      )}

      {result && (
        <div className={`${styles.output} ${result.status === 'error' ? styles.error : styles.success}`}>
          <h4>Result:</h4>
          <pre>{result.output}</pre>

          {result.execution_time && (
            <div className={styles.meta}>
              <span>Execution time: {result.execution_time}ms</span>
            </div>
          )}
        </div>
      )}
    </div>
  );
};
```

```scss
// front/src/widgets/CodeEditorWidget/ui/CodeEditorWidget.module.scss
@import 'app/styles/variables';
@import 'app/styles/mixins';

.widget {
  display: flex;
  flex-direction: column;
  gap: $spacing-md;
  background: var(--bg-secondary);
  border-radius: $border-radius-lg;
  padding: $spacing-lg;
  border: 1px solid var(--border-color);
}

.toolbar {
  display: flex;
  align-items: center;
  gap: $spacing-md;
  padding-bottom: $spacing-md;
  border-bottom: 1px solid var(--border-color);
}

.languageSelect {
  padding: $spacing-sm $spacing-md;
  border: 1px solid var(--border-color);
  border-radius: $border-radius-md;
  background: var(--bg-primary);
  color: var(--text-primary);
  font-size: $font-size-md;
  cursor: pointer;

  &:focus {
    outline: 2px solid var(--color-primary);
    outline-offset: 2px;
  }
}

.editorContainer {
  border-radius: $border-radius-md;
  overflow: hidden;
  border: 1px solid var(--border-color);
}

.output {
  padding: $spacing-md;
  background: var(--bg-tertiary);
  border-radius: $border-radius-md;
  font-family: $font-family-mono;

  h4 {
    margin-bottom: $spacing-sm;
    color: var(--text-primary);
  }

  pre {
    margin: 0;
    white-space: pre-wrap;
    word-wrap: break-word;
    color: var(--text-secondary);
  }

  &.success {
    border-left: 4px solid var(--color-success);
  }

  &.error {
    border-left: 4px solid var(--color-error);

    pre {
      color: var(--color-error);
    }
  }
}

.meta {
  margin-top: $spacing-sm;
  padding-top: $spacing-sm;
  border-top: 1px solid var(--border-color);
  font-size: $font-size-sm;
  color: var(--text-tertiary);
}
```

---

## 3. Feature Example: Flashcards

```typescript
// front/src/features/Flashcards/ui/Flashcards.tsx
import { FC, useState } from 'react';
import { AnimatePresence, motion } from 'framer-motion';

import { Button } from 'shared/components/Button';
import { Loading } from 'shared/components/Loading';
import { useAppDispatch, useAppSelector } from 'app/providers/ReduxProvider/hooks';
import { selectCurrentCard, selectDeckProgress, nextCard, markKnown, markUnknown } from 'entities/Card';

import styles from './Flashcards.module.scss';

export const Flashcards: FC = () => {
  const dispatch = useAppDispatch();
  const currentCard = useAppSelector(selectCurrentCard);
  const progress = useAppSelector(selectDeckProgress);
  const [isFlipped, setIsFlipped] = useState(false);

  if (!currentCard) {
    return (
      <div className={styles.empty}>
        <p>All cards studied!</p>
        <Button onClick={() => window.location.reload()}>
          Start Over
        </Button>
      </div>
    );
  }

  const handleKnown = () => {
    dispatch(markKnown(currentCard.id));
    dispatch(nextCard());
    setIsFlipped(false);
  };

  const handleUnknown = () => {
    dispatch(markUnknown(currentCard.id));
    dispatch(nextCard());
    setIsFlipped(false);
  };

  return (
    <div className={styles.container}>
      {/* Progress */}
      <div className={styles.progress}>
        <div className={styles.progressBar}>
          <div
            className={styles.progressFill}
            style={{ width: `${progress}%` }}
          />
        </div>
        <span className={styles.progressText}>{progress.toFixed(0)}%</span>
      </div>

      {/* Card with flip animation */}
      <motion.div
        className={styles.card}
        onClick={() => setIsFlipped(!isFlipped)}
        animate={{ rotateY: isFlipped ? 180 : 0 }}
        transition={{ duration: 0.6 }}
      >
        <div className={`${styles.cardFace} ${styles.front}`}>
          <div className={styles.category}>{currentCard.category}</div>
          <h2 className={styles.question}>{currentCard.title}</h2>
          <p className={styles.hint}>Click for answer</p>
        </div>

        <div className={`${styles.cardFace} ${styles.back}`}>
          <div className={styles.answer}>{currentCard.content}</div>
        </div>
      </motion.div>

      {/* Action buttons */}
      {isFlipped && (
        <motion.div
          className={styles.actions}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
        >
          <Button
            onClick={handleUnknown}
            variant="secondary"
            size="lg"
          >
            Don't Know
          </Button>

          <Button
            onClick={handleKnown}
            variant="primary"
            size="lg"
          >
            Know
          </Button>
        </motion.div>
      )}
    </div>
  );
};
```

```scss
// front/src/features/Flashcards/ui/Flashcards.module.scss
@import 'app/styles/variables';
@import 'app/styles/mixins';

.container {
  max-width: 800px;
  margin: 0 auto;
  padding: $spacing-xl;
}

.progress {
  margin-bottom: $spacing-xl;
}

.progressBar {
  height: 8px;
  background: var(--bg-tertiary);
  border-radius: $border-radius-full;
  overflow: hidden;
}

.progressFill {
  height: 100%;
  background: linear-gradient(90deg, var(--color-primary), var(--color-secondary));
  transition: width 0.3s ease;
}

.progressText {
  display: block;
  text-align: center;
  margin-top: $spacing-xs;
  color: var(--text-secondary);
  font-size: $font-size-sm;
}

.card {
  position: relative;
  width: 100%;
  min-height: 400px;
  cursor: pointer;
  perspective: 1000px;
  transform-style: preserve-3d;

  @include respond-to(mobile) {
    min-height: 300px;
  }
}

.cardFace {
  position: absolute;
  width: 100%;
  height: 100%;
  backface-visibility: hidden;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  padding: $spacing-xl;
  background: var(--bg-secondary);
  border-radius: $border-radius-lg;
  box-shadow: $shadow-lg;
}

.front {
  z-index: 2;
}

.back {
  transform: rotateY(180deg);
}

.category {
  position: absolute;
  top: $spacing-md;
  right: $spacing-md;
  padding: $spacing-xs $spacing-sm;
  background: var(--color-primary);
  color: white;
  border-radius: $border-radius-sm;
  font-size: $font-size-xs;
  font-weight: $font-weight-bold;
  text-transform: uppercase;
}

.question {
  font-size: $font-size-2xl;
  font-weight: $font-weight-bold;
  text-align: center;
  color: var(--text-primary);
  margin-bottom: $spacing-md;
}

.hint {
  color: var(--text-tertiary);
  font-size: $font-size-sm;
  font-style: italic;
}

.answer {
  font-size: $font-size-lg;
  line-height: 1.6;
  color: var(--text-primary);
  text-align: center;
}

.actions {
  display: flex;
  gap: $spacing-md;
  justify-content: center;
  margin-top: $spacing-xl;
}

.empty {
  text-align: center;
  padding: $spacing-xxl;

  p {
    font-size: $font-size-2xl;
    margin-bottom: $spacing-lg;
    color: var(--text-primary);
  }
}
```

---

## 4. Entity Example: Item with Redux

```typescript
// front/src/entities/Item/model/itemSlice.ts
import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import type { RootState } from 'app/providers/ReduxProvider/store';

export interface Item {
  id: number;
  title: string;
  content: string;
  technology: string;
  difficulty: string;
  completed: boolean;
}

interface ItemState {
  items: Item[];
  selectedId: number | null;
  filter: {
    technology: string | null;
    difficulty: string | null;
    completed: boolean | null;
  };
}

const initialState: ItemState = {
  items: [],
  selectedId: null,
  filter: {
    technology: null,
    difficulty: null,
    completed: null
  }
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
    setFilter: (state, action: PayloadAction<Partial<ItemState['filter']>>) => {
      state.filter = { ...state.filter, ...action.payload };
    },
    clearFilters: (state) => {
      state.filter = initialState.filter;
    }
  }
});

// Actions
export const { setItems, selectItem, toggleCompleted, setFilter, clearFilters } = itemSlice.actions;

// Selectors
export const selectAllItems = (state: RootState) => state.item.items;
export const selectSelectedId = (state: RootState) => state.item.selectedId;
export const selectFilter = (state: RootState) => state.item.filter;

export const selectFilteredItems = (state: RootState) => {
  const { items, filter } = state.item;

  return items.filter(item => {
    if (filter.technology && item.technology !== filter.technology) return false;
    if (filter.difficulty && item.difficulty !== filter.difficulty) return false;
    if (filter.completed !== null && item.completed !== filter.completed) return false;
    return true;
  });
};

export const selectSelectedItem = (state: RootState) => {
  const { items, selectedId } = state.item;
  return items.find(b => b.id === selectedId) || null;
};

// Reducer
export default itemSlice.reducer;
```

```typescript
// front/src/entities/Item/ui/ItemCard.tsx
import { FC } from 'react';
import { useAppDispatch } from 'app/providers/ReduxProvider/hooks';
import { selectItem, toggleCompleted } from '../model/itemSlice';
import type { Item } from '../model/itemSlice';

import styles from './ItemCard.module.scss';

interface ItemCardProps {
  item: Item;
  onClick?: () => void;
}

export const ItemCard: FC<ItemCardProps> = ({ item, onClick }) => {
  const dispatch = useAppDispatch();

  const handleToggle = (e: React.MouseEvent) => {
    e.stopPropagation();
    dispatch(toggleCompleted(item.id));
  };

  const handleClick = () => {
    dispatch(selectItem(item.id));
    onClick?.();
  };

  return (
    <div
      className={`${styles.card} ${item.completed ? styles.completed : ''}`}
      onClick={handleClick}
    >
      <div className={styles.header}>
        <h3 className={styles.title}>{item.title}</h3>
        <button
          className={styles.checkButton}
          onClick={handleToggle}
          aria-label={item.completed ? 'Mark as incomplete' : 'Mark as complete'}
        >
          {item.completed ? 'Done' : 'Pending'}
        </button>
      </div>

      <p className={styles.content}>{item.content.slice(0, 150)}...</p>

      <div className={styles.footer}>
        <span className={styles.badge}>{item.technology}</span>
        <span className={`${styles.difficulty} ${styles[item.difficulty]}`}>
          {item.difficulty}
        </span>
      </div>
    </div>
  );
};
```

```typescript
// front/src/entities/Item/index.ts
export { itemSlice, setItems, selectItem, toggleCompleted, setFilter, clearFilters } from './model/itemSlice';
export { selectAllItems, selectSelectedId, selectFilteredItems, selectSelectedItem } from './model/itemSlice';
export { ItemCard } from './ui/ItemCard';
export type { Item } from './model/itemSlice';
```

---

## 5. Shared Component: Button

```typescript
// front/src/shared/components/Button/Button.tsx
import { FC, ButtonHTMLAttributes, ReactNode } from 'react';
import { Loading } from '../Loading';

import styles from './Button.module.scss';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  children: ReactNode;
  variant?: 'primary' | 'secondary' | 'danger' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  loading?: boolean;
  fullWidth?: boolean;
  icon?: ReactNode;
}

export const Button: FC<ButtonProps> = ({
  children,
  variant = 'primary',
  size = 'md',
  loading = false,
  fullWidth = false,
  icon,
  disabled,
  className = '',
  ...props
}) => {
  const classes = [
    styles.button,
    styles[variant],
    styles[size],
    fullWidth && styles.fullWidth,
    loading && styles.loading,
    className
  ].filter(Boolean).join(' ');

  return (
    <button
      className={classes}
      disabled={disabled || loading}
      {...props}
    >
      {loading && <Loading size="sm" />}
      {icon && !loading && <span className={styles.icon}>{icon}</span>}
      <span className={styles.text}>{children}</span>
    </button>
  );
};
```

```scss
// front/src/shared/components/Button/Button.module.scss
@import 'app/styles/variables';
@import 'app/styles/mixins';

.button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: $spacing-xs;
  border: none;
  border-radius: $border-radius-md;
  font-weight: $font-weight-medium;
  cursor: pointer;
  transition: all 0.2s;
  font-family: $font-family-primary;

  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  &:not(:disabled):hover {
    transform: translateY(-1px);
    box-shadow: $shadow-md;
  }

  &:not(:disabled):active {
    transform: translateY(0);
  }
}

// Sizes
.sm {
  padding: $spacing-xs $spacing-sm;
  font-size: $font-size-sm;
}

.md {
  padding: $spacing-sm $spacing-md;
  font-size: $font-size-md;
}

.lg {
  padding: $spacing-md $spacing-lg;
  font-size: $font-size-lg;
}

// Variants
.primary {
  background: var(--color-primary);
  color: white;

  &:not(:disabled):hover {
    background: var(--color-primary-dark);
  }
}

.secondary {
  background: var(--bg-secondary);
  color: var(--text-primary);
  border: 1px solid var(--border-color);

  &:not(:disabled):hover {
    border-color: var(--color-primary);
  }
}

.danger {
  background: var(--color-error);
  color: white;

  &:not(:disabled):hover {
    background: var(--color-error-dark);
  }
}

.ghost {
  background: transparent;
  color: var(--text-primary);

  &:not(:disabled):hover {
    background: var(--bg-secondary);
  }
}

// Modifiers
.fullWidth {
  width: 100%;
}

.loading {
  position: relative;

  .text {
    opacity: 0.5;
  }
}

.icon {
  display: flex;
  align-items: center;
}
```

```typescript
// front/src/shared/components/Button/index.ts
export { Button } from './Button';
export type { ButtonProps } from './Button';
```

---

**All examples follow FSD architecture, use TypeScript, SCSS modules, Redux Toolkit and React Query!**
