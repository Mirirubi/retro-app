# Casos de Uso

## Overview

Use Cases represent application-layer business logic orchestration. They coordinate between domain models and infrastructure, implementing specific user stories or system operations.

## Core Principles

1. **Single Responsibility**: One use case, one specific action
2. **Orchestration, not Logic**: Coordinate domain objects, don't duplicate domain logic
3. **Dependency Injection**: Receive all dependencies via constructor
4. **Platform Agnostic**: No platform-specific code (Node/Browser)
5. **Immutable**: No internal state, pure function behavior

## Use Case Structure

### Complete Template

```typescript
// src/{context}/application/{Action}{Entity}{Context}UseCase.ts

import { UseCase } from '../../_kernel/architecture'
import type { Config } from '../../_config'
import type { {Context}Repository } from '../domain/{Context}Repository'
import { {Context}RepositoryProxy } from '../infrastructure/{Context}RepositoryProxy'
import type { {Entity} } from '../domain/{Entity}'
import { DomainError } from '../../_kernel/DomainError'
import { ErrorsCode } from '../../_kernel/ErrorsCode'

// Input interface (only if execute needs parameters)
export interface {Action}{Entity}{Context}UseCaseInput {
  id: number
  // other params...
}

export default class {Action}{Entity}{Context}UseCase
  implements UseCase<{Action}{Entity}{Context}UseCaseInput, {Entity}>
{
  static readonly USE_CASE_NAME = '{Action}{Entity}{Context}UseCase'

  static create({
    config,
    repository
  }: {
    config: Config
    repository?: {Context}Repository
  }) {
    return new {Action}{Entity}{Context}UseCase(
      repository ?? {Context}RepositoryProxy.create({ config })
    )
  }

  constructor(private repository: {Context}Repository) {}

  async execute({ id }: {Action}{Entity}{Context}UseCaseInput): Promise<{Entity}> {
    // 1. Validate input
    if (!id) {
      throw DomainError.withCodes(ErrorsCode.VALIDATION_ERROR)
    }

    // 2. Call repository
    const entity = await this.repository.findById(id)

    // 3. Apply business logic (delegate to domain)
    if (!entity.canBeProcessed()) {
      throw DomainError.withCodes(ErrorsCode.BUSINESS_RULE_VIOLATION)
    }

    // 4. Return result
    return entity
  }
}
```

### Template Without Input Parameters

```typescript
// src/{context}/application/{Action}{Entity}{Context}UseCase.ts

import { UseCase } from '../../_kernel/architecture'
import type { {Entity} } from '../domain/{Entity}'

export default class {Action}{Entity}{Context}UseCase
  implements UseCase<undefined, {Entity}>
{
  static readonly USE_CASE_NAME = '{Action}{Entity}{Context}UseCase'

  static create() {
    return new {Action}{Entity}{Context}UseCase()
  }

  async execute(): Promise<{Entity}> {
    // Implementation
    return entity
  }
}
```

### Template With Multiple Dependencies

```typescript
// src/{context}/application/{Action}{Entity}{Context}UseCase.ts

import { UseCase } from '../../_kernel/architecture'
import type { Config } from '../../_config'
import type { {Context}Repository } from '../domain/{Context}Repository'
import { {Context}RepositoryProxy } from '../infrastructure/{Context}RepositoryProxy'
import GetCurrentMarketSharedUseCase from '../../shared/application/GetCurrentMarketSharedUseCase'
import type { {Entity} } from '../domain/{Entity}'

export default class {Action}{Entity}{Context}UseCase
  implements UseCase<undefined, {Entity}>
{
  static readonly USE_CASE_NAME = '{Action}{Entity}{Context}UseCase'

  static create({
    config,
    repository,
    marketUseCase,
  }: {
    config: Config
    repository?: {Context}Repository
    marketUseCase?: GetCurrentMarketSharedUseCase
  }) {
    return new {Action}{Entity}{Context}UseCase(
      repository ?? {Context}RepositoryProxy.create({ config }),
      marketUseCase ?? GetCurrentMarketSharedUseCase.create({ config })
    )
  }

  constructor(
    private repository: {Context}Repository,
    private getCurrentMarketUseCase: GetCurrentMarketSharedUseCase
  ) {}

  async execute(): Promise<{Entity}> {
    const market = await this.getCurrentMarketUseCase.execute()
    const entity = await this.repository.findByMarket({ market })
    return entity
  }
}
```

## With Cache Decorator

### When to Use Cache
- Use case is called frequently with same inputs
- Data changes infrequently
- Performance is critical
- Data is expensive to fetch/compute

### Cache Template

