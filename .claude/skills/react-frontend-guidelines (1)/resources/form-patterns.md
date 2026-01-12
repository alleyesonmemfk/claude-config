# Form Patterns - React Hook Form + Zod

## Complete Form Example

```typescript
// front/src/features/RegisterForm/ui/RegisterForm.tsx
import { FC } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

import { Button } from 'shared/components/Button';
import { Input } from 'shared/components/Input';

import styles from './RegisterForm.module.scss';

const registerSchema = z.object({
  email: z.string().email('Invalid email'),
  password: z.string().min(6, 'Minimum 6 characters'),
  confirmPassword: z.string(),
  terms: z.boolean().refine(val => val === true, 'You must accept the terms')
}).refine(data => data.password === data.confirmPassword, {
  message: 'Passwords do not match',
  path: ['confirmPassword']
});

type RegisterFormData = z.infer<typeof registerSchema>;

export const RegisterForm: FC = () => {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting }
  } = useForm<RegisterFormData>({
    resolver: zodResolver(registerSchema),
    mode: 'onBlur' // Validation on blur
  });

  const onSubmit = async (data: RegisterFormData) => {
    try {
      await registerUser(data);
    } catch (error) {
      console.error(error);
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className={styles.form}>
      <Input
        label="Email"
        type="email"
        error={errors.email?.message}
        {...register('email')}
      />

      <Input
        label="Password"
        type="password"
        error={errors.password?.message}
        {...register('password')}
      />

      <Input
        label="Confirm Password"
        type="password"
        error={errors.confirmPassword?.message}
        {...register('confirmPassword')}
      />

      <label className={styles.checkbox}>
        <input type="checkbox" {...register('terms')} />
        I accept the terms of service
        {errors.terms && <span className={styles.error}>{errors.terms.message}</span>}
      </label>

      <Button type="submit" loading={isSubmitting}>
        Register
      </Button>
    </form>
  );
};
```

## Zod Schema Patterns

```typescript
// Basic types
const schema = z.object({
  name: z.string().min(1, 'Required field'),
  email: z.string().email('Invalid email'),
  age: z.number().min(18, 'Minimum age is 18'),
  phone: z.string().optional(),
});

// Enum
const statusSchema = z.enum(['active', 'inactive', 'pending']);

// Array
const tagsSchema = z.array(z.string()).min(1, 'At least 1 tag required');

// Union
const idSchema = z.union([z.string(), z.number()]);

// Custom validation
const passwordSchema = z.string()
  .min(8, 'Minimum 8 characters')
  .regex(/[A-Z]/, 'At least 1 uppercase letter')
  .regex(/[0-9]/, 'At least 1 digit');

// Conditional validation (refine)
const formSchema = z.object({
  password: z.string(),
  confirmPassword: z.string(),
}).refine(data => data.password === data.confirmPassword, {
  message: 'Passwords do not match',
  path: ['confirmPassword'],
});

// Type inference
type FormData = z.infer<typeof schema>;
```

## Form with API Mutation

```typescript
import { useRegisterMutation } from 'shared/api/generated/auth/auth';

export const RegisterForm: FC = () => {
  const { mutate: register, isPending, error } = useRegisterMutation({
    onSuccess: () => {
      navigate('/login');
    }
  });

  const { register: formRegister, handleSubmit, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema)
  });

  const onSubmit = (data: FormData) => {
    register({ data });
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      {error && <div className={styles.apiError}>{error.message}</div>}
      {/* ... fields */}
      <Button type="submit" loading={isPending}>Submit</Button>
    </form>
  );
};
```

## Form with Default Values

```typescript
interface EditFormProps {
  initialData: FormData;
}

export const EditForm: FC<EditFormProps> = ({ initialData }) => {
  const { register, handleSubmit, reset } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: initialData
  });

  // Reset form when initialData changes
  useEffect(() => {
    reset(initialData);
  }, [initialData, reset]);

  return <form>...</form>;
};
```

## Dynamic Form Fields

```typescript
import { useFieldArray } from 'react-hook-form';

const schema = z.object({
  items: z.array(z.object({
    name: z.string().min(1),
    quantity: z.number().min(1),
  })).min(1, 'At least 1 item required')
});

export const DynamicForm: FC = () => {
  const { control, register, handleSubmit } = useForm({
    resolver: zodResolver(schema),
    defaultValues: { items: [{ name: '', quantity: 1 }] }
  });

  const { fields, append, remove } = useFieldArray({
    control,
    name: 'items'
  });

  return (
    <form>
      {fields.map((field, index) => (
        <div key={field.id}>
          <Input {...register(`items.${index}.name`)} />
          <Input type="number" {...register(`items.${index}.quantity`, { valueAsNumber: true })} />
          <Button onClick={() => remove(index)}>Remove</Button>
        </div>
      ))}
      <Button onClick={() => append({ name: '', quantity: 1 })}>Add Item</Button>
    </form>
  );
};
```

## Form Validation Modes

```typescript
useForm({
  mode: 'onChange',    // Validate on every change
  mode: 'onBlur',      // Validate on blur
  mode: 'onSubmit',    // Validate only on submit (default)
  mode: 'onTouched',   // Validate after first blur, then onChange
  mode: 'all',         // All modes
});
```
