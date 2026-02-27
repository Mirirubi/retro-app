# Especificaciones del Proyecto - Herramienta de Retrospectiva de Sprint

## 📋 Resumen del Proyecto

Herramienta web para dinamizar las reuniones de retrospectiva de sprint, permitiendo a los equipos colaborar de forma estructurada mediante post-its digitales en tiempo real.

## 🎯 Objetivo

Facilitar las retrospectivas de sprint con una interfaz intuitiva que permita a los equipos:

- Reflexionar individualmente de forma privada
- Compartir y agrupar ideas colaborativamente
- Organizar feedback en categorías visuales

## 👥 Roles de Usuario

### Moderador

- Crea el espacio de trabajo de la retrospectiva
- Controla las transiciones entre fases
- Gestiona el flujo de la sesión

### Miembro del Equipo

- Se une al espacio de trabajo introduciendo su nombre
- Escribe y organiza post-its
- Participa en la fase colaborativa

## 🔄 Flujo de Uso

### Fase 1: Acceso a la Sesión

1. El moderador crea un nuevo espacio de retrospectiva
2. Se genera un enlace/código único para la sesión
3. Los miembros del equipo acceden introduciendo su nombre
4. Todos entran a la sala de espera hasta que el moderador inicie

### Fase 2: Reflexión Individual (Privada)

- **Duración**: Controlada por el moderador
- **Visibilidad**: Los post-its son privados para cada usuario
- **Acciones permitidas**:
  - Crear post-its en 4 categorías:
    - 🟢 **Verde**: Cosas que han ido bien (Keep doing)
    - 🟠 **Naranja**: Cosas a mejorar (Improve)
    - 🔵 **Azul**: Ideas nuevas (New ideas)
    - 🟣 **Morado**: Cosas que dejar de hacer (Stop doing)
  - Escribir texto en cada post-it
  - Mover post-its entre zonas (drag & drop)
  - El color del post-it cambia automáticamente según la zona
  - Editar o eliminar post-its propios
- **Indicador de progreso**: Cada usuario marca cuando ha terminado
- **Transición**: Cuando todos marcan "terminado", el moderador puede avanzar a la siguiente fase

### Fase 3: Compartir y Agrupar (Colaborativa)

- **Visibilidad**: Todos los post-its se hacen visibles para todos
- **Acciones permitidas**:
  - Ver post-its de todos los miembros
  - Agrupar post-its similares mediante drag & drop
  - Discutir y organizar ideas
  - Votar o priorizar (feature futura)

## 🎨 Categorías de Post-its

| Color      | Categoría  | Propósito                     |
| ---------- | ---------- | ----------------------------- |
| 🟢 Verde   | Keep Doing | Prácticas exitosas a mantener |
| 🟠 Naranja | Improve    | Áreas de mejora identificadas |
| 🔵 Azul    | New Ideas  | Propuestas e innovaciones     |
| 🟣 Morado  | Stop Doing | Prácticas a eliminar          |

## 💡 Características Principales

### MVP (Mínimo Producto Viable)

1. **Acceso Simple con Nombre**
   - Input de nombre de usuario
   - Identificación de usuarios en la sesión por nombre
   - Sin autenticación real (para MVP)

2. **Gestión de Sesiones**
   - Crear sala de retrospectiva
   - Generar enlace/código único
   - Unirse a sala existente

3. **Post-its Digitales**
   - Crear, editar, eliminar post-its
   - 4 zonas de color diferenciadas
   - Cambio automático de color según zona

4. **Drag & Drop**
   - Mover post-its entre zonas
   - Reorganizar post-its dentro de una zona
   - Agrupar post-its en fase colaborativa

5. **Control de Fases**
   - Fase privada (individual)
   - Fase pública (colaborativa)
   - Indicador de "terminado" por usuario
   - Control de transición por moderador

6. **Sincronización en Tiempo Real**
   - Actualización automática de post-its
   - Visibilidad de usuarios conectados
   - Estado de progreso de cada miembro

## 🏗️ Arquitectura Técnica

### Stack Tecnológico Propuesto (Sin Backend Propio)

#### Frontend