```typescript
import type { UseCase } from '../../_kernel/architecture'
import { UseCaseCache } from '@s4l/cache'
import type { Config } from '../../_config'
import type { {Context}Repository } from '../domain/{Context}Repository'
import { {Context}RepositoryProxy } from '../infrastructure/{Context}RepositoryProxy'
import GetCurrentMarketSharedUseCase from '../../shared/application/GetCurrentMarketSharedUseCase'
import GetCurrentLanguageSharedUseCase from '../../shared/application/GetCurrentLanguageSharedUseCase'
import type { {Entity} } from '../domain/{Entity}'

const FIVE_MINUTES = 5 * 60 * 1000

// Note: NO @UseCaseCache decorator and NO export default on the class
class {Action}{Entity}{Context}UseCase implements UseCase<undefined, {Entity}> {
  static readonly USE_CASE_NAME = '{Action}{Entity}{Context}UseCase'

  static create({
    config,
    repository,
    marketUseCase,
    languageUseCase,
  }: {
    config: Config
    repository?: {Context}Repository
    marketUseCase?: GetCurrentMarketSharedUseCase
    languageUseCase?: GetCurrentLanguageSharedUseCase
  }) {
    return new {Action}{Entity}{Context}UseCase(
      repository ?? {Context}RepositoryProxy.create({ config }),
      marketUseCase ?? GetCurrentMarketSharedUseCase.create({ config }),
      languageUseCase ?? GetCurrentLanguageSharedUseCase.create({ config })
    )
  }

  constructor(
    private repository: {Context}Repository,
    // NOTE: Use cases that affect cache MUST be public readonly
    public readonly getCurrentMarketUseCase: GetCurrentMarketSharedUseCase,
    public readonly getCurrentLanguageUseCase: GetCurrentLanguageSharedUseCase
  ) {}

  async execute(): Promise<{Entity}> {
    // Get dependencies that affect the response
    const [market, language] = await Promise.all([
      this.getCurrentMarketUseCase.execute(),
      this.getCurrentLanguageUseCase.execute(),
    ])

    // Call repository with those dependencies
    return this.repository.getData({ market, language })
  }
}

// Export the result of UseCaseCache function (NOT the class directly)
export default UseCaseCache<typeof {Action}{Entity}{Context}UseCase, {Entity}>(
  {Action}{Entity}{Context}UseCase,
  {
    ttl: FIVE_MINUTES,
    /* v8 ignore start -- @preserve */
    async asides() {
      // DUPLICATE the same calls from execute() that affect cache
      const [market, language] = await Promise.all([
        await this.getCurrentMarketUseCase.execute(),
        await this.getCurrentLanguageUseCase.execute(),
      ])
      return { market, language }
    },
    /* v8 ignore stop -- @preserve */
  }
)
```

### Cache Pattern Explanation

**Key Points:**

1. **Class Declaration**: No `export default` on the class, no `@UseCaseCache` decorator
2. **Public Readonly Dependencies**: Use cases that affect cache MUST be `public readonly` in constructor
3. **Export Pattern**: Export the result of calling `UseCaseCache<typeof Class, ReturnType>(Class, config)`
4. **Function Signature**: `UseCaseCache<typeof {UseCase}, {ReturnType}>(class, config)`
5. **TTL Configuration**: Define cache time-to-live constant (e.g., `FIVE_MINUTES`)
6. **Asides Function**: DUPLICATE the same use case calls from `execute()` that affect the response
7. **Coverage Comments**: Always wrap `asides` in `/* v8 ignore start/stop -- @preserve */`

**Why `asides` duplicates `execute()` calls:**
- `asides` returns "side values" that affect the cache key but aren't passed as `execute()` parameters
- These are contextual dependencies (market, language, OS, platform, etc.)
- The cache uses these values to create a unique cache key
- Must be public readonly so `asides` can access them via `this`

**Why v8 ignore comments:**
- Cache doesn't work in tests (mocked in setupTests.ts)
- Without comments, coverage tool marks `asides` as uncovered
- Comments exclude from coverage metrics while preserving production functionality

```typescript
/* v8 ignore start -- @preserve */
async asides() {
  // Duplicate use case calls from execute()
}
/* v8 ignore stop -- @preserve */
```

## Common Use Case Patterns

### 1. Query Pattern (Get/Find)

```typescript
import { UseCase } from '../../_kernel/architecture'
import type { Config } from '../../_config'
import type { AuthRepository } from '../domain/AuthRepository'
import { AuthRepositoryProxy } from '../infrastructure/AuthRepositoryProxy'
import type { User } from '../domain/User'
import { DomainError } from '../../_kernel/DomainError'
import { ErrorsCode } from '../../_kernel/ErrorsCode'
import { ID } from '../../_kernel/ID'

export interface GetUserAuthUseCaseInput {
  userId: string
}

export default class GetUserAuthUseCase
  implements UseCase<GetUserAuthUseCaseInput, User>
{
  static readonly USE_CASE_NAME = 'GetUserAuthUseCase'

  static create({
    config,
    repository
  }: {
    config: Config
    repository?: AuthRepository
  }) {
    return new GetUserAuthUseCase(
      repository ?? AuthRepositoryProxy.create({ config })
    )
  }

  constructor(private repository: AuthRepository) {}

  async execute({ userId }: GetUserAuthUseCaseInput): Promise<User> {
    const user = await this.repository.findById(ID.create({ value: userId }))

    if (!user) {
      throw DomainError.withCodes(ErrorsCode.NOT_FOUND)
    }

    return user
  }
}
```

### 2. Create Pattern

