# Claude Personal Skills

A collection of personal skills for [Claude Code](https://claude.ai/code).

## Usage

Copy skills to `~/.claude/skills/` for personal use, or to `.claude/skills/` in a project for team sharing.

Or run `./install.sh` to symlink every skill in `skills/` into `~/.claude/skills/`.

## Skills

| Skill | Description |
|-------|-------------|
| [handover](skills/handover/SKILL.md) | Generate a `HANDOVER.md` shift-change report so the next session can resume without losing context. |
| [rust-api-guidelines](skills/rust-api-guidelines/SKILL.md) | Idiomatic Rust API design — naming, traits, error handling, type safety. |
| [sim-boundaries](skills/sim-boundaries/SKILL.md) | Sim-driven testing — replace mocks/testcontainers with in-memory trait-based fakes at the right boundary. |
| [spec-interview](skills/spec-interview/SKILL.md) | Interview-driven spec creation for a new feature. |

## Creating Skills

See `references/guide.md` for comprehensive guidance on designing effective skills.

## License

Apache 2.0
