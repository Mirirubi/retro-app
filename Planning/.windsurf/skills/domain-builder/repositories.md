# Repositorios

## Overview

Repositories are the bridge between domain and infrastructure. They abstract data access, allowing the domain to remain pure and infrastructure-agnostic.

## Architecture

```
Domain Layer (Interface)
    ↓
Infrastructure Layer (Implementation)
    ↓
External Systems (API, Cookie, Query Params, etc.)
```

## Repository Types

### Available Repository Types

| Type           | Purpose              |
| -------------- | -------------------- |
| **HTTP**       | External API calls   |
| **Cookie**     | Browser cookies      |
| **QueryParam** | URL query parameters |
| **PathName**   | URL pathname         |
| **Domain**     | Domain name          |
| **Navigator**  | Browser navigator    |
| **Header**     | HTTP headers         |
| **DataSource** | Static data          |
| **Forbidden**  | Testing only         |

> **Note:** During the investigation phase, analyze the use case requirements to determine which repository types are appropriate. Ask about the data sources needed based on the specific domain context and business rules.

## Repository Interface (Domain Layer)

### Location

```
src/{context}/domain/{Context}Repository.ts
```

### Template

```typescript
// src/{context}/domain/{Context}Repository.ts

import type { {Entity} } from './{Entity}'
import type { ListOf{Entity} } from './ListOf{Entity}'
import type { ID } from '../../_kernel/ID'

// Input interfaces for method arguments
export interface findByIdInput { id: ID } // prettier-ignore
export interface findAllInput {} // prettier-ignore
export interface searchInput { criteria: SearchCriteria } // prettier-ignore
export interface saveInput { entity: {Entity} } // prettier-ignore
export interface updateInput { entity: {Entity} } // prettier-ignore
export interface deleteInput { id: ID } // prettier-ignore
export interface markAsActiveInput { id: ID } // prettier-ignore
export interface countByStatusInput { status: Status } // prettier-ignore

export interface {Context}Repository {
  // Queries
  findById: ({ id }: findByIdInput) => Promise<{Entity} | null>
  findAll: (input?: findAllInput) => Promise<ListOf{Entity}>
  search: ({ criteria }: searchInput) => Promise<SearchResult>

  // Commands
  save: ({ entity }: saveInput) => Promise<void>
  update: ({ entity }: updateInput) => Promise<void>
  delete: ({ id }: deleteInput) => Promise<void>

  // Domain-specific operations
  markAsActive: ({ id }: markAsActiveInput) => Promise<void>
  countByStatus: ({ status }: countByStatusInput) => Promise<number>
}
```

### Interface Guidelines

1. **Export input interfaces** for each method's arguments
2. **Use arrow functions** for method definitions
3. **Return domain objects**, not DTOs or raw data
4. **Use domain types** for parameters (ID, not string) — see examples below
5. **Async operations** always return Promises
6. **Nullable results** when entity might not exist
7. **Throw errors** for unexpected failures, return null for "not found"

> **⚠️ CRITICAL: Repository parameters MUST be domain objects, NEVER primitives.** The UseCase's `execute()` is responsible for transforming input primitives into domain objects before calling the repository.

```typescript
// ✅ Correct: Repository input uses domain types
export interface createPurchaseIdInput {
  availabilityIds: ListOfID    // ✅ Domain object
  insuranceIds?: ListOfID      // ✅ Domain object
  market: Market               // ✅ Domain object
}

// ❌ Wrong: Repository input uses primitives
export interface createPurchaseIdInput {
  availabilityIds: string      // ❌ Primitive
  insuranceIds?: string        // ❌ Primitive
  market: string               // ❌ Primitive
}
```

## HTTP Repository

### Structure

```
src/{context}/infrastructure/
├── HTTP{Context}Repository/
│   ├── index.ts (main implementation)
│   └── schemas/
│       └── {endpoint}/
│           └── index.ts (Zod schemas)
```

### Implementation Template

