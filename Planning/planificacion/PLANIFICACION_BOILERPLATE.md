# Plan de Implementación del Boilerplate - Retrospectiva de Sprint

## 📋 Objetivo

Crear la estructura base del proyecto siguiendo arquitectura DDD, principios SOLID y las convenciones de la skill **domain-builder**, preparando el entorno para el desarrollo del MVP.

---

## 🎯 Fases de Implementación

### **FASE 1: Configuración Inicial del Proyecto** ⏱️ 1-2 días

#### 1.1 Inicialización de Next.js 16

- [ ] Crear proyecto Next.js 16 con App Router
  ```bash
  npx create-next-app@latest retro-app --typescript --tailwind --app --no-src
  ```
- [ ] Configurar opciones:
  - ✅ TypeScript
  - ✅ ESLint
  - ✅ Tailwind CSS
  - ✅ App Router
  - ❌ src/ directory (usaremos estructura DDD custom)
  - ✅ Import alias (@/\*)

#### 1.2 Configuración de TypeScript Estricto

- [ ] Actualizar `tsconfig.json` con configuración estricta:
  ```json
  {
    "compilerOptions": {
      "strict": true,
      "noUncheckedIndexedAccess": true,
      "noImplicitReturns": true,
      "noFallthroughCasesInSwitch": true,
      "noUnusedLocals": true,
      "noUnusedParameters": true,
      "exactOptionalPropertyTypes": true,
      "paths": {
        "@/*": ["./*"],
        "@retro/*": ["./src/retro/*"],
        "@shared/*": ["./src/shared/*"],
        "@kernel/*": ["./src/kernel/*"]
      }
    }
  }
  ```

#### 1.3 Configuración de ESLint con Reglas SOLID

- [ ] Instalar dependencias de ESLint:
  ```bash
  npm install -D @typescript-eslint/parser @typescript-eslint/eslint-plugin
  ```
- [ ] Configurar `.eslintrc.json` con reglas SOLID:
  ```json
  {
    "extends": [
      "next/core-web-vitals",
      "plugin:@typescript-eslint/recommended"
    ],
    "rules": {
      "max-lines-per-function": ["warn", 50],
      "max-params": ["warn", 3],
      "complexity": ["warn", 10],
      "@typescript-eslint/no-explicit-any": "error",
      "@typescript-eslint/explicit-function-return-type": "warn"
    }
  }
  ```

#### 1.4 Instalación de Dependencias Base

- [ ] Instalar dependencias de producción:
  ```bash
  npm install @supabase/supabase-js @supabase/ssr
  npm install @dnd-kit/core @dnd-kit/sortable @dnd-kit/utilities
  npm install @base-ui/react
  npm install zod
  npm install nanoid
  ```
- [ ] Instalar dependencias de desarrollo:
  ```bash
  npm install -D vitest @vitest/ui
  npm install -D @testing-library/react @testing-library/jest-dom
  npm install -D prettier eslint-config-prettier
  ```

#### 1.5 Configuración de Prettier

- [ ] Crear `.prettierrc`:
  ```json
  {
    "semi": true,
    "trailingComma": "all",
    "singleQuote": false,
    "printWidth": 80,
    "tabWidth": 2
  }
  ```

---

### **FASE 2: Estructura de Carpetas DDD** ⏱️ 0.5 días

#### 2.1 Crear Estructura de Dominio

- [ ] Crear carpetas del contexto `retro`:
  ```bash
  mkdir -p src/retro/domain
  mkdir -p src/retro/application
  mkdir -p src/retro/infrastructure/schemas
  ```

#### 2.2 Crear Carpetas Compartidas

- [ ] Crear carpetas `shared`:
  ```bash
  mkdir -p src/shared/domain
  mkdir -p src/shared/infrastructure/supabase
  mkdir -p src/shared/infrastructure/realtime
  ```

#### 2.3 Crear Carpetas Kernel

- [ ] Crear carpeta `kernel`:
  ```bash
  mkdir -p src/kernel
  ```

#### 2.4 Crear Estructura de Testing

