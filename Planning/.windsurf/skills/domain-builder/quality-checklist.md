# Lista de Verificación de Calidad

## Overview

Use this checklist before completing any use case implementation. Every item must be verified to ensure code quality and maintainability.

## Domain Models

### Structure

- [ ] Private constructor implemented (with comma-separated parameters, NOT Props object)
- [ ] Factory method implemented (`create` with Zod validation, `createOrNull`, or `fromJSON`)
- [ ] All props are readonly
- [ ] NO Props type created (pass arguments directly to constructor)
- [ ] NO JSON type created (use `ReturnType<{Entity}['toJSON']>` instead)
- [ ] Class is immutable (no methods modify internal state)

### Methods

- [ ] Semantic methods implemented (NO getters/setters)
- [ ] Business logic methods express intent clearly
- [ ] `toJSON()` method implemented
- [ ] `toJSONOrNull()` implemented if model can be nullable
- [ ] `fromJSON()` static method implemented
- [ ] All methods have clear, business-focused names

### Validation

- [ ] Zod schema defined for validation (e.g., `{Entity}Validation`)
- [ ] `create()` method uses `{Entity}Validation.parse()` for validation
- [ ] `createOrNull` returns null for invalid data (wraps `create()` in try/catch)
- [ ] Custom error messages included in Zod schema with `[ModelName]` prefix
- [ ] Use `z.instanceof()` for aggregate validations (other domain models)
- [ ] Business rules validated in domain
- [ ] No validation logic in repositories or use cases
- [ ] Edge cases handled (empty, null, undefined)

### Null Handling

- [ ] Null pattern used correctly (`createOrNull`, `toJSONOrNull`)
- [ ] Empty methods ONLY exist for ListOf models
- [ ] No empty string or empty object patterns
- [ ] Nullable fields handled explicitly

### ListOf Models

- [ ] Generic `ListOf<T>` pattern used
- [ ] `empty()` static method implemented
- [ ] `isEmpty()` method implemented
- [ ] `count()` method implemented
- [ ] `items()` method returns readonly array
- [ ] `first()` and `last()` return T | null
- [ ] Domain-specific query methods implemented
- [ ] Serialization/deserialization implemented

### Reusability

- [ ] Checked kernel models (`src/_kernel/`)
- [ ] Checked shared models (`src/shared/domain/`)
- [ ] Checked context-specific models
- [ ] Existing models reused where possible
- [ ] No duplicate concepts created
- [ ] New value objects justified

### Backward Compatibility

- [ ] No breaking changes to existing models
- [ ] Existing method signatures unchanged
- [ ] Only additive changes made
- [ ] Existing tests still pass
- [ ] New functionality doesn't conflict with old

## Use Cases

### Structure

- [ ] Single responsibility maintained
- [ ] Dependencies injected via constructor
- [ ] Props type defined with readonly fields
- [ ] No internal state/instance variables
- [ ] Platform-agnostic (unless specific need)

### Implementation

- [ ] `execute()` method implemented
- [ ] Delegates to domain for business logic
- [ ] Orchestrates dependencies correctly
- [ ] Returns domain objects (not DTOs)
- [ ] Repository calls receive domain objects (NEVER primitives)
- [ ] Input validated early
- [ ] Clear error handling

### Caching

- [ ] `@UseCaseCache` decorator added (if caching needed)
- [ ] `asides()` method implemented (if cached)
- [ ] Dependencies for cache key included
- [ ] Coverage comments added: `/* v8 ignore start -- @preserve */`
- [ ] Coverage comments closed: `/* v8 ignore stop -- @preserve */`

### Error Handling

- [ ] Uses `DomainError` from kernel
- [ ] Appropriate `ErrorsCode` used
- [ ] Validation errors throw early
- [ ] Domain errors propagate naturally
- [ ] Unexpected errors wrapped appropriately

### Domain Events

- [ ] No manual event emission (automatic)
- [ ] No event-specific code in use case
- [ ] Events work through infrastructure

## Repositories

### Interface (Domain Layer)

