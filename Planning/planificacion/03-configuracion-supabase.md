# Fase 3 — Configuración de Supabase

⏱️ **Tiempo estimado**: 1 día

---

## 🎯 Objetivo

Configurar Supabase como infraestructura de persistencia y tiempo real para el MVP de retrospectivas, asegurando seguridad por participante (RLS), soporte de fases (`private` y `collaborative`) y base técnica para sincronización en vivo.

---

## 📌 Referencias

- Fuente de fase: `PLANIFICACION_BOILERPLATE.md` (Fase 3)
- Alineación funcional: `ESPECIFICACIONES.md` (fase privada y colaborativa)

---

## ✅ Alcance de la Fase 3

### 3.1 Setup de proyecto Supabase

- [ ] Crear proyecto en Supabase Dashboard.
- [ ] Obtener credenciales del proyecto:
  - `NEXT_PUBLIC_SUPABASE_URL`
  - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- [ ] Crear archivo `.env.local` en la raíz del proyecto:

```env
NEXT_PUBLIC_SUPABASE_URL=your-project-url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

- [ ] Verificar que `.env.local` no se versiona (gitignore).

---

### 3.2 Crear cliente de Supabase

- [ ] Implementar cliente en `src/shared/infrastructure/supabase/client.ts` para:
  - Server Components.
  - Client Components.
  - Reutilización tipada en toda la app.

**Resultado esperado**
- Una única entrada de infraestructura para inicializar Supabase con API coherente según entorno (server/client).

---

### 3.3 Diseñar schema de base de datos

- [ ] Crear archivo `supabase/schema.sql` con tablas:
  - `retro_sessions` (`id`, `code`, `moderator_id`, `phase`, `created_at`)
  - `session_users` (`id`, `session_id`, `user_name`, `is_completed`, `is_moderator`, `joined_at`)
  - `postits` (`id`, `session_id`, `user_id`, `user_name`, `category`, `text`, `position_x`, `position_y`, `group_id`, `created_at`, `updated_at`)
- [ ] Definir claves primarias, foráneas e índices mínimos de consulta por `session_id`.

**Resultado esperado**
- Modelo relacional preparado para soportar:
  1. Estado de sesión por código.
  2. Participantes por sesión.
  3. Post-its con posicionamiento y agrupación.

---

### 3.4 Configurar Row Level Security (RLS)

- [ ] Activar RLS en tablas con datos sensibles.
- [ ] Crear políticas para privacidad en fase privada:
  - En fase `private`, cada usuario solo ve sus post-its.
  - En fase `collaborative`, todos los usuarios de la sesión ven todos los post-its.
  - Las sesiones solo son visibles para participantes de la misma sesión.

**Resultado esperado**
- Seguridad de acceso alineada con reglas de negocio de retrospectiva.

---

### 3.5 Habilitar Realtime

- [ ] Activar Realtime en tablas necesarias (mínimo `postits` y estado de sesión).
- [ ] Configurar publicaciones/eventos para reflejar cambios en tiempo real.

**Resultado esperado**
- Cambios de post-its y fase reflejados en clientes conectados sin recarga manual.

---

## 🧭 Entregables de la fase

Al finalizar esta fase deben existir:

1. Configuración local de credenciales (`.env.local`) funcionando.
2. Cliente Supabase reutilizable en `src/shared/infrastructure/supabase/client.ts`.
3. Script base de esquema en `supabase/schema.sql`.
4. Políticas RLS activas y validadas.
5. Realtime habilitado en tablas clave.

---

## 🔍 Checklist de validación

- [ ] La app puede inicializar cliente Supabase sin errores de entorno.
- [ ] Las tablas `retro_sessions`, `session_users` y `postits` existen en Supabase.
- [ ] Se pueden crear y consultar registros de prueba para una sesión.
- [ ] RLS bloquea accesos fuera de la sesión o usuario no autorizado.
- [ ] En fase `private`, un usuario no puede leer post-its ajenos.
- [ ] En fase `collaborative`, los post-its de la sesión son visibles para todos los participantes.
- [ ] Realtime notifica inserciones/actualizaciones en tablas activadas.

---

## 🚦 Criterio de completitud de Fase 3

La fase se considera completada cuando:

1. La infraestructura de Supabase está conectada y operativa desde la app.
2. El esquema de datos está aplicado y consistente con el dominio.
3. Las políticas RLS implementan correctamente privacidad y colaboración por fase.
4. La sincronización en tiempo real está habilitada en los recursos necesarios.