- **Framework**: Next.js 16 (App Router) + TypeScript
- **Styling**: TailwindCSS + Base UI
- **Drag & Drop**: @dnd-kit/core (mejor compatibilidad con React Server Components)
- **Estado**: React Context + Server Components (sin Zustand)
- **Tiempo Real**: Supabase Realtime client

#### Backend as a Service (BaaS)

**Supabase (Seleccionado)**

- **Database**: PostgreSQL con Realtime
- **Hosting**: Vercel (optimizado para Next.js)
- **Ventajas**:
  - Open source
  - SQL completo con tipos seguros
  - Realtime subscriptions nativas
  - SDK oficial para Next.js con Server Components
  - Row Level Security (RLS) para privacidad de datos
  - Excelente integración con TypeScript
  - Autenticación disponible para futuras fases

**Nota**: Para el MVP no se requiere autenticación real, solo identificación por nombre

### Arquitectura DDD (Domain-Driven Design)

El proyecto seguirá principios de Domain-Driven Design siguiendo las convenciones de la skill **domain-builder** para mantener una arquitectura limpia y escalable:

#### Estructura de Capas

```
src/
├── retro/                     # Contexto de Retrospectiva
│   ├── application/           # Capa de Aplicación (Use Cases)
│   │   ├── CreateSessionUseCase.ts
│   │   ├── JoinSessionUseCase.ts
│   │   ├── CreatePostItUseCase.ts
│   │   ├── MovePostItUseCase.ts
│   │   ├── DeletePostItUseCase.ts
│   │   ├── TransitionPhaseUseCase.ts
│   │   └── MarkUserCompletedUseCase.ts
│   │
│   ├── domain/                # Capa de Dominio
│   │   ├── RetroSession.ts    # Entidad principal (Agregado raíz)
│   │   ├── PostIt.ts          # Entidad
│   │   ├── SessionUser.ts     # Entidad
│   │   ├── PostItList.ts      # ListOf para colecciones
│   │   ├── SessionUserList.ts # ListOf para colecciones
│   │   ├── IRetroSessionRepository.ts  # Interface de repositorio
│   │   ├── IPostItRepository.ts
│   │   └── ISessionUserRepository.ts
│   │
│   └── infrastructure/        # Capa de Infraestructura
│       ├── SupabaseRetroSessionRepository.ts
│       ├── SupabasePostItRepository.ts
│       ├── SupabaseSessionUserRepository.ts
│       └── schemas/           # Esquemas Zod para validación
│           ├── RetroSessionSchema.ts
│           ├── PostItSchema.ts
│           └── SessionUserSchema.ts
│
├── shared/                    # Objetos compartidos entre contextos
│   ├── domain/
│   │   ├── SessionCode.ts     # Value Object
│   │   ├── PostItCategory.ts  # Value Object
│   │   ├── SessionPhase.ts    # Value Object
│   │   └── Position.ts        # Value Object
│   └── infrastructure/
│       ├── supabase/
│       │   ├── client.ts
│       │   └── types.ts
│       └── realtime/
│           └── SupabaseRealtimeService.ts
│
├── kernel/                    # Objetos de valor primitivos reutilizables
│   ├── Id.ts
│   ├── Timestamp.ts
│   └── NonEmptyString.ts
│
└── app/                       # Next.js App Router (Presentación)
    ├── page.tsx
    ├── session/[code]/
    ├── components/
    │   ├── session/
    │   ├── postit/
    │   └── shared/
    └── hooks/
        ├── useSession.ts
        ├── usePostIts.ts
        └── useRealtime.ts

test/
├── domain/
│   └── retro/
│       ├── models/            # Pruebas unitarias de modelos
│       │   ├── RetroSession.test.ts
│       │   ├── PostIt.test.ts
│       │   └── SessionUser.test.ts
│       ├── units/             # Pruebas unitarias de Use Cases (mocks)
│       │   ├── CreateSessionUseCase.test.ts
│       │   └── CreatePostItUseCase.test.ts
│       └── integrations/      # Pruebas de integración (repositorio real)
│           ├── CreateSessionUseCase.test.ts
│           └── CreatePostItUseCase.test.ts
│
└── mothers/                   # Objetos Madre (Test Data Builders)
    └── retro/
        ├── RetroSessionMother.ts
        ├── PostItMother.ts
        └── SessionUserMother.ts
```