- [ ] Interface defined in domain layer
- [ ] Methods return domain objects
- [ ] Parameters use domain types (ID, not string)
- [ ] Async operations return Promises
- [ ] Nullable results specified (`T | null`)
- [ ] Interface properly exported

### Implementation (Infrastructure Layer)

- [ ] Implementation in infrastructure layer
- [ ] Implements domain interface
- [ ] Dependencies injected (Fetcher, Cookie, etc.)
- [ ] Returns domain objects (not DTOs)
- [ ] Transforms external data to domain
- [ ] No domain logic in repository

### HTTP Repositories

- [ ] Zod schemas defined
- [ ] Schemas in correct location (`schemas/{endpoint}/`)
- [ ] Schema types exported (`z.infer<>`)
- [ ] `.parse()` used (not `.safeParse()`)
- [ ] Proper error handling
- [ ] Not found returns null
- [ ] Other errors propagate

### Other Repository Types

- [ ] Cookie: Proper cookie handling
- [ ] QueryParam: URL parsing correct
- [ ] Domain: Domain detection working
- [ ] Navigator: Browser API usage correct
- [ ] DataSource: Static data loading proper

### Error Handling

- [ ] Not found scenarios return null
- [ ] Network errors throw DomainError
- [ ] Validation errors throw DomainError
- [ ] Unexpected errors handled
- [ ] Error messages descriptive

### Platform Compatibility

- [ ] Platform-specific if needed (node/window)
- [ ] Correct factory pattern used
- [ ] Browser APIs guarded
- [ ] Node APIs guarded

## Testing

### Mother Objects

- [ ] Mother object created for every model
- [ ] Located in `test/mothers/{context}/`
- [ ] Uses faker for random data
- [ ] Implements `create()` with overrides
- [ ] Semantic factory methods implemented
- [ ] Returns valid instances (uses `!` after createOrNull)
- [ ] Supports ListOf creation
- [ ] Edge case methods provided

### Model Unit Tests

- [ ] Test file in `test/domain/{context}/models/`
- [ ] Tests `createOrNull` success cases
- [ ] Tests `createOrNull` null returns
- [ ] Tests `fromJSON` deserialization
- [ ] Tests `toJSON` serialization
- [ ] Tests round-trip (toJSON → fromJSON)
- [ ] Tests all semantic methods
- [ ] Tests all business logic methods
- [ ] Tests edge cases
- [ ] Uses mother objects for test data

### Use Case Unit Tests

- [ ] Test file in `test/domain/{context}/units/`
- [ ] All dependencies mocked (repositories, use cases)
- [ ] Tests happy path
- [ ] Tests error scenarios
- [ ] Tests validation
- [ ] Tests repository called correctly
- [ ] Tests call count verification
- [ ] Uses mother objects for test data
- [ ] AAA pattern (Arrange-Act-Assert)

### Use Case Integration Tests

- [ ] Test file in `test/domain/{context}/integrations/`
- [ ] Platform suffix (`.node.test.ts` or `.window.test.ts`)
- [ ] Uses DomainBuilder for real domain
- [ ] Real repositories instantiated
- [ ] Domain not mocked
- [ ] Infrastructure mocked at fetcher level
- [ ] Tests complete workflows
- [ ] Tests error scenarios
- [ ] Tests real data flow

### Test Coverage

- [ ] Model tests cover 100% of model
- [ ] Use case unit tests cover business logic
- [ ] Integration tests cover real scenarios
- [ ] Coverage meets 80% threshold
- [ ] Cache code has coverage comments
- [ ] No untested code paths

## Naming Conventions

### Use Cases

- [ ] Follows pattern: `{Action}{Entity}{Context}UseCase`
- [ ] Action is a verb (Get, Create, Update, etc.)
- [ ] Entity is singular
- [ ] Context matches bounded context
- [ ] File name matches class name

### Models

- [ ] Entity names are singular
- [ ] No plural forms
- [ ] Clear, business-focused names
- [ ] Consistent with domain language

### ListOf Models

- [ ] Follows pattern: `ListOf{Entity}`
- [ ] Entity in singular form
- [ ] Clear what it's a list of

