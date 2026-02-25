# Rust API Guidelines — Full Reference

All 54 guidelines from [rust-lang.github.io/api-guidelines](https://rust-lang.github.io/api-guidelines), plus production patterns.

---

## Naming (7 guidelines)

| Code | Rule | LLM risk |
|------|------|----------|
| C-CASE | `UpperCamelCase` types/traits, `snake_case` functions/methods, `SCREAMING_SNAKE` constants. Acronyms are one word: `Uuid` not `UUID`. | HIGH |
| C-CONV | `as_` (free borrow→borrow), `to_` (expensive borrow→owned), `into_` (consumes self), `from_` (constructs). | VERY HIGH |
| C-GETTER | No `get_` prefix. Getter for field `name` is `fn name()` and `fn name_mut()`. `get` reserved for `Option`-returning access like `Vec::get`. | VERY HIGH |
| C-ITER | Collections provide `iter()`, `iter_mut()`, `into_iter()`. Not `items()` or `elements()`. | HIGH |
| C-ITER-TY | Iterator type name matches method: `into_iter()` → `IntoIter`, `keys()` → `Keys`. | MEDIUM |
| C-FEATURE | Feature names: `serde` not `use-serde`. Features must be additive, no `no-std`. | MEDIUM |
| C-WORD-ORDER | Verb-object-error: `ParseIntError` not `IntParseError`. Consistency within crate. | MEDIUM |

## Interoperability (8 guidelines)

| Code | Rule | LLM risk |
|------|------|----------|
| C-COMMON-TRAITS | Eagerly derive: `Debug` (always), `Clone`, `PartialEq`, `Eq`, `Hash`, `Ord`, `Default`. Orphan rule prevents adding later. | VERY HIGH |
| C-CONV-TRAITS | Implement `From<T>` not `Into<T>`. `TryFrom<T>` for fallible. `AsRef<T>`/`AsMut<T>` for cheap ref conversions. | HIGH |
| C-COLLECT | Collections implement `FromIterator` (enables `.collect()`) and `Extend`. | MEDIUM |
| C-SERDE | Feature-gate behind `"serde"` (not `"with-serde"`). Use `#[cfg_attr(feature = "serde", derive(Serialize, Deserialize))]`. | HIGH |
| C-SEND-SYNC | Maintain `Send + Sync` auto-traits. Test: `fn assert_send<T: Send>() {} assert_send::<MyType>();` | MEDIUM |
| C-GOOD-ERR | Errors: implement `Error` + `Display` (lowercase, no trailing period) + `Send + Sync + 'static`. Never `()` or `String`. | VERY HIGH |
| C-NUM-FMT | Bitwise types implement `UpperHex`, `LowerHex`, `Octal`, `Binary`. | LOW |
| C-RW-VALUE | Accept `R: Read` by value, not `&mut R`. `&mut R` itself impls `Read`. | MEDIUM |

## Macros (5 guidelines)

| Code | Rule | LLM risk |
|------|------|----------|
| C-EVOCATIVE | Input syntax mirrors Rust: use `struct` keyword, semicolons, braces. | MEDIUM |
| C-MACRO-ATTR | Forward `#[derive]`, `#[cfg]`, `#[allow]`, `#[doc]` attributes to generated items. | MEDIUM |
| C-ANYWHERE | Work at module scope AND inside function bodies. | MEDIUM |
| C-MACRO-VIS | Accept visibility specifiers. Private by default, `pub` when specified. | MEDIUM |
| C-MACRO-TY | `$t:ty` must work with primitives, paths, generics. Don't create internal `mod`. | MEDIUM |

## Documentation (7 guidelines)

| Code | Rule | LLM risk |
|------|------|----------|
| C-CRATE-DOC | `//!` on `lib.rs`: overview, getting-started, links to key items. | HIGH |
| C-EXAMPLE | Every public item has `/// # Examples`. Show purpose, not just calling syntax. | HIGH |
| C-QUESTION-MARK | Examples use `?` in hidden `fn main() -> Result<>`. Never `.unwrap()`. | CRITICAL |
| C-FAILURE | `# Errors` (any `Result` fn), `# Panics` (any panicking fn), `# Safety` (any `unsafe fn`). | CRITICAL |
| C-LINK | Intra-doc links: `` [`Type`] ``, `` [`method`](Self::method) ``. | MEDIUM |
| C-METADATA | `Cargo.toml`: authors, description, license, repository, keywords, categories. | MEDIUM |
| C-HIDDEN | `#[doc(hidden)]` for plumbing impls. `pub(crate)` for internal helpers. | HIGH |

## Predictability (7 guidelines)

| Code | Rule | LLM risk |
|------|------|----------|
| C-SMART-PTR | Smart pointers use associated functions (`Box::into_raw(b)`), not methods. | MEDIUM |
| C-CONV-SPECIFIC | Place conversions on the more specific type (stronger invariants). | MEDIUM |
| C-METHOD | Prefer methods on `impl Foo` over free functions. Discoverable, autoborrowing. | HIGH |
| C-NO-OUT | Return tuples/structs, not out-parameters. Exception: buffer reuse (`Read::read`). | HIGH |
| C-OVERLOAD | Operator overloads match mathematical semantics. | MEDIUM |
| C-DEREF | `Deref` only for smart pointers. NOT for wrapper "inheritance". | CRITICAL |
| C-CTOR | `Type::new()` primary constructor. `File::open`, `TcpStream::connect` for IO. Match `Default` behavior. | HIGH |

## Flexibility (4 guidelines)

| Code | Rule | LLM risk |
|------|------|----------|
| C-INTERMEDIATE | Return rich types with intermediate data. `binary_search` → `Result<usize, usize>`. | HIGH |
| C-CALLER-CONTROL | Don't clone internally when you could take ownership. Don't own when you only borrow. | CRITICAL |
| C-GENERIC | Accept broadest type: `&[T]` not `&Vec<T>`, `impl AsRef<Path>` not `&Path`. | CRITICAL |
| C-OBJECT | Plan for `dyn Trait`: avoid generic methods and `Self` outside receiver. | MEDIUM |

## Type Safety (4 guidelines)

| Code | Rule | LLM risk |
|------|------|----------|
| C-NEWTYPE | `struct Miles(f64)` over raw `f64`. Prevents unit confusion at compile time. | VERY HIGH |
| C-CUSTOM-TYPE | `enum Size { Small, Large }` over `bool`. Self-documenting and extensible. | VERY HIGH |
| C-BITFLAG | Use `bitflags` crate for combinable flags, not enums or raw integers. | HIGH |
| C-BUILDER | Non-consuming builders preferred: methods take `&mut self`, terminal takes `&self`. | VERY HIGH |

## Dependability (3 guidelines)

| Code | Rule | LLM risk |
|------|------|----------|
| C-VALIDATE | Prefer static types > `Result`/`Option` > `debug_assert!` > `_unchecked` variants. | VERY HIGH |
| C-DTOR-FAIL | `Drop::drop` must not panic. Provide separate `close() -> Result` for fallible cleanup. | HIGH |
| C-DTOR-BLOCK | Destructors must not block. Provide explicit `close()`/`shutdown()`/`flush()`. | HIGH |

## Debuggability (2 guidelines)

| Code | Rule | LLM risk |
|------|------|----------|
| C-DEBUG | Every public type implements `Debug`, typically via `#[derive(Debug)]`. | VERY HIGH |
| C-DEBUG-NONEMPTY | `Debug` output is never empty. Custom impls must produce at least a type name. | HIGH |

## Future Proofing (4 guidelines)

| Code | Rule | LLM risk |
|------|------|----------|
| C-SEALED | Traits not for external impl: private `Sealed` supertrait. | HIGH |
| C-STRUCT-PRIVATE | Default private fields + getters. Public fields are permanent API commitment. | VERY HIGH |
| C-NEWTYPE-HIDE | Wrap complex types: `-> impl Iterator<Item = T>` or newtype, not `Enumerate<Skip<Map<...>>>`. | VERY HIGH |
| C-STRUCT-BOUNDS | Never `struct Foo<T: Clone>`. Bounds on `impl` blocks only. Adding derives becomes breaking change. | VERY HIGH |

## Necessities (2 guidelines)

| Code | Rule | LLM risk |
|------|------|----------|
| C-STABLE | Stable crates (>=1.0) must not expose pre-1.0 dependency types in public API. | MEDIUM |
| C-PERMISSIVE | Dual-license `MIT OR Apache-2.0`. Check transitive deps. | LOW |

---

## Production Patterns

### Newtype Wrappers for IDs

```rust
// DO: Distinct types prevent parameter mix-ups
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq, Serialize, Deserialize)]
#[serde(transparent)]
pub struct JobId(pub Uuid);

fn process(job: JobId, session: SessionId) { ... }  // Can't swap

// DON'T: Raw types
fn process(job_id: Uuid, session_id: Uuid) { ... }  // Easy to confuse
```

### Validated Newtypes

```rust
// DO: Private fields + validated constructor + custom Deserialize
pub struct PortRange {
    first: u16,  // private
    last: u16,
}

impl PortRange {
    pub fn new(first: u16, last: u16) -> Result<Self, Error> {
        if first > last { return Err(Error::InvalidRange); }
        Ok(Self { first, last })
    }
}

impl<'de> Deserialize<'de> for PortRange {
    fn deserialize<D: Deserializer<'de>>(d: D) -> Result<Self, D::Error> {
        let raw = RawPortRange::deserialize(d)?;
        Self::new(raw.first, raw.last).map_err(D::Error::custom)
    }
}

// DON'T: Public fields bypass validation
pub struct PortRange { pub first: u16, pub last: u16 }
```

### Enum State Machines

```rust
// DO: States as variants with embedded data
pub enum RepairState {
    Closing { close_job: PendingJob, repair_job: PendingJob },
    Repairing { repair_job: PendingJob },
    Reopening { reopen_job: PendingJob },
}

impl RepairState {
    fn active_job(&self) -> &PendingJob {
        match self {
            Self::Closing { close_job, .. } => close_job,
            Self::Repairing { repair_job, .. } => repair_job,
            Self::Reopening { reopen_job, .. } => reopen_job,
        }
    }
}

// DON'T: Flat struct with optionals — allows invalid combinations
pub struct RepairState {
    closing: bool,
    close_job: Option<PendingJob>,  // closing=false but Some?
    repair_job: Option<PendingJob>,
}
```

### Domain Error Enums

```rust
// DO: Specific variants with context
#[derive(Debug, thiserror::Error)]
pub enum StorageError {
    #[error("block size mismatch")]
    BlockSizeMismatch,

    #[error("missing context for block {block} in extent {extent}")]
    MissingContext { block: u64, extent: u32 },

    #[error("IO failed")]       // DON'T put {source} here — double-prints
    Io {
        #[source]               // chain formatter appends source automatically
        source: io::Error,
    },
}

// Enables intelligent handling
match error {
    StorageError::BlockSizeMismatch => return Err(ClientError::BadRequest),
    StorageError::Io { .. } => retry_with_backoff(),
    _ => ...,
}

// DON'T: Stringly-typed errors
fn do_thing() -> Result<(), String> { ... }
```

### Select-Based Event Loop (tokio applications only)

```rust
// DO: Single select returning typed action, clean main loop
async fn select(&mut self) -> Action {
    tokio::select! {
        d = self.downstream.recv() => Action::Downstream(d),
        g = self.guest.recv() => Action::Guest(g),
        _ = sleep_until(self.deadline) => Action::Tick,
    }
}

loop {
    let action = self.select().await;
    self.apply(action).await;
}

// DON'T: Complex logic inside select branches (cancellation-unsafe)
```

### Futurelock Prevention (tokio applications only)

```rust
// DANGEROUS: Lock held across select — if branch cancelled, deadlock
let guard = mutex.lock().await;
tokio::select! {
    _ = future1 => { }       // holds lock...
    _ = sleep(500ms) => {
        mutex.lock().await;   // DEADLOCK
    }
};

// SAFE: Clone data out, release lock before await
let data = {
    let guard = mutex.lock().await;
    guard.data.clone()
};  // lock released
process(data).await;

// SAFE: Spawn to keep future polling independently
let task = tokio::spawn(future_holding_lock);
tokio::select! { _ = &mut task => { }, _ = sleep(500ms) => { } };
```

### scopeguard for Cancel-Safety (tokio applications only)

```rust
use scopeguard::{guard, ScopeGuard};

async fn handle(state: &Mutex<State>) -> Result<(), Error> {
    // Guard runs cleanup on drop (including cancellation)
    let on_cancel = guard((), |_| {
        warn!(log, "request cancelled");
    });

    do_work().await?;

    // Success: defuse the guard
    let _ = ScopeGuard::into_inner(on_cancel);
    Ok(())
}
```

### Channel Selection (tokio applications only)

| Channel | Use case | Backpressure |
|---------|----------|--------------|
| `mpsc` (bounded) | Multi-producer work queues | `try_send` returns `Full` |
| `mpsc` (unbounded) | Sync-to-async bridge only | None — avoid in general |
| `oneshot` | Request-reply | N/A |
| `watch` | Broadcast latest value, cancellation signals | Latest value only |

---

## Trait Implementation Checklist

| Trait | Derive? | When |
|-------|---------|------|
| `Debug` | Yes | ALL public types, no exceptions |
| `Clone` | Yes | Types that can be duplicated |
| `Copy` | Yes | Small stack-only types (implies `Clone`) |
| `PartialEq` | Yes | Comparable types |
| `Eq` | Yes | Add when `PartialEq` present and no `f32`/`f64` fields |
| `Ord` + `PartialOrd` | Yes | Orderable types (requires `Eq`) |
| `Hash` | Yes | HashMap/HashSet keys (must be consistent with `Eq`) |
| `Default` | Yes | Types with meaningful default. Also provide `new()` matching it. |
| `Display` | Manual | User-facing output. Separate from `Debug`. |
| `Error` | Manual | Error types. Requires `Debug + Display`. Use `source()` for chaining. |
| `From<T>` | Manual | Infallible conversions. Never implement `Into` directly. |
| `TryFrom<T>` | Manual | Fallible conversions. |
| `Serialize`/`Deserialize` | Yes (serde) | Data interchange. Feature-gate behind `"serde"`. |
| `Send` / `Sync` | Auto | Verify with compile-time assert for types with raw pointers. |

## Conversion Naming — Expanded

| Signature pattern | Prefix | Cost | Ownership |
|-------------------|--------|------|-----------|
| `&self -> &T` | `as_` | O(1), no alloc | Borrowed → Borrowed |
| `&mut self -> &mut T` | `as_mut_` | O(1) | Borrowed → Borrowed |
| `&self -> T` (allocates) | `to_` | O(n), allocs | Borrowed → Owned |
| `&self -> Cow<T>` | `to_` | O(1) or O(n) | Borrowed → Maybe-owned |
| `self -> T` (consumes) | `into_` | Varies | Owned → Owned (non-Copy) |
| `T -> Self` (constructs) | `from_` | Varies | Owned → Owned |

Wrapping a single value: `into_inner(self) -> T`.
Mut in return type goes in method name: `as_mut_slice` not `as_slice_mut`.