- [ ] Crear carpetas de pruebas:
  ```bash
  mkdir -p test/domain/retro/models
  mkdir -p test/domain/retro/units
  mkdir -p test/domain/retro/integrations
  mkdir -p test/mothers/retro
  ```

#### 2.5 Mantener App Router de Next.js

- [ ] La carpeta `app/` ya existe, crear subcarpetas:
  ```bash
  mkdir -p app/session/[code]
  mkdir -p app/components/session
  mkdir -p app/components/postit
  mkdir -p app/components/shared
  mkdir -p app/hooks
  ```

---

### **FASE 3: Configuración de Supabase** ⏱️ 1 día

#### 3.1 Setup de Proyecto Supabase

- [ ] Crear proyecto en Supabase Dashboard
- [ ] Obtener credenciales (URL y anon key)
- [ ] Crear archivo `.env.local`:
  ```env
  NEXT_PUBLIC_SUPABASE_URL=your-project-url
  NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
  ```
- [ ] Añadir `.env.local` a `.gitignore`

#### 3.2 Crear Cliente de Supabase

- [ ] Implementar `src/shared/infrastructure/supabase/client.ts`:
  - Cliente para Server Components
  - Cliente para Client Components
  - Tipos TypeScript generados

#### 3.3 Diseño de Schema de Base de Datos

- [ ] Crear archivo `supabase/schema.sql` con tablas:
  - `retro_sessions` (id, code, moderator_id, phase, created_at)
  - `session_users` (id, session_id, user_name, is_completed, is_moderator, joined_at)
  - `postits` (id, session_id, user_id, user_name, category, text, position_x, position_y, group_id, created_at, updated_at)

#### 3.4 Configurar Row Level Security (RLS)

- [ ] Crear políticas RLS para privacidad en fase privada:
  - Post-its solo visibles por creador en fase `private`
  - Post-its visibles para todos en fase `collaborative`
  - Sesiones visibles para participantes

#### 3.5 Habilitar Realtime

- [ ] Activar Realtime en tablas necesarias
- [ ] Configurar publicaciones de Realtime

---

### **FASE 4: Objetos Kernel (Primitivos Reutilizables)** ⏱️ 1 día

#### 4.1 Implementar Value Objects Kernel

- [ ] **`src/kernel/Id.ts`**
  - Método estático `create()`: Genera UUID con nanoid
  - Método estático `createOrNull(value: string)`: Validación de UUID
  - Método `equals(other: Id)`: Comparación
  - Método `toString()`: Serialización

- [ ] **`src/kernel/Timestamp.ts`**
  - Método estático `now()`: Timestamp actual
  - Método estático `createOrNull(value: number | Date)`: Validación
  - Método `toDate()`: Conversión a Date
  - Método `toISOString()`: Serialización

- [ ] **`src/kernel/NonEmptyString.ts`**
  - Método estático `createOrNull(value: string)`: Validación no vacío
  - Método `toString()`: Serialización
  - Método `equals(other: NonEmptyString)`: Comparación

#### 4.2 Crear Pruebas Unitarias de Kernel

- [ ] `test/kernel/Id.test.ts`
- [ ] `test/kernel/Timestamp.test.ts`
- [ ] `test/kernel/NonEmptyString.test.ts`

---

### **FASE 5: Value Objects Compartidos** ⏱️ 1.5 días

#### 5.1 Implementar Value Objects de Dominio

- [ ] **`src/shared/domain/SessionCode.ts`**
  - Código único de 6 caracteres alfanuméricos
  - Método estático `generate()`: Genera código aleatorio
  - Método estático `createOrNull(value: string)`: Validación
  - Método `toString()`: Serialización

- [ ] **`src/shared/domain/PostItCategory.ts`**
  - Enum: `keep`, `improve`, `ideas`, `stop`
  - Métodos estáticos: `keep()`, `improve()`, `ideas()`, `stop()`
  - Método `isKeep()`, `isImprove()`, `isIdeas()`, `isStop()`
  - Método `getColor()`: Retorna color hex asociado

- [ ] **`src/shared/domain/SessionPhase.ts`**
  - Enum: `waiting`, `private`, `collaborative`, `finished`
  - Métodos estáticos para cada fase
  - Métodos de validación de transición: `canTransitionTo(phase: SessionPhase)`