### Repositories

- [ ] Interface: `{Context}Repository`
- [ ] Implementation: `{Type}{Context}Repository`
- [ ] Type clearly indicates source (HTTP, Cookie, etc.)
- [ ] Context matches bounded context

### Mother Objects

- [ ] Follows pattern: `{Entity}Mother`
- [ ] Singular entity name
- [ ] Clear what entity it creates

### Test Files

- [ ] Models: `{Entity}.test.ts`
- [ ] Use Case Units: `{UseCase}.test.ts`
- [ ] Use Case Integrations: `{UseCase}.{platform}.test.ts`
- [ ] Descriptive describe blocks

## File Organization

### Source Files

- [ ] Models in `src/{context}/domain/`
- [ ] Use cases in `src/{context}/application/`
- [ ] Repositories in `src/{context}/infrastructure/`
- [ ] Schemas in `infrastructure/HTTP{Context}Repository/schemas/`

### Test Files

- [ ] Mother objects in `test/mothers/{context}/`
- [ ] Model tests in `test/domain/{context}/models/`
- [ ] Unit tests in `test/domain/{context}/units/`
- [ ] Integration tests in `test/domain/{context}/integrations/`

### Imports

- [ ] Relative imports correct
- [ ] No circular dependencies
- [ ] Types imported as `type`
- [ ] Barrel exports used appropriately

## Documentation

### Code Comments

- [ ] Complex business logic commented
- [ ] Non-obvious decisions explained
- [ ] No redundant comments (code is self-documenting)
- [ ] TODO/FIXME removed or tracked

### Types

- [ ] All parameters typed
- [ ] All return types specified
- [ ] No `any` types (unless absolutely necessary)
- [ ] Generic types used appropriately

### JSDoc (Optional)

- [ ] Public APIs documented if complex
- [ ] Examples provided for non-obvious usage
- [ ] Parameter descriptions clear

## Performance

### Domain

- [ ] No N+1 query patterns
- [ ] Appropriate use of bulk operations
- [ ] Lazy loading where appropriate
- [ ] No unnecessary object creation

### Caching

- [ ] Cache used for expensive operations
- [ ] Cache key dependencies correct
- [ ] Cache invalidation considered
- [ ] No over-caching

### Lists

- [ ] Pagination considered for large lists
- [ ] Filtering done efficiently
- [ ] No full list loading when paginated

## Security

### Validation

- [ ] All external input validated
- [ ] Validation at domain boundary
- [ ] No SQL injection vectors
- [ ] No XSS vectors

### Data Handling

- [ ] Sensitive data not logged
- [ ] Passwords never stored plain
- [ ] Personal data handled appropriately
- [ ] No hardcoded secrets

## StayForLong Registration

- [ ] Getter registered in `src/index.ts` with correct input/output types
- [ ] Input type imported in `src/index.ts` (if use case has input)
- [ ] Output domain type imported in `src/index.ts`
- [ ] Getter name added to `expectedGetters` array in `test/domain/StayForLong.test.ts`
- [ ] Getter placed in the correct context section in both files

## Final Verification

### Build & Test

- [ ] TypeScript compiles without errors
- [ ] All tests pass
- [ ] Coverage threshold met
- [ ] Linter passes
- [ ] No console.log statements

### Integration

- [ ] Works with existing code
- [ ] No breaking changes
- [ ] Follows project patterns
- [ ] Ready for code review

### Review Questions

- [ ] Is this the simplest solution?
- [ ] Is the code self-documenting?
- [ ] Would another developer understand this?
- [ ] Have I considered edge cases?
- [ ] Is this maintainable long-term?

## Sign-Off

Before marking complete:

```
✅ All domain model checklist items verified
✅ All use case checklist items verified
✅ All repository checklist items verified
✅ All testing checklist items verified
✅ All naming convention items verified
✅ All organization items verified
✅ Build and tests pass
✅ Ready for review
```

---

**Remember:**

- Every checkbox matters for maintainability
- Shortcuts today = technical debt tomorrow
- Quality is not negotiable
- Your future self will thank you