```typescript
import { UseCase } from '../../_kernel/architecture'
import type { Config } from '../../_config'
import type { BookingRepository } from '../domain/BookingRepository'
import { BookingRepositoryProxy } from '../infrastructure/BookingRepositoryProxy'
import GetCurrentUserAuthUseCase from '../../auth/application/GetCurrentUserAuthUseCase'
import type { Booking } from '../domain/Booking'
import { DomainError } from '../../_kernel/DomainError'
import { ErrorsCode } from '../../_kernel/ErrorsCode'
import { ID } from '../../_kernel/ID'

export interface CreateBookingBookingUseCaseInput {
  propertyId: string
  checkIn: string
  checkOut: string
  rooms: number
}

export default class CreateBookingBookingUseCase
  implements UseCase<CreateBookingBookingUseCaseInput, Booking>
{
  static readonly USE_CASE_NAME = 'CreateBookingBookingUseCase'

  static create({
    config,
    repository,
    getCurrentUserUseCase,
  }: {
    config: Config
    repository?: BookingRepository
    getCurrentUserUseCase?: GetCurrentUserAuthUseCase
  }) {
    return new CreateBookingBookingUseCase(
      repository ?? BookingRepositoryProxy.create({ config }),
      getCurrentUserUseCase ?? GetCurrentUserAuthUseCase.create({ config })
    )
  }

  constructor(
    private repository: BookingRepository,
    private getCurrentUserUseCase: GetCurrentUserAuthUseCase
  ) {}

  async execute({
    propertyId,
    checkIn,
    checkOut,
    rooms
  }: CreateBookingBookingUseCaseInput): Promise<Booking> {
    // 1. Get current user
    const user = await this.getCurrentUserUseCase.execute()

    // 2. Create domain entity
    const booking = Booking.createOrNull({
      id: ID.generate(),
      userId: user.id(),
      propertyId: ID.create({ value: propertyId }),
      checkIn: new Date(checkIn),
      checkOut: new Date(checkOut),
      rooms,
    })

    if (!booking) {
      throw DomainError.withCodes(ErrorsCode.VALIDATION_ERROR)
    }

    // 3. Save to repository
    await this.repository.save(booking)

    // 4. Return created entity
    return booking
  }
}
```

### 3. Search Pattern

```typescript
import { UseCase } from '../../_kernel/architecture'
import type { Config } from '../../_config'
import type { PropertyRepository } from '../domain/PropertyRepository'
import { PropertyRepositoryProxy } from '../infrastructure/PropertyRepositoryProxy'
import GetCurrentMarketSharedUseCase from '../../shared/application/GetCurrentMarketSharedUseCase'
import type { SearchCriteria } from '../domain/SearchCriteria'
import type { SearchResult } from '../domain/SearchResult'
import { DomainError } from '../../_kernel/DomainError'
import { ErrorsCode } from '../../_kernel/ErrorsCode'

export interface SearchPropertyPropertyUseCaseInput {
  criteria: SearchCriteria
}

export default class SearchPropertyPropertyUseCase
  implements UseCase<SearchPropertyPropertyUseCaseInput, SearchResult>
{
  static readonly USE_CASE_NAME = 'SearchPropertyPropertyUseCase'

  static create({
    config,
    repository,
    marketUseCase,
  }: {
    config: Config
    repository?: PropertyRepository
    marketUseCase?: GetCurrentMarketSharedUseCase
  }) {
    return new SearchPropertyPropertyUseCase(
      repository ?? PropertyRepositoryProxy.create({ config }),
      marketUseCase ?? GetCurrentMarketSharedUseCase.create({ config })
    )
  }

  constructor(
    private repository: PropertyRepository,
    private getCurrentMarketUseCase: GetCurrentMarketSharedUseCase
  ) {}

  async execute({ criteria }: SearchPropertyPropertyUseCaseInput): Promise<SearchResult> {
    // 1. Enrich criteria with context
    const market = await this.getCurrentMarketUseCase.execute()
    const enrichedCriteria = criteria.withMarket(market)

    // 2. Validate criteria
    if (!enrichedCriteria.isValid()) {
      throw DomainError.withCodes(ErrorsCode.VALIDATION_ERROR)
    }

    // 3. Execute search
    const result = await this.repository.search(enrichedCriteria)

    // 4. Return results
    return result
  }
}
```

### 4. Update Pattern

