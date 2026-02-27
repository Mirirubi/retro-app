# Estrategia de Pruebas

## Overview

Comprehensive testing ensures domain integrity and system reliability. This guide covers the complete testing approach: Mother Objects, unit tests, and integration tests.

## Testing Philosophy

### Three-Layer Testing

1. **Model Unit Tests**: Verify domain model behavior
2. **Use Case Unit Tests**: Verify orchestration logic (mocked repositories)
3. **Use Case Integration Tests**: Verify real-world behavior (real repositories)

### Key Principles

- **Mother Objects are mandatory** - Every model needs one
- **Use Mother Objects in all tests** - Never create instances manually
- **Integration tests use real repositories** - UseCase.create() instantiates default repositories
- **Unit tests mock repositories** - Isolate the unit under test
- **No mocking of domain models** - Domain models are never mocked

## Mother Objects

### Purpose

- Generate valid test data
- Provide semantic factory methods
- Ensure consistency across tests
- Make tests readable and maintainable

### Location

```
test/mothers/{context}/{Entity}Mother.ts
```

### Mother Object Guidelines

1. **Method named `random()`** - Main factory method always called `random()`
2. **Default parameters with destructuring** - All parameters have defaults using other Mother Objects
3. **Return Mother instance** - Return `new {Entity}Mother(...)`, not the entity directly
4. **Provide `.model()` method** - To extract the actual entity
5. **Use other Mother Objects** - Import and use Mother Objects for value objects (IDMother, NameMother, etc.)
6. **Semantic methods** - Named after scenarios (active, inactive, withEmail, etc.)
7. **Use `Entity.create()`** - Not `createOrNull()`

### ValueObject Mother with Faker

```typescript
// For simple ValueObjects, use faker directly
import { Name } from '../../../src/_kernel/Name'
import { faker } from '@faker-js/faker'

export class NameMother {
  static random() {
    return new NameMother(Name.create({ value: faker.company.name() }))
  }

  static withValue(value: string) {
    return new NameMother(Name.create({ value }))
  }

  static withLength(n: number) {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    const value = Array.from(
      { length: n },
      () => characters[Math.floor(Math.random() * characters.length)]
    ).join('')

    return new NameMother(Name.create({ value: `Name-${value}` }))
  }

  constructor(private readonly instance: Name) {}

  model() {
    return this.instance
  }
}
```

### Enum Mother with Random Selection

```typescript
// For Enums, randomly select a value from the array
import { Status } from '../../../src/_kernel/Status'

export class StatusMother {
  static random() {
    const statuses = ['ACTIVE', 'INACTIVE', 'PENDING', 'CANCELLED']
    const randomStatus = statuses[Math.floor(Math.random() * statuses.length)]
    return new StatusMother(Status.create({ value: randomStatus }))
  }

  static active() {
    return new StatusMother(Status.create({ value: 'ACTIVE' }))
  }

  static inactive() {
    return new StatusMother(Status.create({ value: 'INACTIVE' }))
  }

  static pending() {
    return new StatusMother(Status.create({ value: 'PENDING' }))
  }

  constructor(private readonly instance: Status) {}

  model() {
    return this.instance
  }
}
```

### Entity Mother with Nested Dependencies

```typescript
// For complex entities, compose using other Mother Objects
export class BookingMother {
  static random({
    id = IDMother.random().model(),
    user = UserMother.random().model(), // Nested mother object
    property = PropertyMother.random().model(), // Nested mother object
    rooms = ListOfRoomMother.random({ length: 2 }).model(), // List of nested objects
    holder = HolderMother.random().model(),
    checkIn = DateMother.future().model(),
    checkOut = DateMother.future().model(),
  } = {}) {
    return new BookingMother(
      Booking.create({
        id,
        user,
        property,
        rooms,
        holder,
        checkIn,
        checkOut,
      })
    )
  }

  static forProperty(property: Property) {
    return this.random({ property })
  }

  static withDates(checkIn: string, checkOut: string) {
    return this.random({
      checkIn: DateMother.withValue(checkIn).model(),
      checkOut: DateMother.withValue(checkOut).model(),
    })
  }

  constructor(private readonly instance: Booking) {}

  model() {
    return this.instance
  }
}
```

## Model Unit Tests

### Purpose

Test domain model behavior in isolation.

### Location

