# Patrones Comunes

## Overview

Esta guía documenta los patrones de diseño que se repiten en el codebase. Úsalos como referencia al implementar nuevas funcionalidades.

**Regla de oro**: Siempre busca primero en `src/_kernel/` y `src/shared/domain/` antes de crear nuevos componentes.

## Patrón: Value Object Enumerado

Value Objects que representan un conjunto cerrado de valores posibles.

### Estructura Simple

```typescript
import { z } from 'zod'
import { Model } from './architecture'

// 1. Array constante de valores (plural, UPPERCASE)
export const ACCOMMODATION_TYPES = [
  'HOTEL',
  'APARTMENT',
  'RESORT',
  // ...
] as const

// 2. Tipo derivado (singular con "Type" o plural del modelo)
export type AccommodationType = (typeof ACCOMMODATION_TYPES)[number]

// 3. Validación con z.enum usando la constante
export const AccommodationValidation = z.object({
  value: z.enum(ACCOMMODATION_TYPES, { required_error: '[Accommodation] value is required' }),
})

// 4. Clase del modelo
export class Accommodation extends Model {
  static create({ value }: z.infer<typeof AccommodationValidation>) {
    AccommodationValidation.parse({ value })
    return new Accommodation(value)
  }

  constructor(private readonly _value: AccommodationType) {
    super()
  }

  get value() { return this._value }

  toJSON() {
    return { value: this.value }
  }
}
```

### Estructura Avanzada (con estado opcional)

Para enumerados que pueden estar vacíos y requieren consultas avanzadas:

```typescript
// 1. Tipo plural del modelo
export type Markets = (typeof ALLOWED_MARKETS)[number]

// 2. Constante ALLOWED_* (desde datasource)
export const ALLOWED_MARKETS = MARKETS // de CountryDatasource

// 3. Validación
export const MarketValidation = z.object({
  value: z.enum(ALLOWED_MARKETS, { required_error: 'value is required' }),
})

export class Market extends Model {
  static create({ value }: z.infer<typeof MarketValidation>) {
    MarketValidation.parse({ value })
    return new Market(value)
  }

  static empty() {
    return new Market() // Sin valor
  }

  // Constructor con valor opcional
  constructor(private readonly _value?: Markets) {
    super()
  }

  get value() { return this._value }

  // Type guards con narrowing
  isEmpty(): this is Market & { value: undefined } {
    return !this.value
  }

  isFilled(): this is Market & z.infer<typeof MarketValidation> {
    return !!this.value
  }

  is<T extends Markets>(value: T): this is Market & { value: T } {
    return this.isFilled() && this.value === value
  }

  isOneOf<T extends Markets>(markets: readonly T[]): this is Market & { value: T } {
    return this.isFilled() && markets.includes(this.value as T)
  }

  toJSON() {
    return { value: this.value ?? null }
  }
}
```

### Uso

```typescript
// Simple
const accommodation = Accommodation.create({ value: 'HOTEL' })

// Avanzado con type guards
const market = Market.create({ value: 'es' })

if (market.is('es')) {
  // TypeScript sabe que market.value es 'es'
}

if (market.isOneOf(['es', 'fr', 'it'])) {
  // TypeScript sabe que market.value es 'es' | 'fr' | 'it'
}

const empty = Market.empty()
if (empty.isEmpty()) {
  // TypeScript sabe que empty.value es undefined
}
```

### Convenciones de nombres

- **Constante de valores**: `ACCOMMODATION_TYPES`, `ALLOWED_MARKETS` (plural, UPPERCASE)
- **Tipo**:
  - Simple: `AccommodationType` (singular + "Type")
  - Avanzado: `Markets` (plural del modelo)
- **Validación**: `z.enum(CONSTANT, ...)` - siempre usa la constante
- **Clase**: `Accommodation`, `Market` (singular)

## Patrón: Value Object Básico

Los Value Objects son objetos inmutables que representan conceptos del dominio mediante su valor.

### Estructura

```typescript
import { z } from 'zod'
import { Model } from './architecture'

// 1. Validación con Zod
export const NameValidation = z.object({
  value: z.string({ required_error: '[Name] value is required' }),
})

// 2. Clase que extiende Model
export class Name extends Model {
  // 3. Método estático create (principal)
  static create({ value }: z.infer<typeof NameValidation>) {
    NameValidation.parse({ value })
    return new Name(value)
  }

  // 4. Constructor privado
  constructor(private readonly _value: string) {
    super()
  }

  // 5. Getter inmutable
  get value() { return this._value }

  // 6. Serialización
  toJSON() {
    return { value: this.value }
  }
}
```

### Uso

```typescript
// Crear instancia
const name = Name.create({ value: 'Barcelona' })

// Acceder al valor
console.log(name.value) // 'Barcelona'

// Serializar
const json = name.toJSON() // { value: 'Barcelona' }
```

### Ubicaciones comunes