```typescript
import { UseCase } from '../../_kernel/architecture'
import type { Config } from '../../_config'
import type { AuthRepository } from '../domain/AuthRepository'
import { AuthRepositoryProxy } from '../infrastructure/AuthRepositoryProxy'
import GetCurrentUserAuthUseCase from './GetCurrentUserAuthUseCase'
import type { User } from '../domain/User'
import { DomainError } from '../../_kernel/DomainError'
import { ErrorsCode } from '../../_kernel/ErrorsCode'

export interface UpdateUserProfileAuthUseCaseInput {
  name?: string
  email?: string
}

export default class UpdateUserProfileAuthUseCase
  implements UseCase<UpdateUserProfileAuthUseCaseInput, User>
{
  static readonly USE_CASE_NAME = 'UpdateUserProfileAuthUseCase'

  static create({
    config,
    repository,
    getCurrentUserUseCase,
  }: {
    config: Config
    repository?: AuthRepository
    getCurrentUserUseCase?: GetCurrentUserAuthUseCase
  }) {
    return new UpdateUserProfileAuthUseCase(
      repository ?? AuthRepositoryProxy.create({ config }),
      getCurrentUserUseCase ?? GetCurrentUserAuthUseCase.create({ config })
    )
  }

  constructor(
    private repository: AuthRepository,
    private getCurrentUserUseCase: GetCurrentUserAuthUseCase
  ) {}

  async execute({ name, email }: UpdateUserProfileAuthUseCaseInput): Promise<User> {
    // 1. Get current user
    const currentUser = await this.getCurrentUserUseCase.execute()

    // 2. Create updated user (immutable)
    const updatedUser = User.createOrNull({
      id: currentUser.id(),
      name: name || currentUser.fullName(),
      email: email || currentUser.emailAddress(),
    })

    if (!updatedUser) {
      throw DomainError.withCodes(ErrorsCode.VALIDATION_ERROR)
    }

    // 3. Save
    await this.repository.update(updatedUser)

    return updatedUser
  }
}
```

### 5. Orchestration Pattern (Multiple Dependencies)

```typescript
import { UseCase } from '../../_kernel/architecture'
import type { Config } from '../../_config'
import GetCurrentMarketSharedUseCase from '../../shared/application/GetCurrentMarketSharedUseCase'
import GetCurrentLanguageSharedUseCase from '../../shared/application/GetCurrentLanguageSharedUseCase'
import GetCurrentCurrencySharedUseCase from '../../shared/application/GetCurrentCurrencySharedUseCase'
import GetCurrentPartialSearchSharedUseCase from '../../shared/application/GetCurrentPartialSearchSharedUseCase'
import type { Search } from '../domain/Search'

export default class CreateSearchPropertyUseCase
  implements UseCase<undefined, Search>
{
  static readonly USE_CASE_NAME = 'CreateSearchPropertyUseCase'

  static create({
    config,
    marketUseCase,
    languageUseCase,
    currencyUseCase,
    partialSearchUseCase,
  }: {
    config: Config
    marketUseCase?: GetCurrentMarketSharedUseCase
    languageUseCase?: GetCurrentLanguageSharedUseCase
    currencyUseCase?: GetCurrentCurrencySharedUseCase
    partialSearchUseCase?: GetCurrentPartialSearchSharedUseCase
  }) {
    return new CreateSearchPropertyUseCase(
      marketUseCase ?? GetCurrentMarketSharedUseCase.create({ config }),
      languageUseCase ?? GetCurrentLanguageSharedUseCase.create({ config }),
      currencyUseCase ?? GetCurrentCurrencySharedUseCase.create({ config }),
      partialSearchUseCase ?? GetCurrentPartialSearchSharedUseCase.create({ config })
    )
  }

  constructor(
    private getCurrentMarketUseCase: GetCurrentMarketSharedUseCase,
    private getCurrentLanguageUseCase: GetCurrentLanguageSharedUseCase,
    private getCurrentCurrencyUseCase: GetCurrentCurrencySharedUseCase,
    private getPartialSearchUseCase: GetCurrentPartialSearchSharedUseCase
  ) {}

  async execute(): Promise<Search> {
    // Orchestrate multiple dependencies
    const [market, language, currency, partial] = await Promise.all([
      this.getCurrentMarketUseCase.execute(),
      this.getCurrentLanguageUseCase.execute(),
      this.getCurrentCurrencyUseCase.execute(),
      this.getPartialSearchUseCase.execute(),
    ])

    // Create search with all context
    const search = Search.create({
      market,
      language,
      currency,
      partial,
    })

    return search
  }
}
```

### 6. Validation Pattern

```typescript
import { UseCase } from '../../_kernel/architecture'
import type { Config } from '../../_config'
import type { BookingRepository } from '../domain/BookingRepository'
import { BookingRepositoryProxy } from '../infrastructure/BookingRepositoryProxy'
import type { PropertyRepository } from '../../property/domain/PropertyRepository'
import { PropertyRepositoryProxy } from '../../property/infrastructure/PropertyRepositoryProxy'
import { ID } from '../../_kernel/ID'

export interface ValidateBookingBookingUseCaseInput {
  bookingId: string
}

export default class ValidateBookingBookingUseCase
  implements UseCase<ValidateBookingBookingUseCaseInput, boolean>
{
  static readonly USE_CASE_NAME = 'ValidateBookingBookingUseCase'

  static create({
    config,
    bookingRepository,
    propertyRepository,
  }: {
    config: Config
    bookingRepository?: BookingRepository
    propertyRepository?: PropertyRepository
  }) {
    return new ValidateBookingBookingUseCase(
      bookingRepository ?? BookingRepositoryProxy.create({ config }),
      propertyRepository ?? PropertyRepositoryProxy.create({ config })
    )
  }

  constructor(
    private bookingRepository: BookingRepository,
    private propertyRepository: PropertyRepository
  ) {}

  async execute({ bookingId }: ValidateBookingBookingUseCaseInput): Promise<boolean> {
    // 1. Get booking
    const booking = await this.bookingRepository.findById(
      ID.create({ value: bookingId })
    )
    if (!booking) return false

    // 2. Get property
    const property = await this.propertyRepository.findById(booking.propertyId())
    if (!property) return false

    // 3. Validate business rules
    if (!booking.canBeCancelled()) return false
    if (!property.isAvailable()) return false
    if (booking.isExpired()) return false

    return true
  }
}
```