```
test/domain/{context}/models/{Entity}.test.ts
```

### Template

```typescript
// test/domain/{context}/models/{Entity}.test.ts

import { describe, expect, it } from 'vitest'
import { {Entity} } from '../../../../src/{context}/domain/{Entity}'
import { {Entity}Mother } from '../../../mothers/{context}/{Entity}Mother'
import { ID } from '../../../../src/_kernel/ID'

describe('{Entity}', () => {
  describe('create', () => {
    it('should create a valid entity', () => {
      const entity = {Entity}Mother.random().model()

      expect(entity).toBeDefined()
      expect(entity).toBeInstanceOf({Entity})
    })

    it('should return null for invalid data', () => {
      const entity = {Entity}.createOrNull({
        id: null as any,
      })

      expect(entity).toBeNull()
    })
  })

  describe('fromJSON', () => {
    it('should deserialize correctly', () => {
      const original = {Entity}Mother.random().model()
      const json = original.toJSON()
      const entity = {Entity}.fromJSON(json)

      expect(entity.toJSON()).toEqual(json)
    })

    it('should handle nested objects', () => {
      const original = {Entity}Mother.random().model()
      const json = original.toJSON()
      const entity = {Entity}.fromJSON(json)

      expect(entity.nestedObject()).toBeDefined()
      expect(entity.nestedObject().toJSON()).toEqual(json.nestedObject)
    })
  })

  describe('toJSON', () => {
    it('should serialize correctly', () => {
      const entity = {Entity}Mother.random().model()
      const json = entity.toJSON()

      expect(json).toMatchObject({
        id: expect.any(String),
        name: expect.any(String),
        status: expect.any(String),
      })
    })
  })

  describe('semanticMethod', () => {
    it('should return expected value', () => {
      const entity = {Entity}Mother.random().model()

      expect(entity.fullName()).toBe(entity.toJSON().name)
    })

    it('should calculate correctly', () => {
      const entity = {Entity}Mother.random({
        value: MoneyMother.withValue(100).model(),
      }).model()

      expect(entity.calculateTotal()).toBe(121) // 100 * 1.21
    })
  })

  describe('isSpecialCondition', () => {
    it('should return true when condition is met', () => {
      const entity = {Entity}Mother.active().model()

      expect(entity.isActive()).toBe(true)
    })

    it('should return false when condition is not met', () => {
      const entity = {Entity}Mother.inactive().model()

      expect(entity.isActive()).toBe(false)
    })
  })

  describe('business logic', () => {
    it('should validate business rules', () => {
      const entity = {Entity}Mother.expired().model()

      expect(entity.isExpired()).toBe(true)
      expect(entity.canBeProcessed()).toBe(false)
    })
  })
})
```

### Model Test Coverage

Test these aspects for every model:

- [ ] `create` with valid data
- [ ] `createOrNull` with invalid data (returns null)
- [ ] `fromJSON` deserialization
- [ ] `toJSON` serialization
- [ ] Round-trip (toJSON → fromJSON)
- [ ] All semantic methods
- [ ] All business logic methods
- [ ] Edge cases and business validations

## Use Case Unit Tests

### Purpose

Test use case orchestration logic with mocked dependencies (repositories and other use cases). All dependencies are mocked using plain objects with vi.fn().

### Location

```
test/domain/{context}/units/{Action}{Entity}{Context}UseCase.test.ts
```

### Template