- [ ] **`src/shared/domain/Position.ts`**
  - Propiedades: `x: number`, `y: number`
  - Método estático `default()`: Posición (0, 0)
  - Método estático `createOrNull(x: number, y: number)`: Validación
  - Método `toJSON()`: Serialización

#### 5.2 Crear Pruebas Unitarias de Value Objects

- [ ] `test/shared/domain/SessionCode.test.ts`
- [ ] `test/shared/domain/PostItCategory.test.ts`
- [ ] `test/shared/domain/SessionPhase.test.ts`
- [ ] `test/shared/domain/Position.test.ts`

---

### **FASE 6: Entidades de Dominio** ⏱️ 2 días

#### 6.1 Implementar Entidad PostIt

- [ ] **`src/retro/domain/PostIt.ts`**
  - Propiedades privadas (id, sessionId, userId, userName, category, text, position, groupId?, createdAt, updatedAt)
  - Método estático `create(props)`: Constructor semántico
  - Método estático `createOrNull(props)`: Creación segura
  - Método `updateContent(text: NonEmptyString)`: Actualizar texto
  - Método `moveToCategory(category: PostItCategory)`: Cambiar categoría
  - Método `moveToPosition(position: Position)`: Cambiar posición
  - Método `assignToGroup(groupId: Id)`: Agrupar post-it
  - Método `removeFromGroup()`: Desagrupar
  - Método `toJSON()`: Serialización
  - **SIN getters/setters genéricos**

#### 6.2 Implementar Entidad SessionUser

- [ ] **`src/retro/domain/SessionUser.ts`**
  - Propiedades privadas (id, sessionId, userName, isCompleted, isModerator, joinedAt)
  - Método estático `create(props)`: Constructor semántico
  - Método estático `createOrNull(props)`: Creación segura
  - Método `markAsCompleted()`: Marcar terminado
  - Método `markAsIncomplete()`: Desmarcar
  - Método `promoteToModerator()`: Convertir en moderador
  - Método `toJSON()`: Serialización

#### 6.3 Implementar Agregado RetroSession

- [ ] **`src/retro/domain/RetroSession.ts`**
  - Propiedades privadas (id, code, moderatorId, phase, participants, completedUsers, createdAt)
  - Método estático `create(props)`: Constructor semántico
  - Método estático `createOrNull(props)`: Creación segura
  - Método `addParticipant(userId: Id)`: Añadir participante
  - Método `removeParticipant(userId: Id)`: Eliminar participante
  - Método `markUserCompleted(userId: Id)`: Marcar usuario terminado
  - Método `transitionToPrivatePhase()`: Cambiar a fase privada
  - Método `transitionToCollaborativePhase()`: Cambiar a fase colaborativa
  - Método `canTransitionToCollaborative()`: Validar si todos terminaron
  - Método `finish()`: Finalizar sesión
  - Método `toJSON()`: Serialización

#### 6.4 Implementar Colecciones Tipadas (ListOf)

- [ ] **`src/retro/domain/PostItList.ts`**
  - Método `addPostIt(postIt: PostIt)`: Añadir
  - Método `removePostIt(id: Id)`: Eliminar
  - Método `filterByCategory(category: PostItCategory)`: Filtrar
  - Método `filterByUser(userId: Id)`: Filtrar por usuario
  - Método `toArray()`: Convertir a array

- [ ] **`src/retro/domain/SessionUserList.ts`**
  - Método `addUser(user: SessionUser)`: Añadir
  - Método `removeUser(id: Id)`: Eliminar
  - Método `findByUserName(name: string)`: Buscar
  - Método `getCompletedCount()`: Contar completados
  - Método `toArray()`: Convertir a array

#### 6.5 Crear Pruebas Unitarias de Entidades

- [ ] `test/domain/retro/models/PostIt.test.ts`
- [ ] `test/domain/retro/models/SessionUser.test.ts`
- [ ] `test/domain/retro/models/RetroSession.test.ts`

---

### **FASE 7: Objetos Madre (Test Data Builders)** ⏱️ 1 día

#### 7.1 Implementar Mothers

