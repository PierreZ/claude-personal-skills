# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repository contains personal skills for Claude Code - custom slash commands and automation that extend Claude Code's capabilities.

## Designing Skills

See `references/guide.md` for comprehensive guidance on creating effective skills.

### Skill Pattern

Skills should be **short and actionable** (~80-100 lines). Follow the pattern in `skills/application-metrics/SKILL.md`:

1. **Tables over prose** - Use tables for rules, patterns, checklists
2. **Link to blog posts** - Reference external URLs for full context rather than embedding content
3. **Concise sections** - Each section should be scannable at a glance
4. **End with "Full Reference"** - Point to the source blog post URL

### SKILL.md Structure

- YAML frontmatter (name, description, allowed-tools)
- One-line overview
- Content tables/checklists
- Common pitfalls list
- Full Reference link to blog post

## License

Apache 2.0