```typescript
// test/domain/{context}/units/{Action}{Entity}{Context}UseCase.test.ts

import { beforeEach, describe, expect, it, Mock, vi } from 'vitest'
import { {Action}{Entity}{Context}UseCase } from '../../../../src/{context}/application/{Action}{Entity}{Context}UseCase'
import type { {Context}Repository } from '../../../../src/{context}/domain/{Context}Repository'
import { ConfigMother } from '../../../mothers/_config/ConfigMother'
import { {Entity}Mother } from '../../../mothers/{context}/{Entity}Mother'
import { IDMother } from '../../../mothers/_kernel/IDMother'

interface LocalTestContext {
  repository: { findById: Mock; save: Mock }
  usecase: {Action}{Entity}{Context}UseCase
}

describe('{Action}{Entity}{Context}UseCase', () => {
  beforeEach<LocalTestContext>(async context => {
    context.repository = {
      findById: vi.fn(),
      save: vi.fn(),
    }

    context.usecase = {Action}{Entity}{Context}UseCase.create({
      config: ConfigMother.forTesting().model(),
      repository: context.repository as unknown as {Context}Repository,
    })

    return async () => vi.resetAllMocks()
  })

  describe('creation', () => {
    it('should create use case with default repository when not provided', () => {
      // When
      const usecase = {Action}{Entity}{Context}UseCase.create({
        config: ConfigMother.forTesting().model(),
      })

      // Then
      expect(usecase).toBeInstanceOf({Action}{Entity}{Context}UseCase)
    })

    it('should create use case with custom repository when provided', () => {
      // Given
      const customRepository = {
        findById: vi.fn(),
        save: vi.fn(),
      } as unknown as {Context}Repository

      // When
      const usecase = {Action}{Entity}{Context}UseCase.create({
        config: ConfigMother.forTesting().model(),
        repository: customRepository,
      })

      // Then
      expect(usecase).toBeInstanceOf({Action}{Entity}{Context}UseCase)
    })
  })

  describe('execute', () => {
    it<LocalTestContext>('should return entity from repository', async context => {
      // Given
      const expectedEntity = {Entity}Mother.random().model()
      const id = IDMother.random().model()
      context.repository.findById.mockResolvedValue(expectedEntity)

      // When
      const result = await context.usecase.execute(id)

      // Then
      expect(result).toEqual(expectedEntity)
      expect(context.repository.findById).toHaveBeenCalledWith(id)
      expect(context.repository.findById).toHaveBeenCalledTimes(1)
    })

    it<LocalTestContext>('should save entity successfully', async context => {
      // Given
      const entity = {Entity}Mother.random().model()
      context.repository.save.mockResolvedValue(entity.id())

      // When
      const result = await context.usecase.execute(entity)

      // Then
      expect(result).toBeDefined()
      expect(context.repository.save).toHaveBeenCalledWith(entity)
      expect(context.repository.save).toHaveBeenCalledTimes(1)
    })
  })
})
```

### Example with Multiple Dependencies

```typescript
// Example with repository + other use cases as collaborators
import type GetOtherDataSharedUseCase from '../../../../src/shared/application/GetOtherDataSharedUseCase'

interface LocalTestContext {
  repository: { findById: Mock }
  otherUseCase: { execute: Mock }
  usecase: {Action}{Entity}{Context}UseCase
}

describe('{Action}{Entity}{Context}UseCase', () => {
  beforeEach<LocalTestContext>(async context => {
    context.repository = {
      findById: vi.fn(),
    }
    context.otherUseCase = {
      execute: vi.fn(),
    }

    context.usecase = {Action}{Entity}{Context}UseCase.create({
      config: ConfigMother.forTesting().model(),
      repository: context.repository as unknown as {Context}Repository,
      otherUseCase: context.otherUseCase as unknown as GetOtherDataSharedUseCase,
    })

    return async () => vi.resetAllMocks()
  })

  it<LocalTestContext>('should orchestrate multiple dependencies', async context => {
    // Given
    const entity = {Entity}Mother.random().model()
    const otherData = OtherDataMother.random().model()
    context.repository.findById.mockResolvedValue(entity)
    context.otherUseCase.execute.mockResolvedValue(otherData)

    // When
    const result = await context.usecase.execute(IDMother.random().model())

    // Then
    expect(result).toBeDefined()
    expect(context.repository.findById).toHaveBeenCalled()
    expect(context.otherUseCase.execute).toHaveBeenCalled()
  })
})
```

### Unit Test Guidelines

1. **Use LocalTestContext interface** - Define all mocks (repositories, use cases)
2. **Use beforeEach<LocalTestContext>** - Type the context parameter
3. **Mock as plain objects** - Only methods needed: `{ execute: vi.fn() }`
4. **Cast as unknown as Type** - To avoid TypeScript errors
5. **Use UseCase.create()** - Always instantiate with mocked dependencies
6. **Reset mocks** - Return `async () => vi.resetAllMocks()` from beforeEach
7. **Use Given-When-Then** - Not Arrange-Act-Assert
8. **Access via context** - `it<LocalTestContext>('...', async context => ...)`
9. **Mother Objects everywhere** - `.random().model()` for all data

### Unit Test Coverage