- **Identifiers**: `ID`, `Hash`, `Token`
- **Text**: `Name`, `Title`, `Description`, `Slug`, `Path`
- **Contact**: `Email`, `Phone`, `VatNumber`
- **Numeric**: `Count`, `Rating`, `Stars`, `PageNumber`
- **Location**: `City`, `Country`, `Nationality`
- **Visual**: `Color`, `Url`, `ImageCode`

## Patrón: Value Object Compuesto

Value Objects con múltiples propiedades que pueden contener otros Value Objects.

### Ejemplo: Money

```typescript
export const MoneyValidation = z.object({
  amount: z.number().nonnegative(),
  currency: z.instanceof(Currency), // Usa otro Value Object
})

export class Money extends Model {
  static create({ amount, currency }: z.infer<typeof MoneyValidation>) {
    MoneyValidation.parse({ amount, currency })
    return new Money(amount, currency)
  }

  constructor(
    private readonly _amount: number,
    private readonly _currency: Currency
  ) {
    super()
  }

  get amount() { return this._amount }
  get currency() { return this._currency.value }

  toJSON() {
    return { amount: this.amount, currency: this.currency }
  }

  // Métodos de negocio
  toFormattedString(locale: string, market: Market) {
    // Lógica de formateo...
  }
}
```

### Uso

```typescript
const money = Money.create({
  amount: 150.50,
  currency: Currency.create({ value: 'EUR' })
})

console.log(money.amount) // 150.50
console.log(money.currency) // 'EUR'
```

### Otros ejemplos

- `GeoCoordenate`: latitude + longitude
- `Pagination`: page + perPage + total
- `Image`: url + alt + metadata
- `CTA`: text + url

## Patrón: Métodos de Construcción Alternativos

Además del método `create()` principal, los Value Objects pueden ofrecer constructores especializados.

### createOrNull

Para valores opcionales que pueden no existir:

```typescript
export class Currency extends Model {
  static createOrNull({ value }: { value: Currencies | null }) {
    if (!value) return null
    return Currency.create({ value })
  }
}

// Uso
const currency = Currency.createOrNull({ value: null }) // null
const validCurrency = Currency.createOrNull({ value: 'EUR' }) // Currency
```

### fromJSON

Para deserializar objetos JSON (diferente de `create`):

```typescript
export class Money extends Model {
  static fromJSON(json: ReturnType<Money['toJSON']>) {
    return new Money(
      json.amount,
      Currency.create({ value: json.currency })
    )
  }
}

// Uso - cuando recibes datos de API/storage
const money = Money.fromJSON({ amount: 100, currency: 'EUR' })
```

### Constructores específicos de dominio

```typescript
export class Currency extends Model {
  // Crear desde Market
  static fromMarket({ market }: { market: Market }) {
    return Currency.create({ value: FROM_MARKET_TO_CURRENCY[market.value] })
  }

  // Valor por defecto
  static empty() {
    return new Currency('USD')
  }
}

// Uso
const currency = Currency.fromMarket({ market: Market.ES }) // EUR
const defaultCurrency = Currency.empty() // USD
```

### Otros métodos comunes

- `fromNumber()` en ID
- `now()` en Date
- `generate()` para IDs únicos

## Patrón: ListOf

Colecciones tipadas con métodos de consulta.

### Estructura básica

```typescript
export class ListOfEntity extends Model {
  static create(items: ReadonlyArray<Entity>) {
    return new ListOfEntity(items)
  }

  constructor(private readonly items: ReadonlyArray<Entity>) {
    super()
  }

  // Consultas básicas
  items(): ReadonlyArray<Entity> { return this.items }
  isEmpty(): boolean { return this.items.length === 0 }
  count(): number { return this.items.length }
  first(): Entity | null { return this.items[0] || null }
  last(): Entity | null { return this.items[this.items.length - 1] || null }

  // Búsqueda
  findById(id: ID): Entity | null {
    return this.items.find(item => item.id().equals(id)) || null
  }

  // Filtrado
  filterByStatus(status: Status): ListOfEntity {
    return ListOfEntity.create(
      this.items.filter(item => item.hasStatus(status))
    )
  }

  // Transformación
  map<T>(fn: (item: Entity) => T): T[] {
    return this.items.map(fn)
  }

  toJSON() {
    return this.items.map(item => item.toJSON())
  }
}
```

### Ubicaciones

- `ListOfImage`, `ListOfImageBucket`
- `ListOfID`, `ListOfPaginatedID`
- `ListOfRating`, `ListOfStars`
- `ListOfTitle`, `ListOfI18nText`
- `ListOfAccommodation`, `ListOfUrl`

## Patrón: Error Handling

### DomainError con .withCodes()

Usar `DomainError.withCodes()` desde kernel - NO `new DomainError({ ... })`:

```typescript
import { DomainError } from '../../_kernel/DomainError'
import { ErrorsCode } from '../../_kernel/ErrorsCode'

// Error simple - solo código
throw DomainError.withCodes(ErrorsCode.BOOKING_CANNOT_BE_CANCELLED)

// Error con causa original
try {
  await someOperation()
} catch (err) {
  throw DomainError.withCodes(ErrorsCode.OPERATION_FAILED).withCauses(err)
}
```

