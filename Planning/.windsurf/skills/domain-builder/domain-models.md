# Modelos de Dominio

## Descripción General

Los modelos de dominio representan los conceptos y reglas de negocio principales. Son clases TypeScript puras sin dependencias externas, enfocándose en la lógica de negocio e inmutabilidad.

## Principios Principales

### 1. SIN Getters/Setters - Usar Métodos Semánticos

**❌ Malo:**

```typescript
class User {
  private constructor(
    private readonly name: FullName,
    private readonly email: Email
  ) {}

  getName(): string {
    return this.name
  }
  setName(name: string) {
    this.name = name
  } // ❌ Mutation!
  getEmail(): string {
    return this.email
  }
}
```

**✅ Bueno:**

```typescript
class User {
  private constructor(
    private readonly name: FullName,
    private readonly email: Email
  ) {}

  fullName(): string {
    return this.name.value()
  }
  emailAddress(): string {
    return this.email.value()
  }
  canLogin(): boolean {
    return this.isActive() && this.hasVerifiedEmail()
  }
}
```

### 2. Métodos de Fábrica con Validación Zod

**OBLIGATORIO:** Todos los modelos deben tener un `static create()` que valida con Zod:

```typescript
import { z } from 'zod'

// Ejemplo con primitivos
const EntityValidation = z.object({
  value: z.string().min(1, '[Entity] Value is required'),
  count: z.number().positive('[Entity] Count must be positive'),
})

// Ejemplo con agregados (otros modelos de dominio)
const BookingValidation = z.object({
  // Primitivos
  id: z.string().uuid('[Booking] Invalid booking ID format'),
  // Agregados: usa z.instanceof() para validar que sea una instancia del modelo
  user: z.instanceof(User, { message: '[Booking] User must be a valid User instance' }),
  price: z.instanceof(Money, { message: '[Booking] Price must be a valid Money instance' }),
  dates: z.instanceof(DateRange, { message: '[Booking] Dates must be a valid DateRange instance' }),
})

export class Entity {
  static create({ value }: z.infer<typeof EntityValidation>): Entity {
    EntityValidation.parse({ value }) // Throws if invalid with custom messages
    return new Entity(value)
  }

  static createOrNull({ value }: z.infer<typeof EntityValidation>): Entity | null {
    try {
      return Entity.create({ value })
    } catch {
      return null
    }
  }

  static fromJSONOrNull(json?: Partial<ReturnType<Entity['toJSON']>>): Entity | null {
    if (!json?.value) return null
    return Entity.create({ value: json.value })
  }

  // Empty is allowed when it makes sense in the domain
  static empty(): Entity {
    return new Entity()
  }
}
```

**Notas importantes:**

- **Agregados:** Cuando un modelo contiene otros modelos de dominio (agregados), usa `z.instanceof(ModelClass)` para validar que sea una instancia correcta del modelo.
- **Mensajes de error:** SIEMPRE incluye mensajes de error personalizados con el formato `[ModelName] Descripción del error`. Esto facilita el debugging y proporciona contexto claro sobre qué validación falló.

**❌ Malo:**

```typescript
static create(props: Props): Entity {
  return new Entity(props || {}) // No validation!
}
```

**✅ Bueno - ValueObject simple:**

```typescript
static create({ value }: z.infer<typeof EntityValidation>): Entity {
  EntityValidation.parse({ value }) // Zod validation
  return new Entity(value)
}
```

**✅ Bueno - Agregado con múltiples propiedades:**

```typescript
const BookingValidation = z.object({
  id: z.string().uuid('[Booking] Invalid ID'),
  user: z.instanceof(User, { message: '[Booking] Invalid user' }),
  price: z.instanceof(Money, { message: '[Booking] Invalid price' }),
  dates: z.instanceof(DateRange, { message: '[Booking] Invalid dates' }),
})

static create({ id, user, price, dates }: z.infer<typeof BookingValidation>): Booking {
  BookingValidation.parse({ id, user, price, dates }) // Valida todos los campos
  return new Booking(id, user, price, dates)
}
```