#### Principios DDD Aplicados (según domain-builder skill)

1. **Entidades con Métodos Semánticos**
   - Evitar getters/setters genéricos
   - Usar métodos que expresen intención de negocio
   - Ejemplo: `session.transitionToCollaborativePhase()` en lugar de `session.setPhase('collaborative')`

2. **Value Objects Inmutables**
   - SessionCode, PostItCategory, SessionPhase, Position
   - Validación en constructor
   - Métodos de comparación y transformación

3. **Agregados**
   - RetroSession es el agregado raíz
   - Controla el ciclo de vida de PostIts y SessionUsers
   - Garantiza invariantes de negocio

4. **Patrones de Seguridad Nula**
   - `createOrNull()`: Creación segura de objetos
   - `toJSONOrNull()`: Serialización segura
   - Evitar excepciones, retornar null en casos inválidos

5. **Colecciones Tipadas (ListOf)**
   - `PostItList` en lugar de `PostIt[]`
   - Métodos semánticos: `addPostIt()`, `removePostIt()`, `filterByCategory()`
   - Validaciones de colección

6. **Repositorios**
   - Interfaces en capa de dominio
   - Implementaciones en infraestructura
   - **SIEMPRE reciben objetos de dominio, nunca primitivos**
   - Use Cases transforman primitivos a dominio en `execute()`

7. **Use Cases**
   - Un caso de uso = una acción de negocio
   - Método `execute()` con parámetros primitivos
   - Transformación de primitivos a objetos de dominio
   - Orquestación de repositorios y servicios

8. **Eventos de Dominio**
   - Automáticos mediante decoradores
   - No requieren código especial
   - Registran cambios importantes en entidades

### Principios SOLID

El código seguirá estrictamente los principios SOLID:

#### S - Single Responsibility Principle (SRP)

- Cada clase/módulo tiene una única responsabilidad
- Ejemplo: `CreatePostItUseCase` solo se encarga de crear post-its
- Los repositorios solo manejan persistencia, no lógica de negocio

#### O - Open/Closed Principle (OCP)

- Abierto para extensión, cerrado para modificación
- Uso de interfaces para repositorios permite cambiar de Supabase a otra DB sin modificar use cases
- Estrategias para diferentes tipos de agrupación de post-its

#### L - Liskov Substitution Principle (LSP)

- Las implementaciones de repositorios son intercambiables
- Cualquier implementación de `IPostItRepository` puede sustituir a otra

#### I - Interface Segregation Principle (ISP)

- Interfaces específicas y pequeñas
- Ejemplo: `IPostItReader` e `IPostItWriter` en lugar de un único `IPostItRepository` grande
- Clientes solo dependen de métodos que realmente usan

#### D - Dependency Inversion Principle (DIP)

- Dependencias apuntan hacia abstracciones, no implementaciones
- Use cases dependen de interfaces de repositorios, no de implementaciones concretas
- Inyección de dependencias mediante constructores

```typescript
// Ejemplo de DIP y Patrones de la Skill

// ❌ INCORRECTO: Getters/setters genéricos
class PostIt {
  getText(): string {
    return this.text;
  }
  setText(text: string): void {
    this.text = text;
  }
}

// ✅ CORRECTO: Métodos semánticos
class PostIt {
  updateContent(newText: string): PostIt {
    return new PostIt({ ...this.props, text: newText });
  }

  moveToCategory(category: PostItCategory): PostIt {
    return new PostIt({ ...this.props, category });
  }
}

// ✅ CORRECTO: Use Case con transformación de primitivos a dominio
class CreatePostItUseCase {
  constructor(
    private readonly postItRepository: IPostItRepository,
    private readonly sessionRepository: IRetroSessionRepository,
  ) {}

  async execute(params: {
    sessionId: string;
    userId: string;
    text: string;
    category: string;
  }): Promise<PostIt | null> {
    // 1. Transformar primitivos a objetos de dominio
    const sessionId = Id.createOrNull(params.sessionId);
    const userId = Id.createOrNull(params.userId);
    const category = PostItCategory.createOrNull(params.category);
    const text = NonEmptyString.createOrNull(params.text);

    if (!sessionId || !userId || !category || !text) {
      return null;
    }

    // 2. Crear entidad de dominio
    const postIt = PostIt.create({
      sessionId,
      userId,
      category,
      text,
      position: Position.default(),
    });

    // 3. Persistir usando repositorio (recibe objeto de dominio)
    return await this.postItRepository.save(postIt);
  }
}

// ✅ CORRECTO: Patrón createOrNull para seguridad nula
class SessionCode {
  private constructor(private readonly value: string) {}

  static createOrNull(value: string): SessionCode | null {
    if (!value || value.length !== 6) return null;
    return new SessionCode(value.toUpperCase());
  }

  toString(): string {
    return this.value;
  }
}
```