Test these scenarios for every use case:

- [ ] Creation tests (optional but recommended)
  - [ ] Create with default repository
  - [ ] Create with custom repository
- [ ] Happy path (successful execution)
- [ ] Repository/UseCase called with correct parameters
- [ ] Repository/UseCase called correct number of times
- [ ] Multiple dependencies orchestration
- [ ] Business rule validation

## Use Case Integration Tests

### Purpose

Test real-world behavior with real repositories. Use the UseCase's `create()` method to instantiate default repositories automatically.

### Location

```
test/domain/{context}/integrations/{Action}{Entity}{Context}UseCase.{platform}.test.ts
```

### Platform Suffixes

- `.node.test.ts` - Node.js specific
- `.window.test.ts` - Browser specific
- `.test.ts` - Platform agnostic (if both work)

### Template with HTTPRepository (most common)

```typescript
// test/domain/{context}/integrations/{Action}{Entity}{Context}UseCase.node.test.ts

import { beforeEach, describe, expect, it } from 'vitest'
import { {Action}{Entity}{Context}UseCase } from '../../../../src/{context}/application/{Action}{Entity}{Context}UseCase'
import { {Entity} } from '../../../../src/{context}/domain/{Entity}'
import { ConfigMother } from '../../../mothers/_config/ConfigMother'
import { EnvironmentMother } from '../../../mothers/_kernel/EnvironmentMother'
import { {Entity}Mother } from '../../../mothers/{context}/{Entity}Mother'
import { IDMother } from '../../../mothers/_kernel/IDMother'
import { NodeFetcherMock } from '../../../mocks/_fetcher/NodeFetcherMock'

interface LocalTestContext {
  usecase: {Action}{Entity}{Context}UseCase
  config: ConfigMother
  fetcher: NodeFetcherMock
}

describe('[Node] {Action}{Entity}{Context}UseCase - Integration', () => {
  beforeEach<LocalTestContext>(async context => {
    EnvironmentMother.stub().withIsNode().returnsTrue()

    context.config = ConfigMother.forTesting()
    context.fetcher = NodeFetcherMock.stub().build()

    context.usecase = {Action}{Entity}{Context}UseCase.create({
      config: context.config.model(),
    })

    return async () => {
      context.fetcher.restore()
      EnvironmentMother.restore()
    }
  })

  it<LocalTestContext>('should retrieve entity successfully', async context => {
    // Given
    const id = IDMother.random().model()
    const expectedEntity = {Entity}Mother.random().model()

    context.fetcher
      .withAuthToken()
      .withSuccessRequest({
        method: 'get',
        url: `http://testing.gateway/{context}/entities/${id.value}`,
      })

    // When
    const result = await context.usecase.execute(id)

    // Then
    expect(result).toBeInstanceOf({Entity})
    expect(result.id().value).toBe(id.value)
  })

  it<LocalTestContext>('should handle API errors', async context => {
    // Given
    const id = IDMother.random().model()

    context.fetcher
      .withAuthToken()
      .withFailureRequest({
        method: 'get',
        url: `http://testing.gateway/{context}/entities/${id.value}`,
        status: 500,
      })

    // When & Then
    await expect(() => context.usecase.execute(id)).rejects.toThrow()
  })
})
```

### Template with CookieRepository

```typescript
// test/domain/{context}/integrations/{Action}{Entity}{Context}UseCase.window.test.ts

import { beforeEach, describe, expect, it } from 'vitest'
import { {Action}{Entity}{Context}UseCase } from '../../../../src/{context}/application/{Action}{Entity}{Context}UseCase'
import { ConfigMother } from '../../../mothers/_config/ConfigMother'
import { EnvironmentMother } from '../../../mothers/_kernel/EnvironmentMother'
import { WindowCookieMock } from '../../../mocks/_cookie/WindowCookieMock'

interface LocalTestContext {
  usecase: {Action}{Entity}{Context}UseCase
  config: ConfigMother
  cookieMock: WindowCookieMock
}

