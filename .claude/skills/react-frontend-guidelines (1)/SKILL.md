---
name: react-frontend-guidelines
description: React/TypeScript/FSD frontend development guide. Use when creating pages, widgets, features, entities, components, working with Redux Toolkit, React Query v5, React Hook Form, SCSS modules, Monaco Editor, React Flow, or implementing FSD architecture. Covers layer structure, state management patterns, API integration with Orval, styling with SCSS modules, performance optimization.
---

# React Frontend Development Guidelines

## Purpose

Establish consistency and best practices for frontend using Feature-Sliced Design (FSD) architecture with React 19 + TypeScript + Redux Toolkit + React Query v5 stack.

## When to Use This Skill

Automatically activates when working on:
- Creating pages, widgets, features, entities, shared components
- Working with Redux Toolkit slices
- React Query hooks and API integration
- SCSS modules and styling
- Forms with React Hook Form + Zod
- Monaco Editor, React Flow, or other UI libraries
- Frontend routing with React Router v7
- Performance optimization

---

## Quick Start Checklists

### New Page Checklist

- [ ] **Page Component**: Create in `front/src/pages/PageName/`
- [ ] **SCSS Module**: `PageName.module.scss`
- [ ] **Route**: Add to React Router config
- [ ] **Data Fetching**: Use React Query hooks from `api/generated/`
- [ ] **Lazy Loading**: Wrap with `React.lazy()` if heavy
- [ ] **Meta Tags**: SEO optimization
- [ ] **Tests**: Component tests (optional)

### New Feature Checklist

- [ ] **Feature Module**: Create in `front/src/features/FeatureName/`
- [ ] **UI Components**: Business logic components
- [ ] **Hooks**: Custom hooks if needed
- [ ] **State**: Local state or Redux slice if global
- [ ] **API Integration**: Use React Query hooks
- [ ] **SCSS Module**: Feature-specific styles
- [ ] **Export**: Public API in `index.ts`

### New Widget Checklist

- [ ] **Widget Module**: Create in `front/src/widgets/WidgetName/`
- [ ] **Composition**: Combine features + entities
- [ ] **Props Interface**: Well-defined TypeScript interface
- [ ] **SCSS Module**: Widget styles
- [ ] **Responsive**: Mobile/tablet/desktop support
- [ ] **Loading States**: Skeleton or spinner
- [ ] **Error States**: Error boundaries

---

## Architecture Overview

### Feature-Sliced Design (FSD) Layers

```
front/src/
├── app/                # Application initialization
│   ├── providers/      # Providers (auth, modal, query, redux, router)
│   ├── styles/         # Global styles (base, light, dark)
│   └── App.tsx
│
├── pages/              # Pages
│   ├── Home/
│   ├── Dashboard/
│   ├── Profile/
│   └── ...
│
├── widgets/            # Composite UI blocks
│   ├── Header/
│   ├── Sidebar/        # With Redux slice!
│   ├── Footer/
│   └── ...
│
├── features/           # Business features
│   ├── LoginForm/
│   ├── RegisterForm/
│   ├── SearchFilter/
│   └── ...
│
├── entities/           # Business entities
│   ├── User/
│   ├── Item/           # With Redux slice!
│   ├── Category/       # With React Query!
│   └── ...
│
└── shared/             # Reusable code
    ├── api/            # API clients + generated
    ├── components/     # UI components
    ├── hooks/          # Common hooks
    ├── lib/            # Utilities
    └── types/          # TypeScript types
```

### FSD Import Rules

```typescript
// ✅ Correct: import from top to bottom
import { AuthProvider } from 'app/providers'          // app
import { HomePage } from 'pages/Home'                 // pages
import { Sidebar } from 'widgets/Sidebar'             // widgets
import { LoginForm } from 'features/LoginForm'        // features
import { User } from 'entities/User'                  // entities
import { Button } from 'shared/components/Button'     // shared

// ❌ Wrong: import from bottom to top
import { AuthProvider } from 'app/providers'  // app CANNOT import from pages!

// ❌ Wrong: cross-feature imports
import { RegisterForm } from 'features/RegisterForm'  // features DON'T import each other!
```

**Golden Rule:** A layer can only import from layers below itself.

---

## Core Patterns Summary

### 1. Component Pattern
- Use `FC<Props>` for typing
- Destructure props with defaults
- SCSS modules for styling

→ See `resources/component-patterns.md` for full examples

### 2. Redux Toolkit
- `createSlice` for state
- Export actions and selectors
- Use `useAppDispatch` and `useAppSelector`

→ See `resources/redux-patterns.md` for full examples

### 3. React Query (Orval)
- Use auto-generated hooks from `shared/api/generated/`
- Destructure `{ data, isLoading, error }`
- `enabled` for conditional queries
- `invalidateQueries` after mutations

→ See `resources/react-query-patterns.md` for full examples

### 4. Forms (React Hook Form + Zod)
- Zod schema for validation
- `useForm` with `zodResolver`
- Error handling per field

→ See `resources/form-patterns.md` for full examples

### 5. SCSS Modules
- Import variables and mixins
- CSS variables for theming
- Responsive mixins

→ See `resources/scss-patterns.md` for full examples

### 6. Performance
- `React.memo` for expensive components
- `useMemo` for expensive calculations
- `useCallback` for stable callbacks
- `React.lazy` for code splitting

→ See `resources/performance-patterns.md` for full examples

---

## Quick Reference

**Create New Page:**
1. `mkdir -p front/src/pages/PageName/ui`
2. Create `PageName.tsx` + `PageName.module.scss`
3. Add route to router config
4. Export from `index.ts`

**Create New Feature:**
1. `mkdir -p front/src/features/FeatureName/ui`
2. Create components + hooks + styles
3. Export public API from `index.ts`

**File Naming:**
- Components: `ComponentName.tsx` (PascalCase)
- Styles: `ComponentName.module.scss`
- Hooks: `useHookName.ts` (camelCase)
- Types: `types.ts` or `ComponentName.types.ts`

**Import Order:**
```typescript
// 1. React
import { FC, useState } from 'react';

// 2. External libraries
import { useQuery } from '@tanstack/react-query';

// 3. Internal (FSD order: app → pages → widgets → features → entities → shared)
import { AuthProvider } from 'app/providers';
import { Sidebar } from 'widgets/Sidebar';
import { LoginForm } from 'features/LoginForm';
import { User } from 'entities/User';
import { Button } from 'shared/components/Button';

// 4. Styles
import styles from './Component.module.scss';
```

---

## Resources (Progressive Disclosure)

For detailed patterns and full code examples, see:
- `resources/component-patterns.md` - React component structure
- `resources/redux-patterns.md` - Redux Toolkit slices and selectors
- `resources/react-query-patterns.md` - API integration with React Query
- `resources/form-patterns.md` - Forms with React Hook Form + Zod
- `resources/scss-patterns.md` - SCSS modules and theming
- `resources/performance-patterns.md` - Performance optimization
- `resources/routing-patterns.md` - React Router configuration
- `resources/complete-examples.md` - Full page/widget/feature examples

---

**Remember:** Follow FSD architecture, use TypeScript strictly, optimize performance, test components!