### 3. Inmutabilidad y Constructor Privado

El constructor debe ser privado y recibir los parámetros como argumentos separados (no como objeto):

**Importante sobre tipos JSON:**

- NO crear tipos `{Entity}JSON` manualmente
- Usar `ReturnType<{Entity}['toJSON']>` en `fromJSON` para inferir el tipo automáticamente
- El método `toJSON()` no necesita tipo de retorno explícito - TypeScript lo infiere

```typescript
export class User {
  private constructor(
    private readonly id: ID,
    private readonly name: Name,
    private readonly email: Email
  ) {}

  static createOrNull(id: ID, name: Name, email: Email): User | null {
    // Validation logic
    if (!id.isValid()) return null
    if (!name.isValid()) return null

    return new User(id, name, email)
  }

  static fromJSON(json: ReturnType<User['toJSON']>): User {
    return new User(ID.fromJSON(json.id), Name.fromJSON(json.name), Email.fromJSON(json.email))
  }
}
```

**Importante:** NO crear un tipo `Props` - pasar los argumentos directamente al constructor separados por comas.

## Estructura del Modelo de Entidad

### Plantilla Completa

```typescript
// src/{context}/domain/{Entity}.ts

export class {Entity} {
  // Private constructor - argumentos separados por coma
  private constructor(
    private readonly field1: Field1Type,
    private readonly field2: Field2Type,
    private readonly nested: NestedType
  ) {}

  // Factory method with validation
  static createOrNull(
    field1: Field1Type,
    field2: Field2Type,
    nested: NestedType
  ): {Entity} | null {
    // Validation logic
    if (!field1.isValid()) return null
    if (field2 < 0) return null

    return new {Entity}(field1, field2, nested)
  }

  // Deserialization - usa ReturnType para inferir el tipo desde toJSON
  static fromJSON(json: ReturnType<{Entity}['toJSON']>): {Entity} {
    return new {Entity}(
      Field1Type.fromJSON(json.field1),
      json.field2,
      NestedType.fromJSON(json.nested)
    )
  }

  // Semantic methods - Express business intent
  semanticName(): string {
    return this.field1.value()
  }

  isSpecialCondition(): boolean {
    return this.field2 > 100
  }

  canPerformAction(): boolean {
    return this.isSpecialCondition() && this.nested.isActive()
  }

  calculateValue(): number {
    return this.field2 * 1.21 // Business logic
  }

  // Serialization - el tipo se infiere automáticamente
  toJSON() {
    return {
      field1: this.field1.toJSON(),
      field2: this.field2,
      nested: this.nested.toJSON(),
    }
  }

  // Nullable serialization (if needed)
  toJSONOrNull(): ReturnType<{Entity}['toJSON']> | null {
    if (!this.isValid()) return null
    return this.toJSON()
  }

  // Private validation (if needed)
  private isValid(): boolean {
    return this.field1.isValid() && this.field2 > 0
  }
}
```

## Modelos ListOf

### Cuándo Crear ListOf

- Colección de entidades de dominio
- Necesidad de operaciones de dominio en la colección
- Deseo de seguridad de tipos para colecciones

### Plantilla