- [ ] **`test/mothers/retro/PostItMother.ts`**
  - Método `create(params?)`: Post-it genérico
  - Método `keepDoing()`: Post-it de categoría keep
  - Método `improve()`: Post-it de categoría improve
  - Método `ideas()`: Post-it de categoría ideas
  - Método `stopDoing()`: Post-it de categoría stop
  - Método `withInvalidText()`: Post-it inválido

- [ ] **`test/mothers/retro/SessionUserMother.ts`**
  - Método `create(params?)`: Usuario genérico
  - Método `moderator()`: Usuario moderador
  - Método `participant()`: Usuario participante
  - Método `completed()`: Usuario que terminó

- [ ] **`test/mothers/retro/RetroSessionMother.ts`**
  - Método `create(params?)`: Sesión genérica
  - Método `inWaitingPhase()`: Sesión en espera
  - Método `inPrivatePhase()`: Sesión en fase privada
  - Método `inCollaborativePhase()`: Sesión en fase colaborativa
  - Método `withParticipants(count: number)`: Sesión con N participantes

---

### **FASE 8: Interfaces de Repositorios** ⏱️ 0.5 días

#### 8.1 Definir Interfaces en Capa de Dominio

- [ ] **`src/retro/domain/IPostItRepository.ts`**

  ```typescript
  interface IPostItRepository {
    save(postIt: PostIt): Promise<PostIt | null>;
    findById(id: Id): Promise<PostIt | null>;
    findBySession(sessionId: Id): Promise<PostItList>;
    findByUserInSession(userId: Id, sessionId: Id): Promise<PostItList>;
    delete(id: Id): Promise<boolean>;
  }
  ```

- [ ] **`src/retro/domain/ISessionUserRepository.ts`**

  ```typescript
  interface ISessionUserRepository {
    save(user: SessionUser): Promise<SessionUser | null>;
    findById(id: Id): Promise<SessionUser | null>;
    findBySession(sessionId: Id): Promise<SessionUserList>;
    delete(id: Id): Promise<boolean>;
  }
  ```

- [ ] **`src/retro/domain/IRetroSessionRepository.ts`**
  ```typescript
  interface IRetroSessionRepository {
    save(session: RetroSession): Promise<RetroSession | null>;
    findById(id: Id): Promise<RetroSession | null>;
    findByCode(code: SessionCode): Promise<RetroSession | null>;
    delete(id: Id): Promise<boolean>;
  }
  ```

---

### **FASE 9: Esquemas Zod para Validación** ⏱️ 1 día

#### 9.1 Implementar Esquemas de Validación

- [ ] **`src/retro/infrastructure/schemas/PostItSchema.ts`**
  - Esquema Zod para validar datos de Supabase
  - Transformación de datos DB → Entidad de dominio

- [ ] **`src/retro/infrastructure/schemas/SessionUserSchema.ts`**
  - Esquema Zod para validar datos de Supabase
  - Transformación de datos DB → Entidad de dominio

- [ ] **`src/retro/infrastructure/schemas/RetroSessionSchema.ts`**
  - Esquema Zod para validar datos de Supabase
  - Transformación de datos DB → Entidad de dominio

---

### **FASE 10: Implementación de Repositorios** ⏱️ 2 días

#### 10.1 Implementar Repositorios de Supabase

- [ ] **`src/retro/infrastructure/SupabasePostItRepository.ts`**
  - Implementa `IPostItRepository`
  - Métodos CRUD con transformación DB ↔ Dominio
  - Manejo de errores con patrón null-safe

- [ ] **`src/retro/infrastructure/SupabaseSessionUserRepository.ts`**
  - Implementa `ISessionUserRepository`
  - Métodos CRUD con transformación DB ↔ Dominio

- [ ] **`src/retro/infrastructure/SupabaseRetroSessionRepository.ts`**
  - Implementa `IRetroSessionRepository`
  - Métodos CRUD con transformación DB ↔ Dominio

#### 10.2 Crear Pruebas de Integración de Repositorios

- [ ] `test/infrastructure/SupabasePostItRepository.test.ts`
- [ ] `test/infrastructure/SupabaseSessionUserRepository.test.ts`
- [ ] `test/infrastructure/SupabaseRetroSessionRepository.test.ts`