### Modelo de Datos

```typescript
// Sesión de Retrospectiva
interface RetroSession {
  id: string;
  code: string; // Código único para unirse
  moderatorId: string;
  createdAt: timestamp;
  phase: "waiting" | "private" | "collaborative" | "finished";
  participants: string[]; // User IDs
  completedUsers: string[]; // Users que marcaron "terminado"
}

// Post-it
interface PostIt {
  id: string;
  sessionId: string;
  userId: string;
  userName: string;
  category: "keep" | "improve" | "ideas" | "stop";
  text: string;
  position: { x: number; y: number };
  groupId?: string; // Para agrupar post-its
  createdAt: timestamp;
  updatedAt: timestamp;
}

// Usuario en Sesión
interface SessionUser {
  id: string; // ID generado localmente
  sessionId: string;
  userName: string; // Nombre introducido por el usuario
  isCompleted: boolean;
  isModerator: boolean;
  joinedAt: timestamp;
  // Campos para futuras versiones con OAuth:
  // userEmail?: string;
  // userPhoto?: string;
  // authProvider?: 'google' | 'github';
}
```

## 📊 Priorización de Funcionalidades

### 🔴 PRIORIDAD ALTA - Sprint 1 (MVP)

**Objetivo**: Producto funcional básico

1. **Acceso Simple con Nombre** (1 día)
   - Input de nombre de usuario
   - Generación de ID único local
   - Validación básica (nombre no vacío)

2. **Crear y Unirse a Sesión** (2 días)
   - Crear sala con código único
   - Unirse mediante código
   - Vista de sala de espera

3. **Post-its Básicos** (4 días)
   - Crear post-it con texto
   - Asignar a categoría (4 colores)
   - Eliminar post-it propio
   - Vista de cuadrícula por categoría

4. **Drag & Drop entre Zonas** (3 días)
   - Mover post-its entre categorías
   - Cambio automático de color
   - Persistencia de cambios

5. **Control de Fases** (3 días)
   - Fase privada: solo ver propios post-its
   - Botón "He terminado" para usuarios
   - Botón "Siguiente fase" para moderador
   - Fase colaborativa: ver todos los post-its

6. **Sincronización Tiempo Real** (2 días)
   - Listeners de Supabase Realtime
   - Actualización automática de post-its
   - Indicador de usuarios conectados

7. **Implementación DDD y SOLID** (3 días)
   - Estructura de capas (Domain, Application, Infrastructure, Presentation)
   - Definición de entidades y value objects
   - Implementación de repositorios con interfaces
   - Use cases para cada funcionalidad

8. **Estrategia de Pruebas** (4 días)
   - Objetos Madre (Mothers) para datos de prueba
   - Pruebas unitarias de modelos de dominio
   - Pruebas unitarias de Use Cases (con mocks)
   - Pruebas de integración de Use Cases (repositorio real)

**Total Sprint 1: ~22 días** (incluye arquitectura DDD, SOLID y testing exhaustivo)

### Semana 1-2: Configuración y Setup Inicial

- Setup del proyecto Next.js 16 con App Router
- Configuración de TypeScript estricto + TailwindCSS + Base UI
- Configuración de Supabase (PostgreSQL + Realtime)
- Setup de estructura DDD (carpetas domain, application, infrastructure, presentation)
- Configuración de ESLint con reglas SOLID
- Setup de Vercel para deployment
- Implementar acceso simple con nombre
- Diseño de UI básica con componentes de Base UI

### Semana 3-4: Funcionalidad Core

- Crear/unirse a sesiones
- CRUD de post-its
- Implementar 4 zonas de categorías
- Drag & drop básico

### Semana 5-6: Tiempo Real y Fases

