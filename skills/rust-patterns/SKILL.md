---
name: rust-patterns
description: Rust idioms, patterns, and gotchas to write better Rust code
allowed-tools:
  - Read
  - Grep
  - Edit
  - Write
---

# Rust Patterns

Practical patterns and pitfalls for writing idiomatic, testable Rust.

## Tooling

| Context | Do | Why |
|---------|-----|-----|
| Running cargo commands | Read `.cargo/config.toml` for aliases | Projects often define custom aliases for common workflows |
| CI pipeline | `fmt --check` → `clippy -D warnings` → `nextest run` → `doc` | Standard pre-commit checks in order |
| Bypassing clippy lint | `#[expect(lint, reason = "...")]` or comment above `#[allow(...)]` | Documents why the lint doesn't apply; reviewable justification |
| Running tests | Check for `.config/nextest.toml`; use `cargo nextest run` if present | Faster parallel execution than `cargo test` |

## Error Handling

| Instead of | Use | Why |
|------------|-----|-----|
| `.unwrap()` | `.expect("reason")` or `?` with context | Panics hide bugs; expect documents assumptions; `?` propagates properly |
| Single error message | `MessagePair { external, internal }` | Prevents leaking sensitive info to clients; keeps detail for logs |
| Library errors as strings | `thiserror` enums for domain errors | Pattern matching for retry logic, client feedback |
| Bare `?` propagation | `.context()` / `.with_context(|| format!(...))` | Adds high-level context to low-level errors |
| `Result<T, Error>` everywhere | Type aliases like `CreateResult<T>`, `DeleteResult` | Self-documenting API signatures |
| Retrying all errors uniformly | Classify: `BackoffError::Transient(e)` vs `Permanent(e)` | Transient = backoff retry, permanent = fail fast |
| Monolithic error enum | Nested `Result<Result<T, LocalErr>, FatalErr>` | Separates recoverable failures from system-halting errors |

## Async & Tokio

| Pattern | Example | Gotcha |
|---------|---------|--------|
| Explicit runtime ownership | Pass `Handle` explicitly; `#[tokio::main]` only at entry point | Don't assume runtime exists; don't spawn from arbitrary code |
| Select-based event loop | `select!` returns typed `Action` enum; `loop { apply(select().await) }` | Keep select branches thin; complex logic inside can be cancelled |
| Prevent futurelock | Use channels or `tokio::spawn` for lock-holding futures in `select!` | `select!` stops polling losers; stopped future holding lock = deadlock |
| Channel selection | `mpsc` bounded (backpressure), `oneshot` (request-reply), `watch` (broadcast latest) | Avoid unbounded `mpsc` except sync-to-async bridge |

## Type Safety

| Pattern | Instead of | Use | Why |
|---------|------------|-----|-----|
| Newtype wrappers | `fn process(job_id: u64, session_id: Uuid)` | `struct JobId(pub u64);` + `fn process(job: JobId, session: SessionId)` | Compiler prevents mixing up IDs of same underlying type |
| Validated newtypes | `pub` fields with invariants | Private fields + `new() -> Result` + custom `Deserialize` | Invariants enforced at construction; can't bypass via deserialization |
| Enum state machines | Flat struct with `Option` fields | Enum variants with embedded state-specific data | Invalid states unrepresentable; each state knows its data |
| Validated transitions | `set_state(new)` with no checks | `assert!(valid_transition(old, new))` | Fail fast on invalid transitions; bugs don't propagate |
| `Cow` for flexibility | `String` or `&'static str` separately | `Cow<'static, str>` | Accepts both static and owned; avoids allocation for constants |
| `Arc` for sharing | `Rc` or cloning data | `Arc<T>` | Clone+Send shared ownership across threads |
| `Box` for dyn | Stack allocation of trait objects | `Box<dyn Trait>` | Single-owner dynamic dispatch; heap when size unknown |
| `Arc::clone` | `arc.clone()` | `Arc::clone(&arc)` | Makes intent explicit: cheap ref count bump, not deep clone |

## Trait Design

| Guideline | Example | Why |
|-----------|---------|-----|
| Dependency abstraction | `trait Clock`, `trait Network` with real + sim impls | Swap behavior for deterministic tests; enables simulation without mocks |
| Type witness traits | `trait SagaType { type Ctx; type Params; }` instead of `<Ctx, Params, Output, Error>` | Bundle related types via associated types; avoids parameter explosion |
| Consistent API derives | `#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]` | Predictable capabilities for API types |
| Adjacent enum tagging | `#[serde(tag = "type", content = "value")]` or `#[serde(tag = "type")]` | Clear JSON: `{"type": "V4", "value": {...}}` vs flat `{"type": "Create", "name": "foo"}` |

## Testing & Structure

| Pattern | Description | Benefit |
|---------|-------------|---------|
| Short functions (10-30 lines) | Decompose into well-named helpers when logic grows | Readable, testable, easier to reason about |
| Semantic suffixes | `_impl` (trait delegation), `_inner` (non-generic core), `for_` (factory), `from_`/`to_` (conversion) | Clear intent; `_inner` enables manual outlining for faster compiles |
| Closures vs functions | Closures for one-off logic; named functions for reuse or testing | `.map_err(ActionError::action_failed)` over long inline closures |
| OpContext/RequestContext | Bundle `log`, `authn`, `authz` into single context with `authorize()`, `child()` | Consistent logging, auth, tracing; avoids parameter explosion |
| Simulated implementations | Full alternative impls (e.g., `sp-sim/`) instead of mock frameworks | Exercises real code paths; catches integration bugs mocks miss |
| `#[instrument]` macro | Add `#[tracing::instrument]` to functions when using tracing | Automatic span creation with function args; simplifies observability |
| Sans-IO | Logic accepts/returns bytes; caller handles I/O | Testable, framework-agnostic; see [sans-io.readthedocs.io](https://sans-io.readthedocs.io) |

## Database Patterns

| Pattern | Description | Why |
|---------|-------------|-----|
| Soft deletes | `time_deleted TIMESTAMPTZ` column (NULL = live) | Audit trails + name reuse after deletion |
| Keyset pagination | `ResultsPage { next_page: Option<String>, items }` + `WHERE name > last_seen` | Scales with data size; OFFSET scans skipped rows |

## Project Organization

| Pattern | Description | Benefit |
|---------|-------------|---------|
| Workspace by change frequency | Separate crates for stable (types, utils) vs volatile (app logic) code | Incremental builds; stable crates rarely recompile |
| Re-export from crate root | `pub use error::HttpError;` in lib.rs | Users write `use crate::HttpError` not `use crate::error::HttpError` |

## Unsafe Code

| Rule | Example | Why |
|------|---------|-----|
| SAFETY comments | `// SAFETY: pointer is valid because...` before every `unsafe` block | Documents invariants; required by clippy `undocumented_unsafe_blocks` |