describe('[Window] {Action}{Entity}{Context}UseCase - Integration', () => {
  beforeEach<LocalTestContext>(async context => {
    EnvironmentMother.stub().withIsNode().returnsFalse()

    context.config = ConfigMother.forTesting().withFrameworkRequest()
    context.cookieMock = WindowCookieMock.stub().build()

    context.usecase = {Action}{Entity}{Context}UseCase.create({
      config: context.config.model(),
    })

    return async () => {
      context.cookieMock.restore()
      EnvironmentMother.restore()
    }
  })

  it<LocalTestContext>('should check cookie successfully', async context => {
    // Given
    context.cookieMock.withCookieStorage('sfl_user=user123')

    // When
    const result = await context.usecase.execute()

    // Then
    expect(result).toBeDefined()
    context.cookieMock.verify()
  })
})
```

### Template with Multiple Infrastructure Dependencies

```typescript
// test/domain/{context}/integrations/{Action}{Entity}{Context}UseCase.window.test.ts

import { beforeEach, describe, expect, it } from 'vitest'
import { {Action}{Entity}{Context}UseCase } from '../../../../src/{context}/application/{Action}{Entity}{Context}UseCase'
import { ConfigMother } from '../../../mothers/_config/ConfigMother'
import { EnvironmentMother } from '../../../mothers/_kernel/EnvironmentMother'
import { WindowFetcherMock } from '../../../mocks/_fetcher/WindowFetcherMock'
import { WindowCookieMock } from '../../../mocks/_cookie/WindowCookieMock'
import { WindowDomainMock } from '../../../mocks/_domain/WindowDomainMock'

interface LocalTestContext {
  usecase: {Action}{Entity}{Context}UseCase
  config: ConfigMother
  fetcher: WindowFetcherMock
  cookieMock: WindowCookieMock
  domainMock: WindowDomainMock
}

describe('[Window] {Action}{Entity}{Context}UseCase - Integration', () => {
  beforeEach<LocalTestContext>(async context => {
    EnvironmentMother.stub().withIsNode().returnsFalse()

    context.config = ConfigMother.forTesting()
    context.fetcher = WindowFetcherMock.stub().build()
    context.cookieMock = WindowCookieMock.stub().build()
    context.domainMock = WindowDomainMock.stub().build()

    context.usecase = {Action}{Entity}{Context}UseCase.create({
      config: context.config.model(),
    })

    return async () => {
      context.fetcher.restore()
      context.cookieMock.restore()
      context.domainMock.restore()
      EnvironmentMother.restore()
    }
  })

  it<LocalTestContext>('should work with multiple infrastructure dependencies', async context => {
    // Given
    context.cookieMock.withCookieStorage('sfl_user=user123')
    context.domainMock.withHostname('www.example.com')
    context.fetcher
      .withAuthToken()
      .withSuccessRequest({
        method: 'get',
        url: 'http://testing.gateway/data',
      })

    // When
    const result = await context.usecase.execute()

    // Then
    expect(result).toBeDefined()
    context.fetcher.verify()
    context.cookieMock.verify()
  })
})
```

### Infrastructure Mocks Available

Integration tests mock **only infrastructure drivers**, never repositories or domain:

1. **FetcherMock** (most common) - For HTTPRepository
   - `NodeFetcherMock` - Node.js environment
   - `WindowFetcherMock` - Browser environment
   - Pattern: `FetcherMock.stub().build()`
   - Configure requests:
     - `.withSuccessRequest({ method, url, schemas?, delay?, bodyMapper? })` - HTTP 200
     - `.withFailureRequest({ method, url, status?, schemas? })` - HTTP error
     - `.withRequest({ method, url, status, headers, schemas, delay })` - Custom
   - Auth: `.withAuthToken()` - Add fake auth token
   - Validation: `.verify()` - Ensures all configured requests were called
   - Assertions: `.latestPostBodyEqual(body)`, `.containsPostBody(body)`

2. **CookieMock** - For CookieRepository
   - `NodeCookieMock` - Node.js environment
   - `WindowCookieMock` - Browser environment
   - Pattern: `CookieMock.stub().build()`
   - Configure: `.withCookieStorage('key=value; other=data')`
   - Validation: `.verify()` - Ensures cookie was accessed

3. **DomainMock** - For domain/hostname operations
   - `NodeDomainMock`, `WindowDomainMock`
   - Pattern: `DomainMock.stub().build()`
   - Configure: `.withHostname('example.com')`

4. **NavigatorMock** - For browser navigator
   - `NodeNavigatorMock`, `WindowNavigatorMock`
   - Pattern: `NavigatorMock.stub().build()`

5. **HeaderMock** - For HTTP headers
   - `NodeHeaderMock`, `WindowHeaderMock`
   - Pattern: `HeaderMock.stub().build()`

6. **PathNameMock** - For URL pathname operations
   - `NodePathNameMock`, `WindowPathNameMock`
   - Pattern: `PathNameMock.stub().build()`

7. **QueryParamsMock** - For query parameters
   - `NodeQueryParamsMock`, `WindowQueryParamsMock`
   - Pattern: `QueryParamsMock.stub().build()`

**Note**: Most use cases only need FetcherMock. Use other mocks only when the repository depends on that specific infrastructure.

### Integration Test Guidelines

1. **Use LocalTestContext interface** - Define usecase, config, and infrastructure mocks
2. **Use EnvironmentMother** - Stub platform (`.withIsNode().returnsTrue()` or `.returnsFalse()`)
3. **Mock infrastructure drivers** - Only mock infrastructure (Fetcher, Cookie, etc.), never repositories
4. **Don't mock repositories** - UseCase.create() instantiates real repositories
5. **Don't mock domain models** - Domain models are never mocked
6. **Platform-specific tests** - `.node.test.ts` or `.window.test.ts`
7. **Restore mocks** - Call `.restore()` on all mocks and `EnvironmentMother.restore()`
8. **Use Given-When-Then** - Same as unit tests
9. **Verify mocks** - Call `.verify()` on mocks that support it (Fetcher, Cookie)

## StayForLong Registration

### Purpose

Every new use case MUST be registered in the `StayForLong` entry point class and its corresponding test. This ensures the use case is accessible from the public API and that the test suite detects any missing registrations.

### Step 1: Register getter in `src/index.ts`

Add a new getter in the `StayForLong` class, grouped by context:

```typescript
// src/index.ts