---

### **FASE 11: Use Cases de Aplicación** ⏱️ 2 días

#### 11.1 Implementar Use Cases Principales

- [ ] **`src/retro/application/CreateSessionUseCase.ts`**
  - Parámetros primitivos: `{ moderatorId: string, moderatorName: string }`
  - Transformación a objetos de dominio en `execute()`
  - Retorna `RetroSession | null`

- [ ] **`src/retro/application/JoinSessionUseCase.ts`**
  - Parámetros: `{ sessionCode: string, userName: string }`
  - Validación de sesión existente
  - Creación de SessionUser

- [ ] **`src/retro/application/CreatePostItUseCase.ts`**
  - Parámetros: `{ sessionId: string, userId: string, text: string, category: string }`
  - Validación de fase (solo en private/collaborative)

- [ ] **`src/retro/application/MovePostItUseCase.ts`**
  - Parámetros: `{ postItId: string, category?: string, position?: { x: number, y: number } }`
  - Actualización de categoría y/o posición

- [ ] **`src/retro/application/DeletePostItUseCase.ts`**
  - Parámetros: `{ postItId: string, userId: string }`
  - Validación de propiedad (solo creador puede eliminar)

- [ ] **`src/retro/application/MarkUserCompletedUseCase.ts`**
  - Parámetros: `{ sessionId: string, userId: string, completed: boolean }`
  - Actualización de estado de usuario

- [ ] **`src/retro/application/TransitionPhaseUseCase.ts`**
  - Parámetros: `{ sessionId: string, moderatorId: string, targetPhase: string }`
  - Validación de permisos (solo moderador)
  - Validación de transición válida

#### 11.2 Crear Pruebas Unitarias de Use Cases (con Mocks)

- [ ] `test/domain/retro/units/CreateSessionUseCase.test.ts`
- [ ] `test/domain/retro/units/JoinSessionUseCase.test.ts`
- [ ] `test/domain/retro/units/CreatePostItUseCase.test.ts`
- [ ] `test/domain/retro/units/MovePostItUseCase.test.ts`
- [ ] `test/domain/retro/units/DeletePostItUseCase.test.ts`
- [ ] `test/domain/retro/units/MarkUserCompletedUseCase.test.ts`
- [ ] `test/domain/retro/units/TransitionPhaseUseCase.test.ts`

#### 11.3 Crear Pruebas de Integración de Use Cases (con Supabase Real)

- [ ] `test/domain/retro/integrations/CreateSessionUseCase.test.ts`
- [ ] `test/domain/retro/integrations/JoinSessionUseCase.test.ts`
- [ ] `test/domain/retro/integrations/CreatePostItUseCase.test.ts`

---

### **FASE 12: Servicio de Realtime** ⏱️ 1 día

#### 12.1 Implementar Servicio de Realtime

- [ ] **`src/shared/infrastructure/realtime/SupabaseRealtimeService.ts`**
  - Método `subscribeToSession(sessionId: string, callback)`
  - Método `subscribeToPostIts(sessionId: string, callback)`
  - Método `subscribeToUsers(sessionId: string, callback)`
  - Método `unsubscribe(subscription)`
  - Manejo de reconexión automática

---

### **FASE 13: Configuración de Vitest** ⏱️ 0.5 días

#### 13.1 Configurar Testing Framework

- [ ] Crear `vitest.config.ts`:

  ```typescript
  import { defineConfig } from "vitest/config";
  import react from "@vitejs/plugin-react";

  export default defineConfig({
    plugins: [react()],
    test: {
      environment: "jsdom",
      setupFiles: ["./test/setup.ts"],
      coverage: {
        provider: "v8",
        reporter: ["text", "json", "html"],
      },
    },
  });
  ```

- [ ] Crear `test/setup.ts` con configuración global

- [ ] Añadir scripts a `package.json`:
  ```json
  {
    "scripts": {
      "test": "vitest",
      "test:ui": "vitest --ui",
      "test:coverage": "vitest --coverage"
    }
  }
  ```

---

### **FASE 14: Componentes Base de UI** ⏱️ 1 día