- Sincronización Firestore
- Control de fases (privada/colaborativa)
- Sistema de "terminado"
- Panel de moderador

### Semana 7: Testing y Pulido

- Testing con usuarios reales
- Corrección de bugs
- Optimización de rendimiento
- Deploy a producción

## 🧪 Estrategia de Pruebas (según domain-builder skill)

### Filosofía de Testing

- **Guiado por pruebas**: Todo modelo y caso de uso debe tener pruebas exhaustivas
- **Objetos Madre obligatorios**: Base de datos de prueba reutilizable
- **Tres niveles de pruebas**: Modelos, Units (mocks), Integrations (real)
- **Cobertura completa**: Casos felices, casos de error, validaciones

### Estructura de Pruebas

```
test/
├── domain/
│   └── retro/
│       ├── models/            # Pruebas unitarias de modelos
│       │   ├── RetroSession.test.ts
│       │   ├── PostIt.test.ts
│       │   └── SessionUser.test.ts
│       ├── units/             # Pruebas unitarias de Use Cases (mocks)
│       │   ├── CreateSessionUseCase.test.ts
│       │   └── CreatePostItUseCase.test.ts
│       └── integrations/      # Pruebas de integración (repositorio real)
│           ├── CreateSessionUseCase.test.ts
│           └── CreatePostItUseCase.test.ts
│
└── mothers/                   # Objetos Madre (Test Data Builders)
    └── retro/
        ├── RetroSessionMother.ts
        ├── PostItMother.ts
        └── SessionUserMother.ts
```

### Objetos Madre (Mothers)

Patrón para crear datos de prueba reutilizables y semánticos:

```typescript
// test/mothers/retro/PostItMother.ts
export class PostItMother {
  static create(params?: Partial<PostItProps>): PostIt {
    return PostIt.create({
      id: params?.id ?? Id.create(),
      sessionId: params?.sessionId ?? Id.create(),
      userId: params?.userId ?? Id.create(),
      userName: params?.userName ?? NonEmptyString.create("Test User"),
      category: params?.category ?? PostItCategory.keep(),
      text: params?.text ?? NonEmptyString.create("Test post-it"),
      position: params?.position ?? Position.default(),
      createdAt: params?.createdAt ?? Timestamp.now(),
      updatedAt: params?.updatedAt ?? Timestamp.now(),
    });
  }

  static keepDoing(): PostIt {
    return this.create({
      category: PostItCategory.keep(),
      text: NonEmptyString.create("Great teamwork!"),
    });
  }

  static improve(): PostIt {
    return this.create({
      category: PostItCategory.improve(),
      text: NonEmptyString.create("Better communication needed"),
    });
  }

  static withInvalidText(): PostIt | null {
    return PostIt.createOrNull({
      ...this.create().toJSON(),
      text: "", // Invalid
    });
  }
}
```

### Pruebas Unitarias de Modelos

Probar métodos semánticos y validaciones:

```typescript
// test/domain/retro/models/PostIt.test.ts
import { describe, it, expect } from "vitest";
import { PostItMother } from "../../../mothers/retro/PostItMother";
import { PostItCategory } from "../../../../src/shared/domain/PostItCategory";

describe("PostIt", () => {
  describe("updateContent", () => {
    it("should update text content", () => {
      const postIt = PostItMother.create();
      const newText = NonEmptyString.create("Updated text");

      const updated = postIt.updateContent(newText);

      expect(updated.text.toString()).toBe("Updated text");
      expect(updated.id.equals(postIt.id)).toBe(true);
    });
  });

  describe("moveToCategory", () => {
    it("should change category from keep to improve", () => {
      const postIt = PostItMother.keepDoing();

      const moved = postIt.moveToCategory(PostItCategory.improve());

      expect(moved.category.isImprove()).toBe(true);
    });
  });

  describe("createOrNull", () => {
    it("should return null for empty text", () => {
      const postIt = PostItMother.withInvalidText();

      expect(postIt).toBeNull();
    });
  });
});
```

### Pruebas Unitarias de Use Cases (con Mocks)

Probar lógica de negocio aislada:

```typescript
// test/domain/retro/units/CreatePostItUseCase.test.ts
import { describe, it, expect, vi } from "vitest";
import { CreatePostItUseCase } from "../../../../src/retro/application/CreatePostItUseCase";
import { PostItMother } from "../../../mothers/retro/PostItMother";

describe("CreatePostItUseCase (Unit)", () => {
  it("should create post-it successfully", async () => {
    // Arrange
    const mockRepository = {
      save: vi.fn().mockResolvedValue(PostItMother.create()),
    };
    const useCase = new CreatePostItUseCase(mockRepository);

    // Act
    const result = await useCase.execute({
      sessionId: "session-123",
      userId: "user-456",
      text: "Great sprint!",
      category: "keep",
    });

    // Assert
    expect(result).not.toBeNull();
    expect(mockRepository.save).toHaveBeenCalledTimes(1);
  });

  it("should return null for invalid category", async () => {
    const mockRepository = { save: vi.fn() };
    const useCase = new CreatePostItUseCase(mockRepository);

    const result = await useCase.execute({
      sessionId: "session-123",
      userId: "user-456",
      text: "Test",
      category: "invalid-category",
    });

    expect(result).toBeNull();
    expect(mockRepository.save).not.toHaveBeenCalled();
  });
});
```

### Pruebas de Integración (con Repositorio Real)

Probar flujo completo con Supabase:

```typescript
// test/domain/retro/integrations/CreatePostItUseCase.test.ts
import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { CreatePostItUseCase } from "../../../../src/retro/application/CreatePostItUseCase";
import { SupabasePostItRepository } from "../../../../src/retro/infrastructure/SupabasePostItRepository";
import { createClient } from "@supabase/supabase-js";

describe("CreatePostItUseCase (Integration)", () => {
  let repository: SupabasePostItRepository;
  let useCase: CreatePostItUseCase;
  let supabase: any;

  beforeEach(() => {
    supabase = createClient(
      process.env.SUPABASE_URL!,
      process.env.SUPABASE_KEY!,
    );
    repository = new SupabasePostItRepository(supabase);
    useCase = new CreatePostItUseCase(repository);
  });

  afterEach(async () => {
    // Cleanup test data
    await supabase.from("postits").delete().eq("text", "Integration test");
  });

  it("should persist post-it to Supabase", async () => {
    const result = await useCase.execute({
      sessionId: "test-session",
      userId: "test-user",
      text: "Integration test",
      category: "keep",
    });

    expect(result).not.toBeNull();
    expect(result?.text.toString()).toBe("Integration test");

    // Verify in database
    const { data } = await supabase
      .from("postits")
      .select("*")
      .eq("id", result?.id.toString())
      .single();

    expect(data).not.toBeNull();
    expect(data.text).toBe("Integration test");
  });
});
```

### Convenciones de Naming para Tests

- **Archivos de prueba**: `{EntityName}.test.ts`
- **Mothers**: `{EntityName}Mother.ts`
- **Describe blocks**: Nombre de la clase o método
- **It blocks**: Descripción en inglés del comportamiento esperado
- **Patrón AAA**: Arrange, Act, Assert (comentado en pruebas complejas)

### Checklist de Calidad para Pruebas

- [ ] Objeto Madre creado para cada entidad
- [ ] Pruebas unitarias de modelo (métodos semánticos, validaciones)
- [ ] Pruebas unitarias de Use Case con mocks
- [ ] Pruebas de integración con repositorio real
- [ ] Casos felices cubiertos
- [ ] Casos de error cubiertos
- [ ] Validaciones de null safety probadas
- [ ] Cleanup de datos de prueba en afterEach

## 🎨 Consideraciones de Diseño

### UI/UX

- **Diseño limpio y minimalista**: Enfoque en la funcionalidad
- **Responsive**: Funcional en desktop y tablet (mobile opcional)
- **Accesibilidad**: Contraste de colores, keyboard navigation
- **Feedback visual**: Animaciones suaves, estados de carga

### Colores Sugeridos

- Verde: `#10B981` (Emerald-500)
- Naranja: `#F59E0B` (Amber-500)
- Azul: `#3B82F6` (Blue-500)
- Morado: `#A855F7` (Purple-500)

## ⚠️ Riesgos y Consideraciones

### Técnicos