## Input/Output Types

### Input: Always Primitives

**Rule:** Input interfaces ALWAYS use primitives (string, number, boolean). Transform to domain models inside `execute()`.

```typescript
// ✅ Correct: Primitives in input
export interface CreateBookingUseCaseInput {
  propertyId: string
  checkIn: string
  checkOut: string
  rooms: number
  holderName: string
  holderEmail: string
}

export default class CreateBookingUseCase
  implements UseCase<CreateBookingUseCaseInput, Booking>
{
  async execute({
    propertyId,
    checkIn,
    checkOut,
    rooms,
    holderName,
    holderEmail
  }: CreateBookingUseCaseInput): Promise<Booking> {
    // Transform primitives to domain models inside execute
    return this.repository.createBooking({
      propertyId: ID.create({ value: propertyId }),
      checkIn: DateModel.create({ value: checkIn }),
      checkOut: DateModel.create({ value: checkOut }),
      rooms: RoomCount.create({ value: rooms }),
      holder: Holder.create({
        name: Name.create({ value: holderName }),
        email: Email.create({ value: holderEmail }),
      }),
    })
  }
}

// ❌ Wrong: Domain models in input
export interface CreateBookingUseCaseInput {
  propertyId: ID  // ❌ Should be string
  checkIn: Date   // ❌ Should be string
  holder: Holder  // ❌ Should be primitives
}
```

### No Input
```typescript
// When getting current/global state
export default class GetCurrentMarketUseCase
  implements UseCase<undefined, Market>
{
  async execute(): Promise<Market> {
    return this.repository.getCurrentMarket()
  }
}
```

### Repository Calls: Always Domain Objects

**Rule:** When calling repository methods from `execute()`, ALL parameters MUST be domain objects. The `execute()` method is responsible for transforming input primitives into domain objects before passing them to the repository.

```typescript
// ✅ Correct: Transform primitives to domain objects, then call repository
export default class CreatePurchaseIdBookingUseCase
  implements UseCase<CreatePurchaseIdBookingUseCaseInput, PurchaseId>
{
  async execute({ availabilityIds, insuranceIds }: CreatePurchaseIdBookingUseCaseInput): Promise<PurchaseId> {
    const market = await this.getCurrentMarketUseCase.execute()

    return this.repository.createPurchaseId({
      availabilityIds: ListOfID.fromString({ ids: availabilityIds }),
      insuranceIds: insuranceIds ? ListOfID.fromString({ ids: insuranceIds }) : undefined,
      market,
    })
  }
}

// ❌ Wrong: Passing primitives directly to repository
export default class CreatePurchaseIdBookingUseCase
  implements UseCase<CreatePurchaseIdBookingUseCaseInput, PurchaseId>
{
  async execute({ availabilityIds, insuranceIds }: CreatePurchaseIdBookingUseCaseInput): Promise<PurchaseId> {
    const market = await this.getCurrentMarketUseCase.execute()

    return this.repository.createPurchaseId({
      availabilityIds,   // ❌ string instead of ListOfID
      insuranceIds,      // ❌ string instead of ListOfID
      market,
    })
  }
}
```

**Flow:** `Input (primitives)` → `execute() transforms` → `Repository (domain objects)` → `Infrastructure (serializes to external format)`

### Output: Domain Models or Null

**Rule:** Output is ALWAYS a domain model, null, or throws an error.

```typescript
// Single entity (or null if not found)
async execute({ id }: Input): Promise<User | null>

// Domain model
async execute(): Promise<Market>

// List of domain models
async execute({ criteria }: Input): Promise<ListOfProperty>

// Complex domain output
async execute(): Promise<SearchResult>  // SearchResult is a domain model

// Throws error if validation fails
async execute({ id }: Input): Promise<User> {
  if (!id) {
    throw DomainError.withCodes(ErrorsCode.VALIDATION_ERROR)
  }
  return user
}
```

## Error Handling

### Using DomainError

DomainError uses a builder pattern with static methods:

```typescript
import { DomainError } from '../../_kernel/DomainError'
import { ErrorsCode } from '../../_kernel/ErrorsCode'
import type { Config } from '../../_config'
import type { AuthRepository } from '../domain/AuthRepository'
import { AuthRepositoryProxy } from '../infrastructure/AuthRepositoryProxy'
import type { User } from '../domain/User'
import { ID } from '../../_kernel/ID'

export interface GetUserAuthUseCaseInput {
  userId: string
}

export default class GetUserAuthUseCase
  implements UseCase<GetUserAuthUseCaseInput, User>
{
  static readonly USE_CASE_NAME = 'GetUserAuthUseCase'

  static create({ config, repository }: { config: Config; repository?: AuthRepository }) {
    return new GetUserAuthUseCase(repository ?? AuthRepositoryProxy.create({ config }))
  }

  constructor(private repository: AuthRepository) {}

  async execute({ userId }: GetUserAuthUseCaseInput): Promise<User> {
    const id = ID.create({ value: userId })

    // Validation error
    if (!id.isValid()) {
      throw DomainError.withCodes(ErrorsCode.VALIDATION_ERROR)
    }

    const user = await this.repository.findById(id)

    // Not found error
    if (!user) {
      throw DomainError.withCodes(ErrorsCode.NOT_FOUND)
    }

    // Business rule violation
    if (!user.isActive()) {
      throw DomainError.withCodes(ErrorsCode.BUSINESS_RULE_VIOLATION)
    }

    return user
  }
}
```