#### 14.1 Crear Componentes Compartidos

- [ ] **`app/components/shared/Button.tsx`**
  - Variantes: primary, secondary, danger
  - Estados: loading, disabled

- [ ] **`app/components/shared/Input.tsx`**
  - Validación integrada
  - Estados de error

- [ ] **`app/components/shared/Card.tsx`**
  - Container base para post-its y secciones

#### 14.2 Crear Sistema de Colores

- [ ] Configurar Tailwind con colores de categorías:
  ```javascript
  // tailwind.config.js
  module.exports = {
    theme: {
      extend: {
        colors: {
          "postit-keep": "#10B981",
          "postit-improve": "#F59E0B",
          "postit-ideas": "#3B82F6",
          "postit-stop": "#A855F7",
        },
      },
    },
  };
  ```

---

### **FASE 15: Hooks de React** ⏱️ 1 día

#### 15.1 Implementar Custom Hooks

- [ ] **`app/hooks/useSession.ts`**
  - Estado de sesión actual
  - Métodos para crear/unirse a sesión
  - Integración con CreateSessionUseCase y JoinSessionUseCase

- [ ] **`app/hooks/usePostIts.ts`**
  - Lista de post-its de la sesión
  - Métodos CRUD de post-its
  - Integración con Use Cases

- [ ] **`app/hooks/useRealtime.ts`**
  - Suscripción a cambios en tiempo real
  - Actualización automática de estado
  - Integración con SupabaseRealtimeService

---

### **FASE 16: Configuración de Vercel** ⏱️ 0.5 días

#### 16.1 Preparar Deploy

- [ ] Crear `vercel.json` con configuración
- [ ] Configurar variables de entorno en Vercel Dashboard
- [ ] Conectar repositorio Git con Vercel
- [ ] Configurar preview deployments

---

### **FASE 17: Documentación del Boilerplate** ⏱️ 0.5 días

#### 17.1 Crear Documentación

- [ ] **`README.md`**
  - Descripción del proyecto
  - Stack tecnológico
  - Instrucciones de instalación
  - Comandos disponibles
  - Estructura de carpetas explicada

- [ ] **`ARCHITECTURE.md`**
  - Explicación de arquitectura DDD
  - Principios SOLID aplicados
  - Flujo de datos
  - Patrones utilizados

- [ ] **`CONTRIBUTING.md`**
  - Guía de contribución
  - Convenciones de código
  - Proceso de testing
  - Pull request template

---

## 📊 Resumen de Tiempo Estimado

| Fase      | Descripción                        | Tiempo          |
| --------- | ---------------------------------- | --------------- |
| 1         | Configuración Inicial del Proyecto | 1-2 días        |
| 2         | Estructura de Carpetas DDD         | 0.5 días        |
| 3         | Configuración de Supabase          | 1 día           |
| 4         | Objetos Kernel                     | 1 día           |
| 5         | Value Objects Compartidos          | 1.5 días        |
| 6         | Entidades de Dominio               | 2 días          |
| 7         | Objetos Madre                      | 1 día           |
| 8         | Interfaces de Repositorios         | 0.5 días        |
| 9         | Esquemas Zod                       | 1 día           |
| 10        | Implementación de Repositorios     | 2 días          |
| 11        | Use Cases de Aplicación            | 2 días          |
| 12        | Servicio de Realtime               | 1 día           |
| 13        | Configuración de Vitest            | 0.5 días        |
| 14        | Componentes Base de UI             | 1 día           |
| 15        | Hooks de React                     | 1 día           |
| 16        | Configuración de Vercel            | 0.5 días        |
| 17        | Documentación                      | 0.5 días        |
| **TOTAL** |                                    | **~17-18 días** |

---

## ✅ Checklist de Validación del Boilerplate

### Arquitectura

- [ ] Estructura DDD completa (domain, application, infrastructure, presentation)
- [ ] Separación clara de capas
- [ ] Dependencias apuntando hacia el dominio (DIP)
- [ ] Interfaces de repositorios en capa de dominio

### Código de Dominio

