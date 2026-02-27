---
name: domain-builder
description: Crear Casos de Uso completos siguiendo los principios de Arquitectura Limpia y Diseño Guiado por Dominio (DDD) en el dominio StayforLong. Usa esta skill cuando el usuario solicite crear o implementar casos de uso, modelos de dominio, repositorios o lógica de negocio. Guía la creación de entidades de dominio, casos de uso de capa de aplicación, repositorios de infraestructura y pruebas exhaustivas siguiendo métodos semánticos, patrones de seguridad nula y principios de reutilización primero.
---

# Skill Creador de Casos de Uso

## Descripción General

Esta skill guía a Claude Code en la creación de Casos de Uso completos en el dominio StayforLong siguiendo los principios de **Arquitectura Limpia** y **Diseño Guiado por Dominio (DDD)**.

### Qué Construirás

Una implementación completa de Caso de Uso incluye:

- **Capa de Dominio**: Modelos, objetos de valor, interfaces de repositorio
- **Capa de Aplicación**: Implementación de Caso de Uso con lógica de negocio
- **Capa de Infraestructura**: Implementaciones de repositorio con adaptadores externos
- **Capa de Pruebas**: Objetos Madre, pruebas unitarias e integración

### Filosofía Central

- **Métodos semánticos sobre getters/setters**: Expresa claramente la intención del negocio
- **Seguridad nula**: Usa patrones `createOrNull` y `toJSONOrNull`
- **Reutilización primero**: Verifica modelos de kernel, compartidos y contexto antes de crear nuevos
- **Guiado por pruebas**: Todo modelo y caso de uso debe tener pruebas exhaustivas
- **Compatibilidad hacia atrás**: Nunca rompas contratos existentes al extender modelos

### Capas de Arquitectura

```
src/{contexto}/
├── application/          # Casos de Uso (orquestación de lógica de negocio)
├── domain/              # Modelos, objetos de valor, interfaces de repositorio
└── infrastructure/      # Implementaciones de repositorio, adaptadores externos

test/
├── domain/{contexto}/
│   ├── models/         # Pruebas unitarias de modelos
│   ├── units/          # Pruebas unitarias de casos de uso (dependencias simuladas)
│   └── integrations/   # Pruebas de integración de casos de uso (dominio real)
└── mothers/{contexto}/   # Fábricas de datos de prueba (Objetos Madre)
```

## Índice de Documentación

### 📋 Proceso de Desarrollo

1. **[Convenciones de Nombres](naming-conventions.md)** - Comienza aquí para entender los patrones de nombres
2. **[Modelos de Dominio](domain-models.md)** - Aprende a crear y estructurar modelos de dominio
3. **[Casos de Uso](use-cases.md)** - Implementa casos de uso de capa de aplicación
4. **[Repositorios](repositories.md)** - Crea adaptadores de infraestructura
5. **[Estrategia de Pruebas](testing-strategy.md)** - Escribe pruebas exhaustivas
6. **[Checklist de Calidad](quality-checklist.md)** - Verifica tu implementación

### 📚 Guías de Referencia

- **[Patrones Comunes](common-patterns.md)** - Patrones reutilizables y objetos de valor

## Flujo de Trabajo de Desarrollo

### Fase 1: Descubrimiento y Planificación

**Objetivo**: Recopilar requisitos y analizar código existente. Para esta fase puedes usa AskUserQuestionTool.

1. Pregunta sobre contexto, entidad y acción
2. Identifica dependencias (repositorios, otros casos de uso)
3. Analiza modelos existentes (kernel, compartidos, contexto)
4. Presenta plan de implementación
5. Espera confirmación del usuario

**Lee**: [Convenciones de Nombres](naming-conventions.md), [Patrones Comunes](common-patterns.md)

### Fase 2: Capa de Dominio

**Objetivo**: Crear o extender modelos de dominio

1. Crear/extender modelos de entidad con métodos semánticos
2. Crear modelos ListOf si es necesario
3. Definir interfaces de repositorio
4. Garantizar compatibilidad hacia atrás