### Propagating Errors

```typescript
export interface CreateBookingUseCaseInput {
  propertyId: string
  // other fields...
}

export default class CreateBookingUseCase
  implements UseCase<CreateBookingUseCaseInput, Booking>
{
  static readonly USE_CASE_NAME = 'CreateBookingUseCase'

  static create({
    config,
    repository,
    getCurrentUserUseCase,
  }: {
    config: Config
    repository?: BookingRepository
    getCurrentUserUseCase?: GetCurrentUserAuthUseCase
  }) {
    return new CreateBookingUseCase(
      repository ?? BookingRepositoryProxy.create({ config }),
      getCurrentUserUseCase ?? GetCurrentUserAuthUseCase.create({ config })
    )
  }

  constructor(
    private repository: BookingRepository,
    private getCurrentUserUseCase: GetCurrentUserAuthUseCase
  ) {}

  async execute(input: CreateBookingUseCaseInput): Promise<Booking> {
    try {
      // Let domain errors propagate naturally
      const user = await this.getCurrentUserUseCase.execute()
      const property = await this.repository.findPropertyById({
        id: ID.create({ value: input.propertyId })
      })

      // Create booking
      const booking = Booking.createOrNull({...})

      return booking
    } catch (error) {
      // Only catch if you need to add context or transform
      if (error instanceof DomainError) {
        throw error // Propagate domain errors
      }

      // Transform unexpected errors with .withCauses()
      throw DomainError.withCodes(ErrorsCode.INTERNAL_ERROR).withCauses(error)
    }
  }
}
```

### Error Pattern

```typescript
// ✅ Correct: Builder pattern
throw DomainError.withCodes(ErrorsCode.VALIDATION_ERROR)
throw DomainError.withCodes(ErrorsCode.NOT_FOUND).withCauses(originalError)

// ❌ Wrong: Constructor pattern
throw new DomainError({
  message: 'Error message',
  code: ErrorsCode.VALIDATION_ERROR,
})
```

## Dependency Management

### Constructor Injection (Positional)

```typescript
export default class UseCase implements UseCase<Input, Output> {
  static readonly USE_CASE_NAME = 'UseCase'

  static create({
    config,
    repository,
    otherUseCase,
  }: {
    config: Config
    repository?: Repository
    otherUseCase?: OtherUseCase
  }) {
    return new UseCase(
      repository ?? RepositoryProxy.create({ config }),
      otherUseCase ?? OtherUseCase.create({ config })
    )
  }

  constructor(
    private repository: Repository,
    private otherUseCase: OtherUseCase
  ) {}
}
```

### Multiple Dependencies

```typescript
export default class UseCase implements UseCase<undefined, Output> {
  static readonly USE_CASE_NAME = 'UseCase'

  static create({
    config,
    userRepository,
    bookingRepository,
    getCurrentUserUseCase,
    getCurrentMarketUseCase,
  }: {
    config: Config
    userRepository?: UserRepository
    bookingRepository?: BookingRepository
    getCurrentUserUseCase?: GetCurrentUserAuthUseCase
    getCurrentMarketUseCase?: GetCurrentMarketSharedUseCase
  }) {
    return new UseCase(
      userRepository ?? UserRepositoryProxy.create({ config }),
      bookingRepository ?? BookingRepositoryProxy.create({ config }),
      getCurrentUserUseCase ?? GetCurrentUserAuthUseCase.create({ config }),
      getCurrentMarketUseCase ?? GetCurrentMarketSharedUseCase.create({ config })
    )
  }

  constructor(
    private userRepository: UserRepository,
    private bookingRepository: BookingRepository,
    private getCurrentUserUseCase: GetCurrentUserAuthUseCase,
    private getCurrentMarketUseCase: GetCurrentMarketSharedUseCase
  ) {}
}
```

### Avoiding God Objects

**❌ Bad:**
```typescript
static create({
  config,
  allRepositories,  // Too many deps
  allUseCases,
}: {
  config: Config
  allRepositories?: AllRepositories
  allUseCases?: AllUseCases
}) {
  // ...
}
```

**✅ Good:**
```typescript
static create({
  config,
  bookingRepository,  // Only what's needed
  getCurrentUserUseCase,
}: {
  config: Config
  bookingRepository?: BookingRepository
  getCurrentUserUseCase?: GetCurrentUserAuthUseCase
}) {
  // ...
}
```

## Platform Agnostic - Always

**IMPORTANT:** Use Cases must ALWAYS be platform-agnostic. Never create platform-specific use cases.

### Why No Platform-Specific Use Cases?

