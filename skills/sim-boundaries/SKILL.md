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

Production fails partially. Mocks couple to call shape; testcontainers are
binary up/down. Fakes — in-memory implementations of a dependency boundary —
run in microseconds and inject arbitrary failure modes.

## The Principle

> **Pick the boundary where your code meets code you don't own, at a level
> that expresses every failure mode the caller branches on.**

- *Your code* = code your team writes and maintains, not "your company owns
  the vendor." A control plane app does not own `tokio-postgres`; FDB does
  own its Flow HTTP client. The boundary moves with that line.
- *Self-contained*: the fake is a plain data structure (`HashMap`,
  `VecDeque`, in-process pipe). Tests drive workload through the trait
  API — `save(user)` then `find_by_id(id)` — not by poking the fake's
  internals.
- *Express the failure modes*: if your code branches on stale reads, the
  fake must produce stale reads. If it can't, the boundary is wrong.

## Picking the Seam

| Boundary in your codebase                | Pattern                                          | Example                                    |
|------------------------------------------|--------------------------------------------------|--------------------------------------------|
| Shallow — driver/SDK you don't own       | Domain trait above the driver; fake the wrapper  | `UserRepository` wrapping `tokio-postgres` |
| Deep — you own down to the I/O primitive | Transport swap; production client unmodified     | FDB `Sim2Conn` + `MockS3RequestHandler`    |
| No narrow point either way               | Don't fake — real instance                       | Complex SQL features → testcontainer       |

The transport swap requires (a) the slice you actually use to be small
enough to mock as a server — FDB uses S3 GET/PUT/DELETE/LIST; a typical app
uses too much of Postgres — and (b) a runtime that exposes the I/O seam to
a global swap (Flow's `g_network`, OkHttp `Interceptor`, Hadoop
`FileSystem`, `madsim` substituting Tokio). FDB cite: `S3BlobStoreEndpoint`
runs unmodified; `Sim2::connect()` returns a `Sim2Conn` plumbed to
`MockS3RequestHandler` registered via `g_simulator->registerSimHTTPServer`
(`fdbrpc/sim2.cpp:1132`, `fdbserver/mocks3/MockS3Server.h:37`).

## Sim — When the Boundary Spans Processes

A per-connection fake can't express "A↔B partitioned but B↔C healthy" —
no single fake sees the topology. Host all processes in one runtime; own
the network as `HashMap<HostId, VecDeque<Msg>>` and time as a counter the
test advances. FDB simulation, Madsim, and TigerBeetle's VOPR all work
this way.

## When to Reach for Each

| Approach       | Use when                                          |
|----------------|---------------------------------------------------|
| Mocks          | Verifying a single interaction at a unit boundary |
| Testcontainers | Wire compatibility, schema, real SQL              |
| **Fakes**      | Default for behavior tests of code with deps      |
| **Sim**        | Cross-process behavior — partition, reorder, skew |

## Common Seams

| Resource       | Look for                                               | Trait shape                                            |
|----------------|--------------------------------------------------------|--------------------------------------------------------|
| Clock          | `Instant::now`, `SystemTime`, `sleep`                  | `now() -> Instant`, `async sleep(Duration)`            |
| Randomness     | `rand::`, `thread_rng`                                 | `gen_u64() -> u64`                                     |
| Byte stream    | `TcpStream`, `connect`, `read_buf`, `tonic::transport` | `read` / `write` / `close`                             |
| File I/O       | `fs::File`, `tokio::fs`, `std::fs::read`               | `read` / `write` / `rename`                            |
| Task admission | `tokio::spawn`, `spawn_blocking`, `std::thread::spawn` | scheduler / spawner                                    |
| External RPC   | `reqwest::Client`, `tonic::Client`, `hyper::client`    | Domain client OR transport swap (see Picking the Seam) |

## Failure Modes to Inject

| Failure    | Real-world analogue                    |
|------------|----------------------------------------|
| Partial    | Kafka partition leader election        |
| Stale read | Galera, async replicas                 |
| Silent drop| MariaDB Galera certification rejection |
| Hang       | TCP black hole, GC pause               |
| Clock skew | NTP correction, leap second            |

If the caller branches on any of these and the fake can't produce them,
raise the boundary or split the trait.

## Pitfalls

- **Seam in the wrong place.** Wrote `IS3Client` even though you own the
  HTTP client → fake the transport instead. Wrote `MockPostgres` wire
  server even though you don't own the driver → wrap with a domain trait
  above.
- **Boundary too low.** If the fake has to reimplement semantics you don't
  own (SQL, TLS, packet framing), raise it.
- **Boundary too high.** Faking the unit-under-test removes the code path.
- **Per-test setup.** A fake is one impl shared across tests, not a builder
  configured per test.
- **Failure injection gated.** A `set_drop_rate()` knob or `partition(a, b)`
  call should be one method call, not buried in a builder chain.
- **No parity check.** Run a contract suite against both impls, or at least
  one integration test against the real one.
- **Per-dep fake for cross-host failure.** A `Connection` fake can't
  express partition-from-A's-view-but-not-B's. Host nodes in one sim.

## Full Reference

- [Why Fakes Beat Mocks and Testcontainers](https://pierrezemb.fr/posts/why-fakes-beat-mocks-and-testcontainers/) — full case, industry examples (AWS, Google Fauxmaster, Microsoft CrystalNet, Oxide, FoundationDB).
