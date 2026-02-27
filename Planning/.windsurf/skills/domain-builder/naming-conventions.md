# Convenciones de Nombres

## Descripción General

Los nombres consistentes son cruciales para la mantenibilidad y comprensión del dominio. Esta guía establece los patrones de nombres utilizados en toda la base de código.

## Casos de Uso

### Patrón

```
{Acción}{Entidad}{Contexto}UseCase
```

### Componentes

- **Acción**: Verbo que describe lo que hace el caso de uso
- **Entidad**: La entidad de dominio principal involucrada
- **Contexto**: El contexto delimitado al que pertenece

### Acciones Comunes

- `Get` - Recuperar una entidad o dato
- `Create` - Crear una nueva entidad
- `Update` - Modificar entidad existente
- `Delete` - Eliminar entidad
- `Search` - Consultar múltiples entidades con criterios
- `Subscribe` - Registrarse en un servicio
- `Calculate` - Realizar cálculo
- `Validate` - Verificar validez
- `Send` - Enviar datos/notificación

### Ejemplos

```typescript
// Bien
GetUserAuthUseCase
CreateBookingBookingUseCase
SearchPropertyPropertyUseCase
GetCurrentMarketSharedUseCase
SubscribeToNewsletterMarketingUseCase

// Mal - Orden incorrecta
UserGetAuthUseCase // ❌ Entidad antes de acción
AuthGetUserUseCase // ❌ Contexto antes de acción
```

### Casos Especiales

**Cuando la entidad y el contexto son iguales:**

```typescript
// Ambos son aceptables, pero el primero es preferible
CreateBookingBookingUseCase // ✅ Explícito
CreateBookingUseCase // ✅ Si el contexto es claro
```

**Contexto compartido con entidad específica:**

```typescript
GetCurrentMarketSharedUseCase // ✅
GetCurrentLanguageSharedUseCase // ✅
GetCurrentCurrencySharedUseCase // ✅
```

**Acciones con preposiciones:**

```typescript
SearchFromPartialAndCriteriaPropertyUseCase // ✅ Acción compleja
GetListOfAvailabilityBasicBookingUseCase // ✅ Devuelve una lista
```

## Modelos de Dominio

### Entidades

```
{Entidad}
```

**Siempre forma singular:**

```typescript
// Bien
User
Booking
Property
Hotel

// Mal
Users // ❌ Plural
Properties // ❌ Plural
```

### Objetos de Valor

```
{Concepto}
```

**Nombres descriptivos y específicos:**

```typescript
// Bien
Email
Phone
FullName
Money
Price
Currency
Rating
Stars

// Mal
UserEmail // ❌ Demasiado específico
Str // ❌ Demasiado genérico
Value // ❌ Demasiado vago
```

### Colecciones (ListOf)

```
ListOf{Entidad}
```

**Siempre singular en el patrón:**

```typescript
// Bien
ListOfUser
ListOfBooking
ListOfProperty
ListOfImage

// Mal
UserList // ❌ Orden incorrecta
UsersListOf // ❌ Estructura incorrecta
ListOfUsers // ❌ La entidad debe ser singular
```

### Listas Especializadas

```
ListOf{Adjetivo}{Entidad}
```

```typescript
// Bien
ListOfPaginatedProperty
ListOfPaginatedID
ListOfImageBucket

// Aceptable si es necesario
ListOfAvailability
```

## Interfaces de Repositorio

### Patrón

```
{Contexto}Repository
```

**Ejemplos:**

```typescript
// Bien
AuthRepository
BookingRepository
PropertyRepository
SharedRepository
MarketingRepository

// Mal
RepositoryAuth // ❌ Orden incorrecta
UserRepository // ❌ Debería ser AuthRepository
```

## Implementaciones de Repositorio

### Patrón

```
{Tipo}{Contexto}Repository
```

### Tipos de Repositorio

- `HTTP` - Llamadas a API externa
- `Cookie` - Almacenamiento basado en cookies
- `QueryParam` - Parámetros de consulta URL
- `PathName` - Datos de ruta URL
- `Domain` - Datos basados en dominio
- `Navigator` - Navegador
- `Header` - Encabezados HTTP
- `DataSource` - Fuentes de datos estáticas
- `Forbidden` - Acceso restringido (pruebas)