- [ ] Entidades con métodos semánticos (sin getters/setters genéricos)
- [ ] Value Objects inmutables con validación
- [ ] Patrón `createOrNull()` implementado
- [ ] Colecciones tipadas (ListOf) implementadas
- [ ] Agregado raíz (RetroSession) con invariantes de negocio

### Testing

- [ ] Objetos Madre creados para todas las entidades
- [ ] Pruebas unitarias de modelos de dominio
- [ ] Pruebas unitarias de Use Cases con mocks
- [ ] Pruebas de integración con Supabase real
- [ ] Cobertura > 80% en capa de dominio

### Infraestructura

- [ ] Supabase configurado con RLS
- [ ] Realtime habilitado
- [ ] Esquemas Zod para validación
- [ ] Repositorios implementados con transformación DB ↔ Dominio

### Frontend

- [ ] Next.js 16 con App Router configurado
- [ ] TailwindCSS con sistema de colores
- [ ] Componentes base reutilizables
- [ ] Hooks personalizados para lógica de negocio

### DevOps

- [ ] ESLint con reglas SOLID
- [ ] Prettier configurado
- [ ] Vitest configurado
- [ ] Vercel configurado para deploy
- [ ] Variables de entorno documentadas

### Documentación

- [ ] README completo
- [ ] Arquitectura documentada
- [ ] Guía de contribución
- [ ] Comentarios en código complejo

---

## 🚀 Próximos Pasos Después del Boilerplate

Una vez completado el boilerplate, el proyecto estará listo para:

1. **Implementar UI de páginas principales**
   - Landing page
   - Página de creación de sesión
   - Página de sala de espera
   - Página de retrospectiva (privada/colaborativa)

2. **Implementar Drag & Drop**
   - Integración de @dnd-kit
   - Zonas de categorías
   - Agrupación de post-its

3. **Implementar Panel de Moderador**
   - Control de fases
   - Vista de progreso de usuarios
   - Gestión de sesión

4. **Testing E2E**
   - Flujos completos de usuario
   - Testing de tiempo real
   - Testing de concurrencia

---

## 📝 Notas Importantes

### Principios a Seguir Durante la Implementación

1. **Métodos Semánticos Siempre**
   - ❌ `postIt.setText("nuevo texto")`
   - ✅ `postIt.updateContent(NonEmptyString.create("nuevo texto"))`

2. **Transformación Primitivos → Dominio en Use Cases**
   - Los Use Cases reciben primitivos en `execute()`
   - Transforman a objetos de dominio internamente
   - Repositorios SIEMPRE reciben objetos de dominio

3. **Null Safety en Lugar de Excepciones**
   - Usar `createOrNull()` para creación segura
   - Retornar `null` en casos inválidos
   - Evitar `throw` excepto en errores críticos

4. **Testing Exhaustivo**
   - Crear Mothers antes de implementar entidades
   - Escribir pruebas antes de implementar Use Cases
   - Probar casos felices y casos de error

5. **Inmutabilidad**
   - Value Objects siempre inmutables
   - Entidades retornan nuevas instancias en métodos de actualización
   - Evitar mutación de estado

### Comandos Útiles Durante el Desarrollo

```bash
# Ejecutar todas las pruebas
npm run test

# Ejecutar pruebas con UI
npm run test:ui

# Ejecutar pruebas con cobertura
npm run test:coverage

# Ejecutar linter
npm run lint

# Formatear código
npm run format

# Ejecutar en desarrollo
npm run dev

# Build de producción
npm run build
```

---

## 🎯 Criterios de Éxito del Boilerplate

El boilerplate se considerará completo cuando:

1. ✅ Todas las fases estén implementadas
2. ✅ Todas las pruebas pasen (unitarias e integración)
3. ✅ Cobertura de código > 80% en dominio
4. ✅ ESLint no reporte errores
5. ✅ Build de Next.js exitoso
6. ✅ Deploy en Vercel funcional
7. ✅ Documentación completa y actualizada
8. ✅ Variables de entorno configuradas
9. ✅ Supabase con RLS y Realtime funcionando
10. ✅ Estructura de carpetas DDD completa

---

**Fecha de creación**: 2026-02-20  
**Versión**: 1.0  
**Basado en**: ESPECIFICACIONES.md