// 1. Import the input type (if the use case has input)
import type { CreatePurchaseIdBookingUseCaseInput } from './booking/application/CreatePurchaseIdBookingUseCase'

// 2. Import the output domain type
import type { PurchaseId } from './booking/domain/PurchaseId'

// 3. Add the getter in the correct context section
export class StayForLong extends EventEmitter {
  /* Booking */
  get CreatePurchaseIdBookingUseCase() { return this.getter<CreatePurchaseIdBookingUseCaseInput, PurchaseId>(() => import('./booking/application/CreatePurchaseIdBookingUseCase')) } // prettier-ignore
}
```

### Step 2: Add to `expectedGetters` in `test/domain/StayForLong.test.ts`

Add the use case name to the `expectedGetters` array in the correct context section:

```typescript
// test/domain/StayForLong.test.ts

const expectedGetters = [
  // ... existing getters

  // Booking
  'CreatePurchaseIdBookingUseCase',  // ← Add here, in the correct context group

  // ...
]
```

> **⚠️ IMPORTANT:** The test `should fail if new getters are added without being tested` will FAIL if you register a getter in `src/index.ts` but don't add it to `expectedGetters`. Always do both steps together.

### Checklist

- [ ] Getter registered in `src/index.ts` with correct input/output types
- [ ] Input type imported in `src/index.ts` (if use case has input)
- [ ] Output domain type imported in `src/index.ts`
- [ ] Getter name added to `expectedGetters` array in `test/domain/StayForLong.test.ts`
- [ ] Getter placed in the correct context section in both files

## Testing ListOf Models

```typescript
describe('ListOf{Entity}', () => {
  describe('create', () => {
    it('should create list from array', () => {
      const items = [
        {Entity}Mother.random().model(),
        {Entity}Mother.random().model(),
      ]

      const list = ListOf{Entity}.create(items)

      expect(list.count()).toBe(2)
      expect(list.items()).toEqual(items)
    })
  })

  describe('empty', () => {
    it('should create empty list', () => {
      const list = ListOf{Entity}.empty()

      expect(list.isEmpty()).toBe(true)
      expect(list.count()).toBe(0)
    })
  })

  describe('fromJSON', () => {
    it('should deserialize array', () => {
      const json = [
        {Entity}Mother.random().model().toJSON(),
        {Entity}Mother.random().model().toJSON(),
      ]

      const list = ListOf{Entity}.fromJSON(json)

      expect(list.count()).toBe(2)
    })
  })

  describe('domain methods', () => {
    it('should filter items', () => {
      const activeEntity = {Entity}Mother.active().model()
      const inactiveEntity = {Entity}Mother.inactive().model()
      const list = ListOf{Entity}.create([activeEntity, inactiveEntity])

      const filtered = list.filterByCondition(item => item.isActive())

      expect(filtered.count()).toBe(1)
      expect(filtered.items()[0]).toBe(activeEntity)
    })

    it('should find by id', () => {
      const entity = {Entity}Mother.random().model()
      const list = ListOf{Entity}.create([entity])

      const found = list.findById(entity.id())

      expect(found).toBe(entity)
    })
  })
})
```

## Test Organization

### File Structure

```
test/
├── domain/
│   └── {context}/
│       ├── models/
│       │   ├── {Entity}.test.ts
│       │   └── ListOf{Entity}.test.ts
│       ├── units/
│       │   └── {UseCase}.test.ts
│       └── integrations/
│           ├── {UseCase}.node.test.ts
│           └── {UseCase}.window.test.ts
└── mothers/
    └── {context}/
        └── {Entity}Mother.ts