**Ejemplos:**

```typescript
// Bien
HTTPAuthRepository
CookieSharedRepository
QueryParamPropertyRepository
NavigatorSharedRepository
DataSourceSharedRepository

// Mal
AuthHTTPRepository // ❌ Orden incorrecta
HTTPRepository // ❌ Falta contexto
AuthRepository // ❌ Debería ser una interfaz
```

## Objetos Madre

### Patrón

```
{Entidad}Mother
```

**Ejemplos:**

```typescript
// Bien
UserMother
BookingMother
PropertyMother
HolderMother
InsuranceMother

// Mal
MotherUser // ❌ Orden incorrecta
UserFactory // ❌ Terminología incorrecta
UserBuilder // ❌ No es un constructor
CreateUser // ❌ No es descriptivo
```

## Archivos de Prueba

### Pruebas Unitarias de Modelos

```
{Entidad}.test.ts
```

**Ubicación:** `test/domain/{contexto}/models/`

**Ejemplos:**

```typescript
User.test.ts
Booking.test.ts
Property.test.ts
```

### Pruebas Unitarias de Casos de Uso

```
{Acción}{Entidad}{Contexto}UseCase.test.ts
```

**Ubicación:** `test/domain/{contexto}/units/`

**Ejemplos:**

```typescript
GetUserAuthUseCase.test.ts
CreateBookingBookingUseCase.test.ts
SearchPropertyPropertyUseCase.test.ts
```

### Pruebas de Integración de Casos de Uso

```
{Acción}{Entidad}{Contexto}UseCase.{plataforma}.test.ts
```

**Ubicación:** `test/domain/{contexto}/integrations/`

**Plataformas:**

- `.node.test.ts` - Específico de Node.js
- `.window.test.ts` - Específico de navegador
- `.test.ts` - Agnóstico de plataforma

**Ejemplos:**

```typescript
GetUserAuthUseCase.window.test.ts
GetBannersMarketingUseCase.node.test.ts
GetLocationUseCase.node.test.ts
```

## Estructura de Archivos y Directorios

### Archivos Fuente

```
src/
  {contexto}/
    application/
      {Acción}{Entidad}{Contexto}UseCase.ts
    domain/
      {Entidad}.ts
      ListOf{Entidad}.ts
      {Contexto}Repository.ts
    infrastructure/
      {Tipo}{Contexto}Repository.ts
      HTTP{Contexto}Repository/
        index.ts
        schemas/
          {endpoint}/
            index.ts
```

### Archivos de Prueba

```
test/
  domain/
    {contexto}/
      models/
        {Entidad}.test.ts
      units/
        {Acción}{Entidad}{Contexto}UseCase.test.ts
      integrations/
        {Acción}{Entidad}{Contexto}UseCase.{plataforma}.test.ts
  mothers/
    {contexto}/
      {Entidad}Mother.ts
```

## Tipos e Interfaces

### Tipos Schema (Zod)

```
{METODO}{EndpointDescriptivo}{Tipo}
```

**Componentes:**

- **METODO**: Método HTTP en mayúsculas (GET, POST, PUT, DELETE, PATCH)
- **EndpointDescriptivo**: Descripción del endpoint en PascalCase
- **Tipo**: Query, Body, Response

**Tipos inferidos:**

```
{NombreDelSchema}Type
```

**Ejemplos:**

```typescript
// Request Query
export const GETpropertiesByIDsQuery = z.object({
  lang: LanguageValidation.shape.value,
  id_properties: z.string(),
})

// Request Body
export const POSTSearchPropertiesBody = z.object({
  market: MarketValidation.shape.value,
  lang: LanguageValidation.shape.value,
  // ...
})

// Response con tipo inferido
export type POSTBannerResponseType = z.infer<typeof POSTBannerResponse>
export const POSTBannerResponse = z.object({
  properties: z.array(z.object({...})),
})

// Response simple
export type GETpropertiesByIDsResponse = z.infer<typeof GETpropertiesByIDsResponse>
export const GETpropertiesByIDsResponse = z.object({
  properties: z.array(z.object({...})),
})
```

**Ubicación:**