```typescript
// src/{context}/domain/ListOf{Entity}.ts

import { z } from 'zod'
import type { {Entity} } from './{Entity}'

const ListOf{Entity}Validation = z.object({
  items: z.array(z.instanceof({Entity}, { message: '[ListOf{Entity}] Items must be valid {Entity} instances' })),
})

export class ListOf{Entity} {
  private constructor(private readonly items: ReadonlyArray<{Entity}>) {}

  // Factory method with validation
  static create({ items }: z.infer<typeof ListOf{Entity}Validation>): ListOf{Entity} {
    ListOf{Entity}Validation.parse({ items })
    return new ListOf{Entity}(items)
  }

  // Deserialization - usa ReturnType para inferir el tipo desde toJSON
  static fromJSON(json: ReturnType<ListOf{Entity}['toJSON']>): ListOf{Entity} {
    return new ListOf{Entity}(json.map({Entity}.fromJSON))
  }

  // Empty is ONLY allowed for ListOf
  static empty(): ListOf{Entity} {
    return new ListOf{Entity}([])
  }

  // Basic queries
  items(): ReadonlyArray<{Entity}> {
    return this.items
  }

  isEmpty(): boolean {
    return this.items.length === 0
  }

  count(): number {
    return this.items.length
  }

  // Domain-specific queries
  first(): {Entity} | null {
    return this.items[0] || null
  }

  last(): {Entity} | null {
    return this.items[this.items.length - 1] || null
  }

  // Business logic methods
  filterByCondition(predicate: (item: {Entity}) => boolean): ListOf{Entity} {
    return ListOf{Entity}.create(this.items.filter(predicate))
  }

  findById(id: ID): {Entity} | null {
    return this.items.find(item => item.hasId(id)) || null
  }

  // Serialization - el tipo se infiere automáticamente
  toJSON() {
    return this.items.map(item => item.toJSON())
  }
}
```

## Objetos de Valor (Kernel)

### Cuándo Reutilizar vs Crear Nuevo

**Reutilizar desde `_kernel` si:**

- El concepto es agnóstico del dominio (ID, Email, Money, Date)
- Ya existe y se adapta a tus necesidades
- No se requieren reglas de negocio específicas

**Crear uno nuevo si:**

- Se requiere validación específica del negocio
- Concepto específico del dominio
- Necesitas métodos adicionales únicos para tu contexto

### Objetos de Valor del Kernel Comunes

```typescript
// Available in src/_kernel/

// Identity
ID, Hash

// Text
Name, FullName, Description, Slug, Path, Title

// Contact
Email, Phone

// Monetary
Money, Price, Currency

// Temporal
Date, Nights

// Numeric
Count, PageNumber, NumberOfComments, Rating, Stars

// Location
Country, City, Nationality, GeoCoordenate, DistanceToCityCenter

// Visual
Color, Image, CTA

// Pagination
Pagination, PaginationStatus

// Lists
ListOfImage, ListOfImageBucket, ListOfStars, etc.
```

### Crear Objetos de Valor Personalizados

```typescript
// src/{context}/domain/{ValueObject}.ts

export class {ValueObject} {
  private constructor(private readonly _value: string | number) {}

  static createOrNull(value: string | number): {ValueObject} | null {
    // Validation
    if (!isValid(value)) return null
    return new {ValueObject}(value)
  }

  // Deserialization - usa ReturnType para inferir el tipo desde toJSON
  static fromJSON(json: ReturnType<{ValueObject}['toJSON']>): {ValueObject} {
    return new {ValueObject}(json)
  }

  // Semantic methods
  value(): string | number {
    return this._value
  }

  isValid(): boolean {
    // Business validation
    return this._value.toString().length > 0
  }

  // Domain operations
  equals(other: {ValueObject}): boolean {
    return this._value === other._value
  }

  // Serialization - el tipo se infiere automáticamente (string | number)
  toJSON() {
    return this._value
  }
}
```

## Análisis de Modelos Existentes

### Paso 1: Revisar Kernel (`src/_kernel/`)

```bash
# Busca conceptos similares
Email, Phone, Name, FullName
Money, Price, Currency
ID, Hash
Date, Nights
Rating, Stars
```

### Paso 2: Revisar Compartido (`src/shared/domain/`)

```bash
# Busca modelos entre contextos
Language, Locale, Market
Location, LocationType
Device, Platform, OperatingSystem
Affiliate, AffiliateSource
FeatureFlag
```

### Paso 3: Revisar Modelos del Contexto

```bash
# Busca dentro del contexto específico
src/{context}/domain/
```

### Matriz de Decisiones

| Si el modelo...                      | Acción                                           |
| ------------------------------------ | ------------------------------------------------ |
| Existe exactamente como se necesita  | ✅ Reutilizar directamente                       |
| Existe pero necesita cambios leves   | ✅ Reutilizar, no modificar                      |
| No existe pero es genérico           | ✅ Verificar si debe estar en kernel             |
| No existe, es específico del dominio | ✅ Crear en el contexto                          |
| Existe pero necesita extensión       | ⚠️ Extender con cuidado, mantener compatibilidad |

