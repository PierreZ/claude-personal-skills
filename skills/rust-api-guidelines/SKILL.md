---
name: rust-api-guidelines
description: Idiomatic Rust API design, naming, traits, error handling, and type safety.
  Use when writing or reviewing Rust code, designing library APIs, or implementing
  traits and error types.
allowed-tools: Read, Grep, Edit, Write
---

# Rust API Guidelines

Apply these rules when writing or reviewing Rust code. See [REFERENCE.md](REFERENCE.md) for full details.

## Top LLM Violations

| # | Guideline | Wrong | Right |
|---|-----------|-------|-------|
| 1 | C-COMMON-TRAITS | No derives on public types | `#[derive(Debug, Clone, PartialEq)]` minimum |
| 2 | C-QUESTION-MARK | `.unwrap()` in lib/example code | `?` with `Result` return types |
| 3 | C-GENERIC | `fn f(v: &Vec<T>)`, `fn f(s: &String)` | `fn f(v: &[T])`, `fn f(s: &str)` |
| 4 | C-GETTER | `fn get_name(&self) -> &str` | `fn name(&self) -> &str` |
| 5 | C-GOOD-ERR | `Result<T, ()>`, `Result<T, String>` | Domain error enum with `thiserror` |
| 6 | C-CONV | Wrong conversion prefix | See Conversion Naming below |
| 7 | C-DEREF | `Deref` on wrapper types | Only for smart pointers (`Box`, `Arc`) |
| 8 | C-STRUCT-BOUNDS | `struct Foo<T: Debug + Clone>` | `struct Foo<T>` — bounds on `impl` only |
| 9 | C-CALLER-CONTROL | Hidden `.clone()`, wrong ownership | Take owned when you need it, borrow when you don't |
| 10 | C-STRUCT-PRIVATE | All `pub` fields on library structs | Private fields + `new()` + getters |
| 11 | C-FAILURE | No error docs | `# Errors`, `# Panics`, `# Safety` sections |
| 12 | C-BUILDER | Struct with 5+ pub config fields | Builder: `FooBuilder::new().bar(1).build()` |
| 13 | C-NEWTYPE | `user_id: u64`, `timeout: u64` | `struct UserId(u64)`, `struct Timeout(Duration)` |
| 14 | C-CUSTOM-TYPE | `fn connect(use_tls: bool)` | `enum TlsMode { Enabled, Disabled }` |
| 15 | C-NEWTYPE-HIDE | `-> Enumerate<Skip<Map<...>>>` | `-> impl Iterator<Item = T>` or newtype |

## Conversion Naming

| Prefix | Cost | Ownership | Example |
|--------|------|-----------|---------|
| `as_` | Free | `&self -> &T` | `fn as_str(&self) -> &str` |
| `to_` | Expensive | `&self -> T` (allocates) | `fn to_string(&self) -> String` |
| `into_` | Variable | `self -> T` (consumes) | `fn into_inner(self) -> T` |
| `from_` | Variable | `T -> Self` (constructs) | `fn from_bytes(v: Vec<u8>) -> Self` |

## Trait Checklist

| Type category | Always derive | When applicable |
|---------------|---------------|-----------------|
| Public structs | `Debug`, `Clone` | `Default`, `PartialEq`, `Eq`, `Hash` |
| Error types | `Debug` + manual `Display` + `Error` | `Clone`, must be `Send + Sync + 'static` |
| ID / newtype | `Debug`, `Clone`, `Copy`, `PartialEq`, `Eq`, `Hash` | `Display`, `Ord` |
| Config / options | `Debug`, `Clone`, `Default` | `PartialEq` |
| API boundary types | `Debug`, `Clone`, `PartialEq`, `Serialize`, `Deserialize` | `JsonSchema` |

## Generic Parameters

| Instead of | Accept | Why |
|------------|--------|-----|
| `&Vec<T>` | `&[T]` | Works with arrays, slices, Vec |
| `&String` | `&str` | Works with literals, String, Cow |
| `&Box<T>` | `&T` | Box is transparent for borrows |
| `String` param | `impl Into<String>` | Accepts `&str` without caller `.to_string()` |
| `PathBuf` param | `impl AsRef<Path>` | Accepts `&str`, `&Path`, `PathBuf` |
| `Vec<T>` param | `impl IntoIterator<Item = T>` | Accepts arrays, slices, iterators |

## Type Design

- **Newtype IDs**: `#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq, Serialize, Deserialize)] #[serde(transparent)] pub struct JobId(pub Uuid);`
- **Enum state machines**: States as enum variants with embedded data. No struct-with-booleans/optionals.
- **Validated newtypes**: Private fields + `fn new(...) -> Result<Self, Error>` + custom `Deserialize` that calls `new`.

## Error Handling

- Define domain error enums with `#[derive(Debug, thiserror::Error)]`, specific variants with context fields.
- With `#[source]`, don't embed `{err}` in `#[error("...")]` — the error chain formatter appends it. Embedding causes double-printing.

## Functions

- Target 10-30 lines per function. Decompose longer functions into well-named helpers.
- Value composition and testability: each function does one thing, returns a value, is independently testable.

## Async / Tokio

**Apply only to applications already using tokio. Libraries must not embed a runtime.**

| Pattern | Rule |
|---------|------|
| Event loop | Single `select!` returning typed action enum, clean `loop { let action = select().await; apply(action).await; }` |
| Futurelock | Never hold locks across `select!` branches. Use channels + `spawn` instead. |
| Cancel-safety | `scopeguard::guard()` to restore invariants on drop. Defuse with `ScopeGuard::into_inner()` on success. |
| Channels | Bounded `mpsc` (backpressure), `oneshot` (request-reply), `watch` (broadcast/cancel). Avoid unbounded mpsc. |
| Lock scope | Clone data out of mutex before `.await`. Never hold `MutexGuard` across await points. |

## Clippy

- Never add `#[allow(clippy::...)]` to suppress a Clippy warning. Fix the underlying issue instead.

## Testing

- Write tests before implementation. Use `#[cfg(test)] mod tests` in the same file.
- Wrap external dependencies behind traits for testability. **Ask the developer** about the scope: IO boundaries only, all external deps, or full ports-and-adapters.

## Full Reference

- [Rust API Guidelines](https://rust-lang.github.io/api-guidelines) | [Checklist](https://rust-lang.github.io/api-guidelines/checklist.html)
- [REFERENCE.md](REFERENCE.md) — all 54 guidelines + pattern details