```
src/{contexto}/infrastructure/HTTP{Contexto}Repository/schemas/{endpoint}/index.ts
```

## Nombres de Métodos

### Métodos Factory

```typescript
// Prefiere createOrNull para validación
static createOrNull(props: Props): Entity | null

// Usa fromJSON para deserialización
static fromJSON(json: JSON): Entity

// Usa empty solo para ListOf
static empty(): ListOfEntity
```

### Métodos Semánticos

**Expresa la intención del negocio, no acceso a datos:**

```typescript
// Bien - Semántico
canBeCancelled(): boolean
isExpired(): boolean
calculateTotal(): Money
hasDiscount(): boolean
fullName(): string
availableRooms(): number

// Mal - Getters/Setters
getName(): string          // ❌
setName(name: string)      // ❌
getCanBeCancelled()        // ❌ Prefijo "get"
```

### Métodos de Serialización

```typescript
toJSON(): EntityJSON
toJSONOrNull(): EntityJSON | null  // Cuando es nullable
```

### Métodos de Consulta (ListOf)

```typescript
items(): ReadonlyArray<Entity>
isEmpty(): boolean
count(): number
first(): Entity | null
last(): Entity | null
```

## Constantes y Enums

### Códigos de Error

```
SCREAMING_SNAKE_CASE
```

```typescript
export enum ErrorsCode {
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  NOT_FOUND = 'NOT_FOUND',
  UNAUTHORIZED = 'UNAUTHORIZED',
}
```

### Configuración

```
SCREAMING_SNAKE_CASE
```

```typescript
export const API_BASE_URL = 'https://api.example.com'
export const MAX_RETRY_ATTEMPTS = 3
export const CACHE_TTL = 60000
```

## Errores Comunes a Evitar

### ❌ Patrones Incorrectos

```typescript
// Caso de Uso - Orden incorrecta
UserGetAuthUseCase // Debería ser: GetUserAuthUseCase
AuthGetCurrentUserUseCase // Debería ser: GetCurrentUserAuthUseCase

// Entidad - Forma plural
Users // Debería ser: User
Properties // Debería ser: Property

// ListOf - Estructura incorrecta
UserList // Debería ser: ListOfUser
ListOfUsers // Debería ser: ListOfUser (singular)

// Repositorio - Orden incorrecta
RepositoryAuth // Debería ser: AuthRepository
AuthHTTPRepository // Debería ser: HTTPAuthRepository

// Objeto Madre - Terminología incorrecta
UserFactory // Debería ser: UserMother
UserBuilder // Debería ser: UserMother

// Métodos - Getters/Setters
getName() // Debería ser: name() o fullName()
setEmail() // Debería ser: updateEmail() o withEmail()
```

## Referencia Rápida

| Elemento                             | Patrón                               | Ejemplo                           |
| ------------------------------------ | ------------------------------------ | --------------------------------- |
| Caso de Uso                          | `{Acción}{Entidad}{Contexto}UseCase` | `GetUserAuthUseCase`              |
| Entidad                              | `{Entidad}`                          | `User`                            |
| Objeto de Valor                      | `{Concepto}`                         | `Email`                           |
| ListOf                               | `ListOf{Entidad}`                    | `ListOfUser`                      |
| Interfaz de Repositorio              | `{Contexto}Repository`               | `AuthRepository`                  |
| Implementación de Repositorio        | `{Tipo}{Contexto}Repository`         | `HTTPAuthRepository`              |
| Objeto Madre                         | `{Entidad}Mother`                    | `UserMother`                      |
| Prueba de Modelo                     | `{Entidad}.test.ts`                  | `User.test.ts`                    |
| Prueba Unitaria de Caso de Uso       | `{UseCase}.test.ts`                  | `GetUserAuthUseCase.test.ts`      |
| Prueba de Integración de Caso de Uso | `{UseCase}.{plataforma}.test.ts`     | `GetUserAuthUseCase.node.test.ts` |

---

**Próximos Pasos:**

- ¿Creando modelos? → Lee [Modelos de Dominio](domain-models.md)
- ¿Implementando casos de uso? → Lee [Casos de Uso](use-cases.md)
- ¿Escribiendo pruebas? → Lee [Estrategia de Pruebas](testing-strategy.md)