1. **Límites de Supabase Free Tier**
   - Monitorizar uso de database size y bandwidth
   - Optimizar queries SQL
   - Plan de escalado si crece
   - Índices apropiados en PostgreSQL

2. **Concurrencia en Drag & Drop**
   - Conflictos si múltiples usuarios mueven el mismo post-it
   - Implementar optimistic updates

3. **Pérdida de Conexión**
   - Manejo de offline
   - Reconexión automática
   - Sincronización al reconectar

### UX

1. **Privacidad en Fase Privada**
   - Asegurar que los post-its no se filtren
   - Row Level Security (RLS) de Supabase para controlar acceso
   - Políticas de seguridad basadas en fase de sesión

2. **Identificación sin Autenticación**
   - Posibilidad de nombres duplicados (aceptable para MVP)
   - Considerar añadir avatar aleatorio para diferenciar
   - Usuarios pueden cambiar nombre accidentalmente (limitación conocida)

3. **Gestión de Sesiones Abandonadas**
   - Limpiar sesiones antiguas
   - Timeout de inactividad

## 📈 Métricas de Éxito

- Tiempo promedio de retrospectiva
- Número de post-its por sesión
- Satisfacción de usuarios (encuesta post-retro)
- Tasa de adopción en equipos
- Bugs reportados vs resueltos

## 🚀 Plan de Implementación Recomendado

### Semana 1-2: Configuración y Setup Inicial

- Setup del proyecto Next.js 16 con App Router
- Configuración de TypeScript + TailwindCSS + Base UI
- Configuración de Supabase (PostgreSQL + Realtime)
- Estructura DDD completa
- Setup de Vercel para deployment
- Implementar acceso simple con nombre
- Diseño de UI básica

### Semana 3-4: Funcionalidad Core

- **Objetos Madre**: Crear Mothers para todas las entidades
- **Entidades de dominio**: RetroSession, PostIt, SessionUser con métodos semánticos
- **Value Objects**: SessionCode, PostItCategory, SessionPhase, Position
- **Repositorios**: Interfaces en domain, implementaciones Supabase en infrastructure
- **Use Cases**: CreateSession, JoinSession, CreatePostIt con transformación primitivos→dominio
- **Pruebas unitarias**: Modelos y Use Cases con mocks
- **Pruebas de integración**: Use Cases con Supabase real
- **UI**: Crear/unirse a sesiones, CRUD de post-its, 4 zonas de categorías
- **Drag & drop básico**

### Semana 5-6: Tiempo Real y Fases

- Implementar servicios de dominio (PhaseTransitionService)
- Use cases de control de fases
- Sincronización Supabase Realtime
- Control de fases (privada/colaborativa)
- Sistema de "terminado"
- Panel de moderador
- Aplicar Row Level Security (RLS) en Supabase

### Semana 7: Testing y Pulido

- Testing con usuarios reales
- Corrección de bugs
- Optimización de rendimiento
- Deploy a producción

## 📚 Recursos Necesarios

### Desarrollo

- 1 Frontend Developer (Next.js/TypeScript)
- Tiempo estimado MVP: 6-8 semanas (incluye arquitectura DDD + testing exhaustivo)
- Conocimientos:
  - Next.js 16, App Router
  - Supabase (PostgreSQL, Realtime, RLS)
  - TailwindCSS, Base UI
  - Arquitectura DDD y principios SOLID
  - TypeScript avanzado
  - Testing (Vitest, patrones de Mothers)
  - Vercel

### Diseño

- Wireframes y mockups de UI
- Sistema de diseño básico
- Iconografía (Lucide React)

### Infraestructura

- Cuenta Supabase (free tier suficiente para empezar)
- Cuenta Vercel (free tier, ideal para Next.js)
- Dominio (opcional)
- Hosting: Vercel (optimizado para Next.js)

---

## 💭 Notas Adicionales

### Alternativas Consideradas

- **Backend propio**: Descartado por requisito de no mantener backend
- **WebSockets puros**: Más complejo que usar BaaS con realtime
- **LocalStorage + P2P**: No confiable para múltiples usuarios

### Futuras Expansiones

- Integración con Jira/Linear para action items
- Retrospectivas asíncronas (sin tiempo real)
- Analytics de retrospectivas
- Plantillas personalizables
- Modo oscuro
- Internacionalización (i18n)