- Use Cases orchestrate domain logic and repositories
- Platform-specific concerns belong in the **infrastructure layer** (repositories)
- Repositories abstract the platform details (Cookie, Navigator, Domain, QueryParam, etc.)

### Example: Wrong vs Right

**❌ WRONG: Platform-specific use case**
```typescript
// ❌ Never do this
export default class GetDeviceInfoWindowUseCase {
  async execute(): Promise<Device> {
    return Device.create({
      userAgent: window.navigator.userAgent,  // ❌ Platform code in use case
    })
  }
}
```

**✅ RIGHT: Platform-agnostic use case with platform-specific repository**
```typescript
// ✅ Use case remains platform-agnostic
export default class GetDeviceInfoSharedUseCase
  implements UseCase<undefined, Device>
{
  static readonly USE_CASE_NAME = 'GetDeviceInfoSharedUseCase'

  static create({ config, repository }: { config: Config; repository?: SharedRepository }) {
    return new GetDeviceInfoSharedUseCase(
      repository ?? NavigatorSharedRepository.create({ config })  // ✅ Repository handles platform
    )
  }

  constructor(private repository: SharedRepository) {}

  async execute(): Promise<Device> {
    return this.repository.getDeviceInfo()  // ✅ Platform abstracted
  }
}

// Platform logic in repository (infrastructure layer)
export class NavigatorSharedRepository {
  async getDeviceInfo(): Promise<Device> {
    const navigator = await FactoryNavigator.create({ config: this.config }).navigator()
    return Device.create({
      userAgent: navigator.userAgent(),  // ✅ Platform handled by infrastructure
    })
  }
}
```

**Key principle:** If you need platform-specific behavior, create a platform-specific **repository**, not a platform-specific use case.

## Domain Events

### Automatic Emission
Domain events are emitted automatically by the domain infrastructure. Use cases don't need special code for events.

```typescript
// ✅ Events work automatically
export default class CreateBookingUseCase
  implements UseCase<CreateBookingInput, Booking>
{
  static readonly USE_CASE_NAME = 'CreateBookingUseCase'

  static create({ config, repository }: { config: Config; repository?: BookingRepository }) {
    return new CreateBookingUseCase(repository ?? BookingRepositoryProxy.create({ config }))
  }

  constructor(private repository: BookingRepository) {}

  async execute(input: CreateBookingInput): Promise<Booking> {
    const booking = await this.repository.save(booking)
    // Event automatically emitted: 'CreateBookingBookingUseCase'
    return booking
  }
}

// ❌ Don't manually emit events
export default class CreateBookingUseCase
  implements UseCase<CreateBookingInput, Booking>
{
  static readonly USE_CASE_NAME = 'CreateBookingUseCase'

  static create({ config, repository }: { config: Config; repository?: BookingRepository }) {
    return new CreateBookingUseCase(repository ?? BookingRepositoryProxy.create({ config }))
  }

  constructor(private repository: BookingRepository) {}

  async execute(input: CreateBookingInput): Promise<Booking> {
    const booking = await this.repository.save(booking)
    this.emitEvent('BookingCreated', booking) // ❌ Not needed
    return booking
  }
}
```

## Anti-Patterns to Avoid

### ❌ Domain Logic in Use Case
```typescript
// BAD - Business logic should be in domain
export interface CalculatePriceUseCaseInput {
  bookingId: string
}

export default class CalculatePriceUseCase
  implements UseCase<CalculatePriceUseCaseInput, Money>
{
  static readonly USE_CASE_NAME = 'CalculatePriceUseCase'

  static create({ config, repository }: { config: Config; repository?: BookingRepository }) {
    return new CalculatePriceUseCase(repository ?? BookingRepositoryProxy.create({ config }))
  }

  constructor(private repository: BookingRepository) {}

  async execute({ bookingId }: CalculatePriceUseCaseInput): Promise<Money> {
    const booking = await this.repository.findById(ID.create({ value: bookingId }))

    let total = 0
    for (const room of booking.rooms()) {
      total += room.basePrice()
      if (booking.hasDiscount()) {
        total -= total * 0.1 // ❌ Logic in use case
      }
    }
    return Money.create(total)
  }
}

// GOOD - Delegate to domain
export default class CalculatePriceUseCase
  implements UseCase<CalculatePriceUseCaseInput, Money>
{
  static readonly USE_CASE_NAME = 'CalculatePriceUseCase'

  static create({ config, repository }: { config: Config; repository?: BookingRepository }) {
    return new CalculatePriceUseCase(repository ?? BookingRepositoryProxy.create({ config }))
  }

  constructor(private repository: BookingRepository) {}

  async execute({ bookingId }: CalculatePriceUseCaseInput): Promise<Money> {
    const booking = await this.repository.findById(ID.create({ value: bookingId }))
    return booking.calculateTotal() // ✅ Domain handles logic
  }
}
```

