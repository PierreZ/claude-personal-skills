---
name: sim-boundaries
description: Sim-driven testing — replace mocks and testcontainers with in-memory
  trait-based fakes at the right boundary. Apply when writing or reviewing tests
  for code with external dependencies (databases, brokers, clocks, network),
  picking the trait boundary to fake at, or exercising partial failures, stale
  reads, silent drops, hangs, or clock skew.
allowed-tools: Read, Grep, Edit, Write
---

# Sim Boundaries

Production fails partially. Mocks couple to call shape; testcontainers are binary
up/down. Fakes — in-memory implementations of dependency traits — run in
microseconds and inject arbitrary failure modes.

## The Principle

> **Pick the level where the fake can express every failure mode the caller cares about without simulating the level below.**

- *Express every failure mode the caller cares about* — if your code branches on
  stale reads, the fake must produce stale reads.
- *Without simulating the level below* — don't fake Postgres semantics, packet
  fragmentation, or Kafka rebalance. You don't own them; the caller doesn't care.

Mocks fail this from above. Testcontainers fail it from below.

## Locating the Boundary

The Principle is a verdict, not a procedure. Two complementary entry points
converge on the seam:

- **Caller-driven.** Read the calling code. Enumerate every failure mode it
  branches on — timeout, partial write, stale read, broken connection,
  retry-able vs fatal. This set is the **floor**.
- **Interaction-driven.** Inventory fallible interactions: OS primitives
  (clock, RNG, sockets, files, signals), dependencies (DB, broker, RPC peer),
  in-process boundaries (threads, channels). See *Common Seams* below. Each
  is a candidate seam.

If a fallible interaction has no caller branch, that's a gap — the code will
crash, hang, or silently corrupt on that failure. Either add the branch or
flag the bug.

Then:

1. **Walk up the stack.** Find the highest level that still expresses every
   floor item. When one becomes inexpressible, you've gone one level too far
   — drop back.
2. **Cut at code ownership.** The seam sits where your code meets code you
   don't own, pulled up to a contract *you* define. Leave the real impl as a
   thin adapter over the vendor.
3. **Sketch the trait in 3–6 lines of Rust.** If you can't, the level is
   wrong: too low (a dozen vendor-shaped methods) or too high (one method
   that swallows the floor).
4. **Run both tests on the candidate seam:**
   - **Too-low test** — does the fake have to reimplement semantics you don't
     own (SQL, TLS records, TCP framing, packet ordering)? Raise the seam.
   - **Too-high test** — does the fake hide a failure mode the caller
     branches on, or replace the unit under test? Lower the seam, or split
     the trait.

## When to Reach for Each

| Approach       | Use When                                          |
|----------------|---------------------------------------------------|
| Mocks          | Verifying a single interaction at a unit boundary |
| Testcontainers | Wire compatibility, schema, real SQL              |
| **Fakes**      | Default for behavior tests of code with deps      |

## The Pattern

Define a trait, implement twice — production and in-memory fake. Inject.

```rust
trait UserRepository {
    async fn save(&self, user: User) -> Result<(), StorageError>;
    async fn find_by_id(&self, id: u64) -> Result<Option<User>, StorageError>;
}
```

## Common Seams

Scan the codebase for these resource categories. Each is a source of
nondeterminism and a candidate seam:

| Resource       | Grep for                                                | Trait shape (3–6 lines)                                              |
|----------------|---------------------------------------------------------|----------------------------------------------------------------------|
| Clock          | `Instant::now`, `SystemTime`, `sleep`, timers, backoff  | `trait Clock { fn now(&self) -> Instant; async fn sleep(&self, Duration); }` |
| Randomness     | `rand::`, `thread_rng`, ID/token generation, hash iter over routing | `trait Rng { fn gen_u64(&self) -> u64; }`                |
| Network I/O    | sockets, byte streams, RPC clients                      | Domain stream trait — `read`/`write`/`close`; not raw TCP            |
| Filesystem     | config reads, log writes, cert loads                    | Domain file trait — `read`/`write`/`rename`; not raw `File`          |
| Process/thread | `spawn`, fork, blocking tasks                           | Scheduler / spawner trait controlling task admission                 |
| External RPC   | backend clients, control-plane peers                    | Domain client trait — `BackendClient::request`; not HTTP wire        |

Fake at the *domain* trait, not the resource. A proxy reading byte streams
fakes at a stream trait (slow reads, partial writes, EOF, reset) — not at the
packet level.

## Failure Modes the Fake Must Express

| Failure        | Real-world analogue                       |
|----------------|-------------------------------------------|
| Partial        | Kafka partition leader election           |
| Stale read     | Galera, async replicas                    |
| Silent drop    | MariaDB Galera certification rejection    |
| Hang           | TCP black hole, GC pause                  |
| Clock skew     | NTP correction, leap second               |

If your code branches on any of these and the fake can't produce them, raise the boundary.

## Pitfalls

- **Boundary too low.** Faking the SQL driver = simulating Postgres. Fake the repository trait.
- **Boundary too high.** Faking the unit-under-test removes the code path. Fake the *deps*.
- **Per-test setup.** A fake is one impl shared across tests, not a builder configured per test.
- **Too kind.** A fake that only fails on demand is a stub. Inject chaos by default: silent drops, stale reads, hangs.
- **No parity check.** Run a contract suite against both impls, or one integration test against the real one.
- **Trait won't fit in 3–6 lines.** Wrong level. Too many vendor-shaped methods → too low. One catch-all method → too high.

## Full Reference

- [Why Fakes Beat Mocks and Testcontainers](https://pierrezemb.fr/posts/why-fakes-beat-mocks-and-testcontainers/) — full case, industry examples (AWS, Google Fauxmaster, Microsoft CrystalNet, Oxide).