```typescript
// src/{context}/infrastructure/HTTP{Context}Repository/index.ts

import type { Config } from '../../../_config'
import { FactoryFetcher } from '../../../_fetcher/FactoryFetcher'
import { DomainError } from '../../../_kernel/DomainError'
import { ErrorsCode } from '../../../_kernel/ErrorsCode'
import type { {Context}Repository } from '../../domain/{Context}Repository'
import type { {Entity} } from '../../domain/{Entity}'
import { ListOf{Entity} } from '../../domain/ListOf{Entity}'
import { GET{Entity}Response, POST{Entity}Body } from './schemas/{endpoint}'

export class HTTP{Context}Repository implements {Context}Repository {
  static create({ config }: { config: Config }) {
    return new HTTP{Context}Repository(config)
  }

  constructor(private readonly config: Config) {}

  findById = async ({ id }: findByIdInput): Promise<{Entity} | null> => {
    const fetcher = await FactoryFetcher.create({ config: this.config }).fetcher()
    const API_GATEWAY = this.config.get('API_GATEWAY')

    const [err, json] = await fetcher.get(
      `${API_GATEWAY}/v3/{endpoint}/${id.toJSON()}`,
      { schemas: { response: GET{Entity}Response } }
    )

    if (err) {
      throw DomainError.withCodes(ErrorsCode.ENTITY_NOT_FOUND).withCauses(err)
    }

    return {Entity}.fromJSON(json)
  }

  save = async ({ entity }: saveInput): Promise<void> => {
    const fetcher = await FactoryFetcher.create({ config: this.config }).fetcher()
    const API_GATEWAY = this.config.get('API_GATEWAY')

    const [err] = await fetcher.post(`${API_GATEWAY}/v3/{endpoint}`, {
      body: JSON.stringify(entity.toJSON()),
      schemas: { body: POST{Entity}Body },
    })

    if (err) {
      throw DomainError.withCodes(ErrorsCode.SAVE_ERROR).withCauses(err)
    }
  }
}
```

### Zod Schemas

Schema naming pattern: `{METHOD}{EndpointName}{Type}`

```typescript
// src/{context}/infrastructure/HTTP{Context}Repository/schemas/{endpoint}/index.ts

import { z } from 'zod'
import { IDValidation } from '../../../../../_kernel/ID'
import { NameValidation } from '../../../../../_kernel/Name'

// GET endpoint with query params
export const GET{Entity}ByIDQuery = z.object({
  id: IDValidation.shape.value,
  lang: z.string(),
})

export type GET{Entity}ByIDResponseType = z.infer<typeof GET{Entity}ByIDResponse>
export const GET{Entity}ByIDResponse = z.object({
  id: z.number(),
  name: NameValidation.shape.value,
  email: z.string().email(),
  status: z.enum(['ACTIVE', 'INACTIVE']),
  createdAt: z.string(),
})

// POST endpoint with body
export const POST{Entity}Body = z.object({
  name: NameValidation.shape.value,
  email: z.string().email(),
})

export type POST{Entity}ResponseType = z.infer<typeof POST{Entity}Response>
export const POST{Entity}Response = z.object({
  id: z.number(),
  created: z.boolean(),
})
```

### Schema Guidelines

1. **Follow naming pattern** - `{METHOD}{EndpointName}{Type}` (Body, Query, Response)
2. **Export types first** - Use `z.infer<typeof Schema>` before defining schema
3. **Use kernel validations** - Reuse existing validation schemas from `_kernel`
4. **Match API structure** - Don't transform in schema, use domain's `fromAPI()`
5. **One file per endpoint** - Group related schemas in `schemas/{endpoint}/index.ts`

## Cookie Repository

### Template

```typescript
// src/{context}/infrastructure/Cookie{Context}Repository.ts

import type { Config } from '../../_config'
import { FactoryCookie } from '../../_cookie/FactoryCookie'
import type { {Context}Repository } from '../domain/{Context}Repository'
import type { {Entity} } from '../domain/{Entity}'

export class Cookie{Context}Repository implements {Context}Repository {
  static COOKIE_NAME = '{context}_data'

  static create({ config }: { config: Config }) {
    return new Cookie{Context}Repository(config)
  }

  constructor(private readonly config: Config) {}

  get = async (): Promise<{Entity} | null> => {
    const cookie = await FactoryCookie.create({ config: this.config }).cookie()

    const [err, data] = cookie.get<string>({
      key: Cookie{Context}Repository.COOKIE_NAME,
    })

    if (err) return null
    if (!data) return null

    try {
      const parsed = JSON.parse(data)
      return {Entity}.fromJSON(parsed)
    } catch {
      return null
    }
  }

  save = async ({ entity }: saveInput): Promise<void> => {
    const cookie = await FactoryCookie.create({ config: this.config }).cookie()

    cookie.set({
      key: Cookie{Context}Repository.COOKIE_NAME,
      value: JSON.stringify(entity.toJSON()),
      options: {
        maxAge: 60 * 60 * 24 * 30, // 30 days
        path: '/',
      },
    })
  }
}
```