### ❌ State in Use Case
```typescript
// BAD
export interface GetEntityUseCaseInput {
  id: string
}

export default class GetEntityUseCase implements UseCase<GetEntityUseCaseInput, Entity> {
  static readonly USE_CASE_NAME = 'GetEntityUseCase'

  private cache: Map<string, Entity> = new Map() // ❌ State

  static create({ config, repository }: { config: Config; repository?: Repository }) {
    return new GetEntityUseCase(repository ?? RepositoryProxy.create({ config }))
  }

  constructor(private repository: Repository) {}

  async execute({ id }: GetEntityUseCaseInput): Promise<Entity> {
    if (this.cache.has(id)) {
      return this.cache.get(id)!
    }
    // ...
  }
}

// GOOD
@UseCaseCache // ✅ Use cache decorator
export default class GetEntityUseCase implements UseCase<GetEntityUseCaseInput, Entity> {
  static readonly USE_CASE_NAME = 'GetEntityUseCase'

  static create({ config, repository }: { config: Config; repository?: Repository }) {
    return new GetEntityUseCase(repository ?? RepositoryProxy.create({ config }))
  }

  constructor(private repository: Repository) {}

  async execute({ id }: GetEntityUseCaseInput): Promise<Entity> {
    // Stateless
  }
}
```

### ❌ Direct Infrastructure Access
```typescript
// BAD
export default class GetUserUseCase implements UseCase<undefined, User> {
  static readonly USE_CASE_NAME = 'GetUserUseCase'

  static create() {
    return new GetUserUseCase()
  }

  async execute(): Promise<User> {
    const response = await fetch('/api/user') // ❌ Direct fetch
    return User.fromJSON(response)
  }
}

// GOOD
export default class GetUserUseCase implements UseCase<undefined, User> {
  static readonly USE_CASE_NAME = 'GetUserUseCase'

  static create({ config, repository }: { config: Config; repository?: UserRepository }) {
    return new GetUserUseCase(repository ?? UserRepositoryProxy.create({ config }))
  }

  constructor(private repository: UserRepository) {} // ✅ Use repository

  async execute(): Promise<User> {
    return this.repository.getCurrentUser()
  }
}
```

### ❌ Platform-Specific Code
```typescript
// BAD - Platform code in use case
export default class GetDeviceInfoUseCase implements UseCase<undefined, Device> {
  static readonly USE_CASE_NAME = 'GetDeviceInfoUseCase'

  static create() {
    return new GetDeviceInfoUseCase()
  }

  async execute(): Promise<Device> {
    return Device.create({
      userAgent: window.navigator.userAgent, // ❌ Platform-specific (window)
      platform: window.navigator.platform,   // ❌ Platform-specific
    })
  }
}

// GOOD - Platform abstracted in repository
export default class GetDeviceInfoUseCase implements UseCase<undefined, Device> {
  static readonly USE_CASE_NAME = 'GetDeviceInfoUseCase'

  static create({ config, repository }: { config: Config; repository?: SharedRepository }) {
    return new GetDeviceInfoUseCase(
      repository ?? NavigatorSharedRepository.create({ config })
    )
  }

  constructor(private repository: SharedRepository) {}

  async execute(): Promise<Device> {
    return this.repository.getDeviceInfo() // ✅ Platform abstracted
  }
}
```

## Checklist

Before finishing a use case:

**Structure:**
- [ ] Implements `UseCase<Input, Output>` interface (or `UseCase<undefined, Output>` if no input)
- [ ] Has `static readonly USE_CASE_NAME` property
- [ ] Has `static create()` method with named dependencies
- [ ] Constructor receives dependencies positionally (not as props object)
- [ ] Default repository instantiation in `create()` method using `??`
- [ ] Input interface defined as `{Action}{Entity}{Context}UseCaseInput` (if needed)
- [ ] Input interface uses ONLY primitives (string, number, boolean)
- [ ] Transforms primitives to domain models inside `execute()`
- [ ] Repository calls receive domain objects (NEVER primitives)
- [ ] Output is domain model, null, or throws error (never primitives)
- [ ] Execute method uses destructured named parameters
- [ ] Uses `export default class` (or `export default UseCaseCache(...)` if cached)

**Business Logic:**
- [ ] Single responsibility (one action)
- [ ] No internal state
- [ ] Delegates to domain for business logic
- [ ] Proper error handling using `DomainError.withCodes(ErrorsCode.XXX).withCauses(err)`
- [ ] Never uses `new DomainError({...})` constructor pattern
- [ ] ALWAYS platform-agnostic (no `window`, `process`, `document`, etc.)
- [ ] Platform concerns handled in repositories, not use cases
- [ ] No manual event emission

**Cache (if applicable):**
- [ ] Class has NO `export default` (exported via UseCaseCache function)
- [ ] Class has NO `@UseCaseCache` decorator
- [ ] Use cases affecting cache are `public readonly` in constructor
- [ ] TTL constant defined (e.g., `FIVE_MINUTES`)
- [ ] Export uses `UseCaseCache<typeof Class, ReturnType>(Class, config)`
- [ ] `asides` function duplicates use case calls from `execute()`
- [ ] `asides` wrapped in `/* v8 ignore start/stop -- @preserve */` comments
- [ ] `asides` returns object with all contextual dependencies

---

**Next Steps:**
- Create repositories? → Read [Repositories](repositories.md)
- Write tests? → Read [Testing Strategy](testing-strategy.md)
- Final review? → Check [Quality Checklist](quality-checklist.md)