```

## Running Tests

```bash
# All tests
npm test

# Unit tests only
npm run test:unit

# Watch mode
npm test -- --watch

# Coverage
npm run test:unit:sonar

# Specific file
npm test -- {Entity}.test.ts
```

## Coverage Requirements

From `vitest.config.ts`:

```typescript
coverage: {
  thresholds: {
    lines: 80,
    functions: 80,
    branches: 80,
    statements: 80,
  },
}
```

### Coverage Exclusions

- Cache code (with `/* v8 ignore */` comments)
- Test files
- Configuration files
- Generated files

## Common Testing Patterns

### Given-When-Then

```typescript
it<LocalTestContext>('should do something', async context => {
  // Given - Set up test data and mocks
  const entity = EntityMother.random().model()
  context.repository.findById.mockResolvedValue(entity)

  // When - Execute the code under test
  const result = await context.usecase.execute(entity.id())

  // Then - Verify the outcome
  expect(result).toEqual(entity)
  expect(context.repository.findById).toHaveBeenCalledTimes(1)
})
```

### Testing Async Operations

```typescript
it('should handle async operations', async () => {
  const promise = useCase.execute(id)

  await expect(promise).resolves.toBeDefined()
  // or
  await expect(promise).rejects.toThrow()
})
```

### Testing Error Messages

```typescript
it('should throw with specific message', async () => {
  await expect(useCase.execute(invalidInput)).rejects.toThrow('Invalid input')
})

it('should throw specific error type', async () => {
  await expect(useCase.execute(invalidInput)).rejects.toBeInstanceOf(DomainError)
})
```

## Checklist

Before finishing tests:

**Mother Objects**

- [ ] Mother object created for every model
- [ ] Mother object uses `random()` method with defaults
- [ ] Mother object returns Mother instance with `.model()` method
- [ ] Mother object has semantic methods

**Model Unit Tests**

- [ ] Model unit tests cover all methods
- [ ] Model tests use mother objects with `.random().model()`
- [ ] Tests for `create`, `createOrNull`, `fromJSON`, `toJSON`
- [ ] Tests for all business logic methods

**Use Case Unit Tests**

- [ ] Use LocalTestContext interface
- [ ] Mock all dependencies (repositories + use cases) as plain objects
- [ ] Use `beforeEach<LocalTestContext>`
- [ ] Use Given-When-Then
- [ ] Return `async () => vi.resetAllMocks()` from beforeEach
- [ ] Creation tests (optional but recommended)

**Use Case Integration Tests**

- [ ] Use LocalTestContext interface
- [ ] Use EnvironmentMother to stub platform
- [ ] Mock only infrastructure drivers (Fetcher, Cookie, etc.)
- [ ] Don't mock repositories - use UseCase.create()
- [ ] Platform-specific (.node.test.ts or .window.test.ts)
- [ ] Call .restore() on all mocks
- [ ] Call .verify() on mocks that support it
- [ ] Use Given-When-Then

**Coverage**

- [ ] Coverage meets 80% threshold
- [ ] Cache code has coverage comments

---

**Next Steps:**

- Final review? → Check [Quality Checklist](quality-checklist.md)
- Need patterns reference? → See [Common Patterns](common-patterns.md)