## Extender Modelos Existentes

### Reglas

1. **Nunca romper contratos existentes**
2. **Añadir, no modificar**
3. **Mantener compatibilidad hacia atrás**
4. **Considerar crear un nuevo modelo en su lugar**

### Patrón de Extensión Segura

**❌ Malo - Cambio disruptivo:**

```typescript
// Existing
class User {
  private constructor(private readonly email: Email) {}

  email(): Email {
    return this.email
  }
}

// Breaking extension
class User {
  email(): string {
    return this.email.value()
  } // ❌ Changed return type
}
```

**✅ Bueno - Cambio aditivo:**

```typescript
// Existing
class User {
  private constructor(
    private readonly email: Email,
    private readonly verified: boolean
  ) {}

  email(): Email {
    return this.email
  }
}

// Safe extension
class User {
  email(): Email {
    return this.email
  } // ✅ Unchanged
  emailAddress(): string {
    return this.email.value()
  } // ✅ New method
  hasVerifiedEmail(): boolean {
    return this.verified
  } // ✅ New method
}
```

## Patrones de Validación

### Patrón createOrNull

```typescript
static createOrNull(
  id: ID,
  amount: number,
  date: Date,
  type: string
): Entity | null {
  // Validation with early returns
  if (!id.isValid()) return null
  if (amount < 0) return null
  if (!date.isFuture()) return null

  // Additional business rules
  if (type === 'premium' && amount < 100) return null

  return new Entity(id, amount, date, type)
}
```

### Métodos de Validación de Negocio

```typescript
class Booking {
  private constructor(
    private readonly checkInDate: Date,
    private readonly checkOutDate: Date,
    private readonly discount: Discount | null
  ) {}

  canBeCancelled(): boolean {
    const now = Date.now()
    const hoursDiff = (this.checkInDate.timestamp() - now) / (1000 * 60 * 60)
    return hoursDiff > 24 // 24h cancellation policy
  }

  isExpired(): boolean {
    return this.checkOutDate.isPast()
  }

  hasDiscount(): boolean {
    return this.discount !== null && this.discount.isPositive()
  }
}
```

## Lógica de Dominio Compleja

### Composición sobre Herencia

**❌ Malo:**

```typescript
class BaseProperty {}
class Hotel extends BaseProperty {}
class Apartment extends BaseProperty {}
```

**✅ Bueno:**

```typescript
class Property {
  private constructor(
    private readonly type: PropertyType,
    private readonly services: Services
  ) {}

  isHotel(): boolean {
    return this.type.equals('HOTEL')
  }

  isApartment(): boolean {
    return this.type.equals('APARTMENT')
  }

  availableServices(): Services {
    if (this.isHotel()) {
      return this.services.hotelServices()
    }
    return this.services.apartmentServices()
  }
}
```

### Reglas de Negocio en Dominio

```typescript
class Price {
  private constructor(
    private readonly amount: number,
    private readonly currency: Currency
  ) {}

  applyDiscount(percentage: number): Price {
    if (percentage < 0 || percentage > 100) {
      throw DomainError.withCodes(ErrorsCode.INVALID_DISCOUNT_PERCENTAGE)
    }

    const discountAmount = this.amount * (percentage / 100)
    const newAmount = this.amount - discountAmount

    return Price.createOrNull(newAmount, this.currency)!
  }

  isHigherThan(other: Price): boolean {
    if (!this.currency.equals(other.currency)) {
      throw DomainError.withCodes(ErrorsCode.CURRENCY_MISMATCH)
    }
    return this.amount > other.amount
  }
}
```

## Manejo de Errores en Dominio

Usar `DomainError.withCodes()` desde kernel:

```typescript
import { DomainError } from '../../_kernel/DomainError'
import { ErrorsCode } from '../../_kernel/ErrorsCode'

class Booking {
  private constructor(
    private readonly id: ID,
    private readonly status: BookingStatus
  ) {}

  static createOrNull(id: ID, status: BookingStatus): Booking | null {
    // Validation - return null for invalid data
    if (!id.isValid()) return null

    return new Booking(id, status)
  }

  cancel(): Booking {
    // Business rule violation - throw DomainError
    if (!this.canBeCancelled()) {
      throw DomainError.withCodes(ErrorsCode.BOOKING_CANNOT_BE_CANCELLED)
    }

    // Return new instance with cancelled status (immutability)
    return new Booking(this.id, BookingStatus.CANCELLED)
  }
}
```

**Patrón de DomainError:**

```typescript
// Error simple
throw DomainError.withCodes(ErrorsCode.SOME_ERROR_CODE)

// Error con causa (cuando wrappeas otro error)
try {
  await someOperation()
} catch (err) {
  throw DomainError.withCodes(ErrorsCode.OPERATION_FAILED).withCauses(err)
}
```

**Reglas:**

- Usar `DomainError.withCodes(ErrorsCode.XXX)` - NO `new DomainError({ ... })`
- Los códigos de error deben estar definidos en `ErrorsCode` del kernel
- Usar `.withCauses(err)` cuando necesites incluir el error original
- NO incluir mensajes hardcodeados - el código de error debe ser suficiente

## Ejemplos de la Base de Código

### Entidad Simple (desde auth)

```typescript
export class User {
  private constructor(
    private readonly id: ID,
    private readonly name: FullName,
    private readonly email: Email
  ) {}

  static fromJSON(json: ReturnType<User['toJSON']>): User {
    return new User(ID.fromJSON(json.id), FullName.fromJSON(json.name), Email.fromJSON(json.email))
  }

  fullName(): string {
    return this.name.value()
  }

  emailAddress(): string {
    return this.email.value()
  }

  toJSON() {
    return {
      id: this.id.toJSON(),
      name: this.name.toJSON(),
      email: this.email.toJSON(),
    }
  }
}
```

### Entidad Compleja (desde booking)

```typescript
export class Booking {
  private constructor(
    private readonly id: ID,
    private readonly rooms: ListOfRoom,
    private readonly checkIn: Date,
    private readonly checkOut: Date,
    private readonly status: BookingStatus
  ) {}

  static createOrNull(
    id: ID,
    rooms: ListOfRoom,
    checkIn: Date,
    checkOut: Date,
    status: BookingStatus
  ): Booking | null {
    if (!id.isValid()) return null
    if (rooms.isEmpty()) return null
    if (checkIn.isAfter(checkOut)) return null
    return new Booking(id, rooms, checkIn, checkOut, status)
  }

  canBeCancelled(): boolean {
    return !this.isExpired() && this.status.canTransitionTo('CANCELLED')
  }

  totalAmount(): Money {
    return this.rooms.items().reduce((sum, room) => sum.add(room.price()), Money.zero())
  }

  nightsCount(): number {
    return this.checkOut.diffInDays(this.checkIn)
  }
}
```

## Lista de Verificación

Antes de terminar un modelo de dominio:

- [ ] Constructor privado
- [ ] Método de fábrica (createOrNull o fromJSON)
- [ ] Métodos semánticos (SIN getters/setters)
- [ ] Patrón null usado correctamente
- [ ] Todos los props readonly
- [ ] Clase inmutable
- [ ] Método toJSON()
- [ ] Método toJSONOrNull() si es anulable
- [ ] Validación de negocio en su lugar
- [ ] Modelos kernel/compartidos reutilizados
- [ ] Sin cambios disruptivos a modelos existentes
- [ ] ListOf usa empty() correctamente

---

**Siguientes Pasos:**

- ¿Implementar casos de uso? → Lee [Casos de Uso](use-cases.md)
- ¿Crear repositorios? → Lee [Repositorios](repositories.md)
- ¿Escribir pruebas? → Lee [Estrategia de Pruebas](testing-strategy.md)