**Lee**: [Modelos de Dominio](domain-models.md)
**Lee**: [Repositorios](repositories.md)

### Fase 3: Capa de Aplicación

**Objetivo**: Implementar orquestación de lógica de negocio

1. Crear clase de Caso de Uso
2. Agregar decorador de caché si es necesario
3. Implementar método execute()

**Lee**: [Casos de Uso](use-cases.md)

### Fase 4: Capa de Infraestructura

**Objetivo**: Conectarse a sistemas externos

1. Crear implementación de repositorio
2. Definir esquemas Zod para validación de datos. Solo para HTTP Repositorios.
3. Usar adaptadores específicos para cada infraestructura.

**Lee**: [Repositorios](repositories.md)

### Fase 5: Capa de Pruebas

**Objetivo**: Garantizar calidad mediante pruebas exhaustivas

1. Crear Objetos Madre para datos de prueba
2. Escribir pruebas unitarias de modelos
3. Escribir pruebas unitarias de casos de uso (simuladas)
4. Escribir pruebas de integración (repositorio real)

**Lee**: [Estrategia de Pruebas](testing-strategy.md)

### Fase 6: Registro y Verificación de Calidad

**Objetivo**: Registrar el caso de uso en el entry point y garantizar que el código cumpla con todos los estándares

1. Registrar el getter del caso de uso en `src/index.ts` (clase `StayForLong`)
2. Añadir el nombre del getter al array `expectedGetters` en `test/domain/StayForLong.test.ts`
3. Revisar el checklist de calidad

**Lee**: [Estrategia de Pruebas > StayForLong Registration](testing-strategy.md)
**Lee**: [Checklist de Calidad](quality-checklist.md)

### Cuándo Leer Cada Guía

- **¿Comenzando un nuevo caso de uso?** → Lee [Convenciones de Nombres](naming-conventions.md) primero
- **¿Creando un modelo?** → Lee [Modelos de Dominio](domain-models.md)
- **¿Necesitas un repositorio?** → Lee [Repositorios](repositories.md)
- **¿Escribiendo pruebas?** → Lee [Estrategia de Pruebas](testing-strategy.md)
- **¿No estás seguro qué reutilizar?** → Consulta [Patrones Comunes](common-patterns.md)
- **¿Revisión final?** → Usa [Checklist de Calidad](quality-checklist.md)

## Sesión de Ejemplo

```
Usuario: "Crear un Caso de Uso para obtener preferencias del usuario"

Claude Code:
📋 Fase de Descubrimiento
1. Contexto: auth
2. Entidad: UserPreferences
3. Acción: Get
4. Repositorio: HTTP
5. Caché: Sí
6. Dependencias: GetCurrentUserUseCase

📊 Análisis
✓ El modelo User existe en auth/domain/User.ts
? ¿Deberíamos extender User o crear UserPreferences?
✓ Verificando kernel para objetos de valor reutilizables...

📝 Plan de Implementación
[Presenta plan detallado con todos los archivos a crear]

¿Proceder? (s/n)
```

## Recordatorios Importantes

1. **Siempre analiza el código existente** antes de crear nuevos modelos
2. **Los eventos de dominio son automáticos** - no se necesita código especial
3. **Los comentarios de cobertura de caché** usan `/* v8 ignore start -- @preserve */`
4. **La compatibilidad de plataforma importa** - prueba para node/window si es necesario
5. **Los objetos madre son obligatorios** - son tu base de pruebas
6. **Los repositorios SIEMPRE reciben objetos de dominio** - nunca primitivos. El UseCase transforma primitivos a dominio en `execute()`
7. **Registra cada nuevo caso de uso** en `src/index.ts` y en `expectedGetters` de `test/domain/StayForLong.test.ts`

---

¿Listo para comenzar? Empieza con [Convenciones de Nombres](naming-conventions.md) para entender los patrones, luego sigue las fases de flujo de trabajo anteriores.