## QueryParam Repository

### Template

```typescript
// src/{context}/infrastructure/QueryParam{Context}Repository.ts

import type { Config } from '../../_config'
import { FactoryQueryParams } from '../../_queryParams/FactoryQueryParams'
import type { {Context}Repository } from '../domain/{Context}Repository'
import type { SearchCriteria } from '../domain/SearchCriteria'

export class QueryParam{Context}Repository implements {Context}Repository {
  static create({ config }: { config: Config }) {
    return new QueryParam{Context}Repository(config)
  }

  constructor(private readonly config: Config) {}

  getSearchCriteria = async (): Promise<SearchCriteria> => {
    const params = await FactoryQueryParams.create({ config: this.config }).params()

    const [errorLocation, location] = params.getByQuery<string>({
      query: 'location',
    })
    const [errorCheckIn, checkIn] = params.getByQuery<string>({
      query: 'checkIn',
    })
    const [errorCheckOut, checkOut] = params.getByQuery<string>({
      query: 'checkOut',
    })

    if (errorLocation || errorCheckIn || errorCheckOut) {
      return SearchCriteria.empty()
    }

    return SearchCriteria.createOrNull({
      location: Location.fromJSON(location),
      checkIn: DateModel.create({ value: checkIn }),
      checkOut: DateModel.create({ value: checkOut }),
    })
  }
}
```

## Domain Repository

### Template

```typescript
// src/{context}/infrastructure/Domain{Context}Repository.ts

import type { Config } from '../../_config'
import { FactoryDomain } from '../../_domain/FactoryDomain'
import type { {Context}Repository } from '../domain/{Context}Repository'
import type { Market } from '../../shared/domain/Market'

export class Domain{Context}Repository implements {Context}Repository {
  static create({ config }: { config: Config }) {
    return new Domain{Context}Repository(config)
  }

  constructor(private readonly config: Config) {}

  getCurrentMarket = async (): Promise<Market> => {
    const domain = await FactoryDomain.create({ config: this.config }).domain()

    const [error, host] = domain.host<(typeof ALLOWED_MARKETS)[number]>()

    if (error) return Market.null()

    return Market.fromHostName({ hostname: host })
  }
}
```

## Navigator Repository

### Template

```typescript
// src/{context}/infrastructure/Navigator{Context}Repository.ts

import type { Config } from '../../_config'
import { FactoryNavigator } from '../../_navigator/FactoryNavigator'
import type { {Context}Repository } from '../domain/{Context}Repository'
import { Platform } from '../domain/Platform'

export class Navigator{Context}Repository implements {Context}Repository {
  static create({ config }: { config: Config }) {
    return new Navigator{Context}Repository(config)
  }

  constructor(private readonly config: Config) {}

  getPlatform = async (): Promise<Platform> => {
    const navigator = await FactoryNavigator.create({ config: this.config }).navigator()

    return Platform.fromUserAgent(navigator.userAgent())
  }
}
```

## Repository Proxy Pattern

### Purpose

Combine multiple repositories to check different sources in order.

**Important:** From the UseCase perspective, this is just a normal repository. The proxy implements the same interface, so the UseCase doesn't know it's checking multiple sources - it just calls the repository method.

### Example from Codebase