### Uso en métodos de dominio

```typescript
class Booking {
  cancel(): Booking {
    // Validar regla de negocio
    if (!this.canBeCancelled()) {
      throw DomainError.withCodes(ErrorsCode.BOOKING_CANNOT_BE_CANCELLED)
    }

    return new Booking(this.id, BookingStatus.CANCELLED)
  }
}

class Price {
  applyDiscount(percentage: number): Price {
    if (percentage < 0 || percentage > 100) {
      throw DomainError.withCodes(ErrorsCode.INVALID_DISCOUNT_PERCENTAGE)
    }

    const newAmount = this.amount * (1 - percentage / 100)
    return Price.create({ amount: newAmount, currency: this.currency })
  }
}
```

### Reglas

- ✅ Usar `DomainError.withCodes(ErrorsCode.XXX)`
- ✅ Los códigos deben estar en `ErrorsCode` del kernel
- ✅ Usar `.withCauses(err)` para incluir el error original
- ❌ NO usar `new DomainError({ message, code })`
- ❌ NO incluir mensajes hardcodeados - el código es suficiente

## Patrón: Repository con Zod

### Estructura

```typescript
// schemas/endpoint.ts
import { z } from 'zod'

export const responseSchema = z.object({
  id: z.string(),
  name: z.string(),
  amount: z.number(),
})

export type ResponseSchema = z.infer<typeof responseSchema>

// Repository.ts
import { responseSchema } from './HTTPRepository/schemas/endpoint'

export class HTTPRepository implements Repository {
  async getData(): Promise<Data> {
    const response = await this.props.fetcher.get('/api/data')
    const parsed = responseSchema.parse(response) // Validación
    return Data.create(parsed) // Mapeo a dominio
  }
}
```

## Patrón: Cache con Decorator

```typescript
import { UseCaseCache } from '@s4l/cache'

type Props = {
  readonly repository: Repository
  readonly getCurrentMarket: GetCurrentMarketSharedUseCase
  readonly getCurrentLanguage: GetCurrentLanguageSharedUseCase
}

@UseCaseCache
export class GetDataUseCase {
  constructor(private readonly props: Props) {}

  /* v8 ignore start -- @preserve */
  async asides() {
    // Dependencias para la cache key
    const [market, language] = await Promise.all([
      this.props.getCurrentMarket.execute(),
      this.props.getCurrentLanguage.execute(),
    ])
    return { market, language }
  }
  /* v8 ignore stop -- @preserve */

  async execute(): Promise<Data> {
    return this.props.repository.getData()
  }
}
```

**Importante**: Usa siempre los comentarios exactos `/* v8 ignore start -- @preserve */` y `/* v8 ignore stop -- @preserve */` para excluir `asides()` de coverage.

## Patrón: Repository Proxy

Para fallback entre múltiples fuentes de datos:

```typescript
type Props = {
  readonly primary: Repository
  readonly secondary: Repository
  readonly fallback: Repository
}

export class RepositoryProxy implements Repository {
  constructor(private readonly props: Props) {}

  async getData(): Promise<Data | null> {
    // Intenta primary
    const fromPrimary = await this.props.primary.getData()
    if (fromPrimary) return fromPrimary

    // Intenta secondary
    const fromSecondary = await this.props.secondary.getData()
    if (fromSecondary) return fromSecondary

    // Fallback
    return this.props.fallback.getData()
  }
}
```

## Patrón: Factory

Para crear instancias específicas según el contexto:

```typescript
export class FactoryCookie {
  static create(): Cookie {
    if (typeof window !== 'undefined') {
      return new WindowCookie()
    }
    return new NodeCookie()
  }
}

// Uso
const cookie = FactoryCookie.create()
```

## Shared Domain Models

Modelos compartidos entre contextos en `src/shared/domain/`:

- **Market**: Mercados geográficos (ES, UK, DE, etc.)
- **Language**: Códigos de idioma (es, en, de, etc.)
- **Locale**: Idioma + región (es-ES, en-GB, etc.)
- **Location**: Ubicaciones de búsqueda (ciudad, país, POI)
- **Device**: Información del dispositivo
- **Platform**: WEB, MOBILE, APP
- **Pax**: Número de huéspedes (adultos, niños, bebés)
- **Affiliate**, **Source**: Tracking de tráfico
- **FeatureFlag**: Sistema de feature toggles

## Checklist de Implementación

Antes de crear un nuevo componente:

1. ✅ ¿Existe un Value Object en `_kernel/` que puedas usar?
2. ✅ ¿Existe un modelo compartido en `shared/domain/`?
3. ✅ ¿Puedes extender un patrón existente?
4. ✅ Si creas algo nuevo, ¿sigue los patrones documentados?
5. ✅ ¿Usa Zod para validación?
6. ✅ ¿Es inmutable?
7. ✅ ¿Tiene método `create()` y `toJSON()`?
8. ✅ ¿Los métodos tienen nombres semánticos (no getters/setters)?

---

**Recuerda**: La consistencia es más importante que la perfección. Sigue los patrones existentes.
