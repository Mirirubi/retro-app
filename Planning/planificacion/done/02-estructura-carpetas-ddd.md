# Fase 2 — Estructura de Carpetas DDD

## 🎯 Objetivo

Implementar la estructura base de carpetas del proyecto para soportar la arquitectura DDD definida en `ESPECIFICACIONES.md`, manteniendo separación de capas y consistencia con Next.js App Router.

---

## 📌 Referencias

- Fuente de fase: `PLANIFICACION_BOILERPLATE.md` (Fase 2)
- Alineación arquitectónica: `ESPECIFICACIONES.md` (sección de estructura de capas y árbol de carpetas)

---

## ✅ Alcance de la Fase 2

### 2.1 Contexto `retro`

Crear la base del bounded context principal:

```bash
mkdir -p src/retro/domain
mkdir -p src/retro/application
mkdir -p src/retro/infrastructure/schemas
```

**Propósito**
- `domain/`: entidades, agregados, interfaces de repositorio.
- `application/`: casos de uso.
- `infrastructure/schemas/`: validación y mapeo de persistencia.

---

### 2.2 Módulo `shared`

Crear elementos compartidos entre contextos:

```bash
mkdir -p src/shared/domain
mkdir -p src/shared/infrastructure/supabase
mkdir -p src/shared/infrastructure/realtime
```

**Propósito**
- `shared/domain/`: value objects compartidos (`SessionCode`, `PostItCategory`, etc.).
- `shared/infrastructure/supabase/`: cliente y tipos de Supabase.
- `shared/infrastructure/realtime/`: servicios de suscripción en tiempo real.

---

### 2.3 Módulo `kernel`

Crear primitives reutilizables para todo el dominio:

```bash
mkdir -p src/kernel
```

**Propósito**
- Contener objetos base de alto valor reutilizable (`Id`, `Timestamp`, `NonEmptyString`).

---

### 2.4 Estructura de testing

Crear base de pruebas por tipo y propósito:

```bash
mkdir -p test/domain/retro/models
mkdir -p test/domain/retro/units
mkdir -p test/domain/retro/integrations
mkdir -p test/mothers/retro
```

**Propósito**
- `models/`: pruebas unitarias de entidades y value objects.
- `units/`: pruebas de casos de uso con mocks.
- `integrations/`: pruebas con repositorios reales.
- `mothers/`: builders de datos de prueba semánticos.

---

### 2.5 App Router (presentación)

Mantener `app/` de Next.js y crear subestructura de UI:

```bash
mkdir -p 'app/session/[code]'
mkdir -p app/components/session
mkdir -p app/components/postit
mkdir -p app/components/shared
mkdir -p app/hooks
```

**Propósito**
- Organizar presentación por dominio funcional sin romper convenciones de App Router.

---

## 🧭 Estructura esperada al finalizar

```text
src/
├── retro/
│   ├── domain/
│   ├── application/
│   └── infrastructure/
│       └── schemas/
├── shared/
│   ├── domain/
│   └── infrastructure/
│       ├── supabase/
│       └── realtime/
└── kernel/

app/
├── session/
│   └── [code]/
├── components/
│   ├── session/
│   ├── postit/
│   └── shared/
└── hooks/

test/
├── domain/
│   └── retro/
│       ├── models/
│       ├── units/
│       └── integrations/
└── mothers/
    └── retro/
```

---

## 🔍 Checklist de validación

- [x] Existen carpetas `domain`, `application`, `infrastructure/schemas` en `src/retro`.
- [x] Existen carpetas compartidas en `src/shared` para `domain`, `supabase` y `realtime`.
- [x] Existe carpeta `src/kernel` para primitives reutilizables.
- [x] Existen carpetas de test separadas por `models`, `units`, `integrations` y `mothers`.
- [x] Estructura `app/` mantiene App Router y separa componentes por responsabilidad.
- [x] La estructura creada coincide con la arquitectura descrita en `ESPECIFICACIONES.md`.

---

## 🚦 Criterio de completitud de Fase 2

La fase se considera completada cuando:

1. Todas las carpetas del alcance existen físicamente en el repositorio.
2. La estructura respeta capas DDD (dominio, aplicación, infraestructura, presentación).
3. Queda lista para iniciar Fase 3 (Supabase) y Fase 4 (objetos kernel).