```typescript
// src/shared/infrastructure/SharedRepositoryProxy.ts

import type { Config } from '../../_config'
import { Market } from '../domain/Market'
import { QueryParamSharedRepository } from './QueryParamSharedRepository'
import { CookieSharedRepository } from './CookieSharedRepository'
import { DomainSharedRepository } from './DomainSharedRepository'
import { ForbiddenSharedRepository } from './ForbiddenSharedRepository'

export class SharedRepositoryProxy extends ForbiddenSharedRepository {
  static create({ config }: { config: Config }) {
    return new SharedRepositoryProxy(
      config,
      QueryParamSharedRepository.create({ config }),
      CookieSharedRepository.create({ config }),
      DomainSharedRepository.create({ config })
    )
  }

  constructor(
    config: Config,
    private readonly queryParamSharedRepository: QueryParamSharedRepository,
    private readonly cookieSharedRepository: CookieSharedRepository,
    private readonly domainSharedRepository: DomainSharedRepository
  ) {
    super(config)
  }

  market = async (): Promise<Market> => {
    // Try query params first
    const paramMarket = await this.queryParamSharedRepository.market()
    if (!paramMarket.isEmpty()) return paramMarket

    // Then try domain
    const domainMarket = await this.domainSharedRepository.market()
    if (!domainMarket.isEmpty()) return domainMarket

    // Then try cookie
    const cookieMarket = await this.cookieSharedRepository.market()
    if (!cookieMarket.isEmpty()) return cookieMarket

    // Finally, return default
    return Market.default()
  }
}
```

## Forbidden Repository Pattern

### ¿Cuándo usar este patrón?

**IMPORTANTE:** NO crear `Forbidden{Context}Repository` automáticamente. Primero detectar si el contexto ya usa este patrón.

### Regla de Detección

Durante la fase de investigación del UseCase:

1. Buscar archivo `Forbidden{Context}Repository.ts` en `src/{context}/infrastructure/`
2. Si **EXISTE** → Seguir el patrón existente
3. Si **NO EXISTE** → No forzar el patrón

### Patrón 1: Con ForbiddenRepository (ejemplo: shared)

**Estructura:**
```
src/shared/infrastructure/
├── ForbiddenSharedRepository.ts    ← Base class
├── SharedRepositoryProxy.ts        ← extends Forbidden
├── QueryParamSharedRepository.ts   ← extends Forbidden
├── CookieSharedRepository.ts       ← extends Forbidden
└── DomainSharedRepository.ts       ← extends Forbidden
```

**ForbiddenRepository implementation:**
```typescript
// src/shared/infrastructure/ForbiddenSharedRepository.ts

import { DomainError } from '../../_kernel/DomainError'
import { ErrorsCode } from '../../_kernel/ErrorsCode'
import type { SharedRepository } from '../domain/SharedRepository'
import type { Market } from '../domain/Market'
import type { Language } from '../domain/Language'

export class ForbiddenSharedRepository implements SharedRepository {
  static create({ config }: { config: Config }) {
    return new ForbiddenSharedRepository(config)
  }

  constructor(protected readonly config: Config) {}

  market = async (): Promise<Market> => {
    throw DomainError.withCodes(ErrorsCode.FORBIDDEN_REPOSITORY_METHOD)
  }

  language = async (): Promise<Language> => {
    throw DomainError.withCodes(ErrorsCode.FORBIDDEN_REPOSITORY_METHOD)
  }

  // ... all other methods throw FORBIDDEN_REPOSITORY_METHOD
}
```

**RepositoryProxy extends Forbidden:**
```typescript
// src/shared/infrastructure/SharedRepositoryProxy.ts

export class SharedRepositoryProxy extends ForbiddenSharedRepository {
  constructor(
    config: Config,
    private readonly queryParam: QueryParamSharedRepository,
    private readonly cookie: CookieSharedRepository,
    private readonly domain: DomainSharedRepository
  ) {
    super(config)
  }

  market = async (): Promise<Market> => {
    // Try multiple sources in order
    const paramMarket = await this.queryParam.market()
    if (!paramMarket.isEmpty()) return paramMarket

    const domainMarket = await this.domain.market()
    if (!domainMarket.isEmpty()) return domainMarket

    return Market.default()
  }
}
```

### Patrón 2: Sin ForbiddenRepository (ejemplo: auth)

**Estructura:**
```
src/auth/infrastructure/
├── AuthRepositoryProxy.ts          ← implements interface directly
├── HTTPAuthRepository/
│   └── index.ts                    ← implements interface, throws inline
├── CookieAuthRepository.ts         ← implements interface, throws inline
└── LocalStorageAuthRepository.ts   ← implements interface, throws inline
```

**RepositoryProxy implementa directamente:**
```typescript
// src/auth/infrastructure/AuthRepositoryProxy.ts

export class AuthRepositoryProxy implements AuthRepository {
  constructor(
    private readonly cookies: CookieAuthRepository,
    private readonly http: HTTPAuthRepository,
    private readonly localStorage: LocalStorageAuthRepository
  ) {}

  getDeleting = async (): Promise<UserDeletionStatus> => {
    return this.localStorage.getDeleting()
  }

  setAsDeleting = async (): Promise<void> => {
    return this.localStorage.setAsDeleting()
  }

  checkLoginStatus = async (): Promise<LoginStatus> => {
    return this.cookies.checkLoginStatus()
  }

  deleteCurrentUser = async (): Promise<void> => {
    await this.http.deleteCurrentUser()
    await this.localStorage.setAsDeleting()
  }
}
```

**Repositorios concretos lanzan errores inline:**
```typescript
// src/auth/infrastructure/HTTPAuthRepository/index.ts

export class HTTPAuthRepository implements AuthRepository {
  deleteCurrentUser = async (): Promise<void> => {
    // Actual implementation
    const fetcher = await FactoryFetcher.create({ config: this.config }).fetcher()
    const [err] = await fetcher.post(`${API}/delete-account`)
    if (err) throw DomainError.withCodes(ErrorsCode.DELETE_ERROR).withCauses(err)
  }

  // Methods not supported by HTTP throw inline
  getDeleting = async (): Promise<UserDeletionStatus> => {
    throw DomainError.withCodes(ErrorsCode.FORBIDDEN_REPOSITORY_METHOD)
  }

  setAsDeleting = async (): Promise<void> => {
    throw DomainError.withCodes(ErrorsCode.FORBIDDEN_REPOSITORY_METHOD)
  }

  checkLoginStatus = async (): Promise<LoginStatus> => {
    throw DomainError.withCodes(ErrorsCode.FORBIDDEN_REPOSITORY_METHOD)
  }
}
```

### Checklist para Planificación de Repositorios

Antes de crear repositorios:

- [ ] Buscar `Forbidden{Context}Repository.ts` en el contexto
- [ ] Si existe → Crear ForbiddenRepository y hacer que todos lo extiendan
- [ ] Si NO existe → NO crear ForbiddenRepository, implementar interfaz directamente
- [ ] RepositoryProxy debe seguir el patrón detectado (extends vs implements)
- [ ] Los métodos no soportados lanzan `FORBIDDEN_REPOSITORY_METHOD`

## Error Handling

### Repository Errors

Fetcher returns a tuple `[error, response]`. Always check for errors and use `DomainError.withCodes().withCauses()`:

```typescript
export class HTTPAuthRepository implements AuthRepository {
  findById = async ({ id }: findByIdInput): Promise<User | null> => {
    const [err, json] = await this.props.fetcher.get(`/users/${id.toJSON()}`, {
      schemas: { response: userResponseSchema },
    })

    if (err) {
      throw DomainError.withCodes(ErrorsCode.USER_NOT_FOUND).withCauses(err)
    }

    return User.fromJSON(json)
  }

  save = async ({ user }: saveUserInput): Promise<void> => {
    const [err] = await this.props.fetcher.post('/users', {
      body: JSON.stringify(user.toJSON()),
      schemas: { body: userBodySchema },
    })

    if (err) {
      throw DomainError.withCodes(ErrorsCode.USER_SAVE_ERROR).withCauses(err)
    }
  }
}
```

## Testing Repositories

Repositories are tested through integration tests, not unit tests.

### Why Integration Tests?

- Repositories interact with external systems
- Need to verify actual HTTP calls, cookie behavior, etc.
- Unit tests would just mock everything

### Location

```
test/domain/{context}/integrations/{UseCase}.{platform}.test.ts
```

## Checklist

Before finishing a repository:

- [ ] Interface in domain layer
- [ ] Implementation in infrastructure layer
- [ ] Returns domain objects (not DTOs)
- [ ] Uses domain types for parameters
- [ ] Zod schemas for HTTP repositories
- [ ] Proper error handling (null for not found)
- [ ] No domain logic in repository
- [ ] Tested via integration tests

---

**Next Steps:**

- Write tests? → Read [Testing Strategy](testing-strategy.md)
- Final review? → Check [Quality Checklist](quality-checklist.md)
