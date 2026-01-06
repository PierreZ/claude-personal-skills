# Designing efficient Claude skills: A comprehensive guide

Agent Skills transform Claude from a general assistant into a domain specialist. The key insight from Anthropic's engineering team: **"Building a skill for an agent is like putting together an onboarding guide for a new hire"**—skills should contain the procedural knowledge and organizational context needed to perform specialized work effectively. This guide synthesizes official documentation, the anthropics/skills repository, and community best practices into actionable patterns for creating, organizing, and optimizing Claude skills.

## How progressive disclosure drives skill architecture

Progressive disclosure is the foundational design principle that makes skills both powerful and efficient. Like a well-organized manual with a table of contents leading to chapters and appendices, skills let Claude load information only as needed across **three distinct levels**:

| Level | When loaded | Token cost | Content |
|-------|-------------|------------|---------|
| **Level 1: Metadata** | Always at startup | ~100 tokens per skill | `name` and `description` from YAML frontmatter |
| **Level 2: Instructions** | When skill triggers | Under 5,000 tokens | SKILL.md body with core guidance |
| **Level 3: Resources** | As needed | Effectively unlimited | Scripts, references, assets loaded on-demand |

This architecture means **the amount of context bundled into a skill is effectively unbounded**. Agents with filesystem access don't need to read everything into their context window—they can execute scripts without loading the code, and reference documentation only when relevant.

## SKILL.md structure that actually works

Every skill requires a `SKILL.md` file with YAML frontmatter followed by markdown content. The frontmatter must begin on line 1 with `---` and use consistent two-space indentation (never tabs).

```markdown
---
name: pdf-processing
description: Extract text and tables from PDF files, fill forms, merge documents. 
  Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.
allowed-tools: Read, Grep, Bash
---

# PDF Processing

## Overview
[1-2 sentence purpose statement]

## Prerequisites  
[Required tools, packages, or context]

## Instructions
### Step 1: Identify the task
[Imperative instructions—"Extract tables from..." not "You should extract..."]

### Step 2: Execute the operation
[Procedural, step-by-step guidance]

## Output format
[How to structure results]

## Error handling
[What to do when operations fail]

## Examples
[Concrete input-output pairs]

## Resources
See [REFERENCE.md](REFERENCE.md) for detailed API documentation.
```

**Keep SKILL.md under 500 lines.** If approaching this limit, split content into reference files. Use imperative language throughout—skills should read like instructions, not explanations.

## Frontmatter fields that trigger accurately

The `description` field is the most critical component of any skill. Claude uses it as the primary signal for determining when to invoke a skill, making precision essential.

### Required fields

| Field | Requirements |
|-------|--------------|
| `name` | Max 64 characters; lowercase letters, numbers, hyphens only; cannot contain "anthropic" or "claude" |
| `description` | Max 1024 characters (200 on claude.ai); non-empty; no XML tags |

### Writing descriptions that trigger correctly

Weak descriptions cause skills to fire unexpectedly or miss relevant requests entirely. The description must communicate **what the skill does AND when to use it** with specific trigger words users would naturally say.

**Weak description:**
```yaml
description: Helps with documents
```

**Strong description:**
```yaml
description: Extract text and tables from PDF files, fill forms, merge and split 
  documents. Use when working with PDF files, forms, document extraction, or batch 
  PDF operations. Not for simple PDF viewing.
```

The strong version includes specific verbs (extract, fill, merge), concrete use cases (batch operations), and clear boundaries (not for viewing). Always write in third person—"Processes files" not "I can help you."

### Optional fields for control

| Field | Purpose |
|-------|---------|
| `allowed-tools` | Restricts which tools Claude can use when skill is active (Claude Code only) |
| `disable-model-invocation` | Prevents auto-invocation; skill only triggers via `/skill-name` command |
| `model` | Override the model for skill execution (e.g., "claude-opus-4-20250514") |

## Directory structure for progressive loading

Organize files to support the three-level disclosure architecture:

```
skill-name/
├── SKILL.md           # Required—core instructions (<500 lines)
├── REFERENCE.md       # Detailed documentation (loaded when referenced)
├── EXAMPLES.md        # Extended examples (loaded as needed)
├── scripts/           # Executable code (runs without loading into context)
│   ├── validate.py
│   └── process.sh
├── references/        # Supporting docs (loaded on-demand)
│   └── api_docs.md
└── assets/            # Templates, binary files (accessed as needed)
    └── template.docx
```

### When to use each directory

**scripts/** stores executable Python or Bash code. Key benefit: **scripts execute without loading their code into context**—only the output consumes tokens. Use scripts for deterministic operations, complex processing, or any logic you find yourself repeatedly asking Claude to write.

**references/** holds documentation loaded on-demand. Keep detailed specifications, API docs, and domain knowledge here. For files exceeding 10,000 words, include grep search patterns in SKILL.md so Claude can search rather than loading entirely:

```markdown
## Searching the API reference
For function signatures, use: `grep -n "def " references/api_docs.md`
For error codes, use: `grep -n "Error:" references/api_docs.md`
```

**assets/** contains templates, binary files, and resources used in output. These are accessed when needed but never loaded into context.

### File organization principles

- **Name files descriptively**: `form_validation_rules.md` not `doc2.md`
- **Keep references one level deep**: Claude may partially read deeply nested files
- **Use forward slashes** in all paths (`scripts/helper.py`)
- **Add a table of contents** to files exceeding 100 lines
- **Never duplicate content**: Information lives in SKILL.md OR reference files, not both

## Keeping skills lean for context efficiency

Context window space is a shared resource. Every skill you add consumes tokens from the same budget as conversation history, system prompts, and user requests.

### Token budget awareness

- System prompt: ~2,000 tokens
- 10 skills × ~100 tokens metadata: ~1,000 tokens  
- Full SKILL.md when loaded: typically 2,000-5,000 tokens
- Maximum skills per API request: 8
- Maximum skill upload size: 8MB total

### Optimization strategies

**Challenge every line**: Ask "Does Claude really need this explanation?" and "Does this paragraph justify its token cost?" Claude is already highly capable—only add context it doesn't already have.

**Bundle utility scripts**: Complex operations belong in `scripts/` where they execute without entering context. A 200-line Python script produces only its output in context, not its source code.

**Use the menu approach**: If your skill covers multiple processes, SKILL.md should describe what's available with relative paths to separate files. Claude then reads only what's relevant to the current task.

**Avoid @-mentioning large docs**: References work better than forcing entire documents into context.

## Organizing personal, team, and project skills

Skills live in different locations with different scopes:

| Location | Scope | Use case |
|----------|-------|----------|
| `~/.claude/skills/` | Personal—available across all projects | Individual workflows, experimental skills |
| `.claude/skills/` | Project—shared via git | Team conventions, project-specific expertise |
| Enterprise settings | Organization-wide | Company standards, centrally managed |

### Recommended folder structure

```
~/.claude/skills/                    # Personal skills
├── writing/
│   ├── SKILL.md
│   └── workflows/
│       ├── blog-post.md
│       └── documentation.md
├── research/
│   ├── SKILL.md
│   └── references/
│       └── source-evaluation.md
└── productivity/
    └── SKILL.md

project-root/.claude/skills/         # Team skills (committed to git)
├── code-review/
│   ├── SKILL.md
│   └── PATTERNS.md
├── testing/
│   └── SKILL.md
└── deployment/
    ├── SKILL.md
    └── scripts/
        └── validate_release.py
```

### Distribution methods

**Via git**: Commit `.claude/skills/` to version control. Team members receive skills automatically on pull.

**Via plugins**: Create a plugin with a `skills/` directory, publish to marketplace, team installs via `/plugin install`. This works for cross-repository sharing.

**Important limitation**: Skills do not sync across surfaces. Skills uploaded to claude.ai must be separately uploaded to the API. Claude Code skills are filesystem-based and independent of both.

## Anti-patterns that undermine skill effectiveness

### ❌ Monolithic skills
**Problem**: Single SKILL.md with 1,000+ lines bloats context on every invocation.
**Solution**: Split into main instructions plus reference files. Keep SKILL.md under 500 lines.

### ❌ Sparse frontmatter
**Problem**: Minimal descriptions missing keywords cause skills to never trigger.
**Solution**: Rich descriptions with all trigger terms users would naturally say, plus explicit "when to use" guidance.

### ❌ Nested references
**Problem**: References pointing to other references create a maze Claude may not fully traverse.
**Solution**: Keep hierarchy flat—maximum one level of reference depth.

### ❌ Code embedded in markdown
**Problem**: 100+ line code blocks in SKILL.md consume context without providing execution benefits.
**Solution**: Move to `scripts/` directory where code executes without loading.

### ❌ Over-permissive tool access
**Problem**: `allowed-tools: Bash,Read,Write,Edit,Glob,Grep,WebSearch,Task,Agent` grants unnecessary permissions.
**Solution**: Restrict to only the tools the skill actually requires.

### ❌ Vague scope boundaries  
**Problem**: "Content marketing helper" is too broad to be useful.
**Solution**: "SEO optimization for blog posts" is appropriately scoped. One skill, one capability.

## Advanced patterns for sophisticated workflows

### Tool restrictions for security

```yaml
---
name: safe-analyzer
description: Analyze code without making changes
allowed-tools: Read, Grep, Glob
---
```

When `allowed-tools` is set, Claude can only execute listed tools when the skill is active—useful for read-only operations or sensitive workflows.

### Subagents for context isolation

Use subagents when research would bloat the main conversation's context window. The pattern from alexop.dev:

```markdown
## For documentation-heavy tasks
When this skill requires reading extensive external documentation:
1. Spawn a subagent with: "Research [topic] using documentation at [URL]"
2. Subagent operates in isolated context window
3. Returns distilled findings to main conversation
4. Main context stays lean
```

Subagents excel at research-heavy tasks because they have separate context windows. Results return distilled, not raw.

### Multi-phase workflows with validation

```markdown
## Workflow: Database migration

### Phase 1: Plan
1. Analyze current schema
2. Create migration plan in `changes.json`
3. **Stop for review before proceeding**

### Phase 2: Validate  
Run `scripts/validate_migration.py changes.json`
Only proceed if validation passes.

### Phase 3: Execute
Apply migrations with logging to `migration.log`
Verify results against expected state.
```

This Plan-Validate-Execute pattern prevents costly errors in critical operations.

### TDD integration with context isolation

Advanced pattern from community practitioners:
- Test writer subagent operates in isolated context
- Implementation details cannot "bleed" into test logic  
- Phase gates block progression until each step completes

## Well-designed skills from the wild

### Anthropic's document skills (github.com/anthropics/skills)

The official `docx` skill demonstrates exemplary structure:

```yaml
---
name: docx
description: "Comprehensive document creation, editing, and analysis with support 
  for tracked changes, comments, formatting preservation, and text extraction. 
  Use when Claude needs to work with professional documents (.docx files) for:
  (1) Creating new documents, (2) Modifying content, (3) Working with tracked 
  changes, (4) Adding comments, or any other document tasks"
license: Proprietary. LICENSE.txt has complete terms
---
```

Notice the explicit enumeration of use cases and the clear statement of what triggers invocation.

### Community skill-creator meta-skill

This skill from the anthropics/skills repository demonstrates the 6-pass workflow pattern:
1. **Pass 0**: Detect skill type (protocol vs code-execution)
2. **Pass 1**: Create YAML frontmatter  
3. **Pass 2**: Write core instructions
4. **Pass 3**: Implement scripts/references/assets
5. **Pass 4**: Test activation
6. **Pass 5**: Verify structure

The skill-creator is 17.4 KB itself but uses progressive disclosure—core instructions in SKILL.md, detailed patterns in `references/workflows.md`, initialization logic in `scripts/init_skill.py`.

### obra/superpowers battle-tested collection

Community repository with 20+ production skills including:
- `brainstorming`: Activates before writing code, refines ideas through questions
- `systematic-debugging`: Four-phase root cause analysis process
- `verification-before-completion`: Blocks completion claims without proof
- `subagent-driven-development`: Fast iteration with two-stage review

## Testing and iteration strategies

### Verification checklist

1. **Run `claude --debug`** to see skill loading errors
2. **Check YAML syntax**: Must start with `---` on line 1, no tabs allowed
3. **Verify script permissions**: `chmod +x scripts/*.py`
4. **Ask "What skills are available?"** to confirm loading

### Test matrix approach

| Test type | What to verify |
|-----------|----------------|
| Normal operations | Skill handles typical requests correctly |
| Edge cases | Graceful handling of incomplete/unusual inputs |
| Out-of-scope | Skill stays inactive for related but irrelevant requests |
| Trigger accuracy | Activation matches description keywords |

### Iterative development process

Anthropic recommends using **two Claude instances**:
1. **Claude A** drafts the skill based on requirements
2. **Claude B** tests the skill in real scenarios
3. Incorporate feedback to address blind spots
4. Iterate based on observed behavior, not assumptions

### Model compatibility testing

What works for Opus may need more detail for Sonnet or Haiku. Test with all models you plan to use and adjust instruction specificity accordingly.

## Starter templates for immediate use

### Minimal single-file skill

```markdown
---
name: commit-messages
description: Generate clear commit messages from git diffs. Use when writing 
  commits or reviewing staged changes.
---

# Generating Commit Messages

## Instructions
1. Run `git diff --staged` to see changes
2. Generate message with:
   - Summary under 50 characters (present tense)
   - Detailed description explaining what and why
   - List of affected components

## Output format
```
<type>(<scope>): <summary>

<body>

<footer>
```
```

### Skill with progressive disclosure

```markdown
---
name: api-integration
description: Build and test API integrations with validation, error handling, 
  and retry logic. Use for REST API work, webhook handling, or service connections.
---

# API Integration

## Quick start
For basic GET requests, use the request pattern in [PATTERNS.md](PATTERNS.md).
For authentication flows, see [AUTH.md](references/AUTH.md).

## Core workflow
1. Define endpoint and expected response schema
2. Implement request with appropriate error handling
3. Validate response against schema
4. Add retry logic for transient failures

## Validation
Run `scripts/validate_response.py <response_file> <schema_file>`

## Error handling guide
See [ERROR_CODES.md](references/ERROR_CODES.md) for comprehensive troubleshooting.
```

### Team skill with tool restrictions

```markdown
---
name: code-review
description: Review code changes for quality, security, and AI-generated patterns. 
  Use when reviewing PRs, auditing code, or checking for common issues.
allowed-tools: Read, Grep, Glob
---

# Code Review

## What to examine
- Excessive comments stating the obvious
- Gratuitous null checks on validated values
- Try/catch blocks in trusted codepaths
- Inconsistent naming or formatting

## Review process
1. Scan file structure: `Glob **/*.{js,ts,py}`
2. Search for patterns: `Grep -r "TODO|FIXME|HACK"`
3. Read flagged files and document issues
4. Generate structured review with severity levels

## Output format
```json
{
  "file": "path/to/file",
  "line": 42,
  "severity": "warning|error|suggestion",
  "issue": "Description",
  "recommendation": "How to fix"
}
```
```

## Conclusion

Effective Claude skills balance comprehensiveness with context efficiency through progressive disclosure. The most impactful optimizations are: writing precise descriptions with explicit trigger conditions, keeping SKILL.md under 500 lines by offloading detail to reference files, using scripts for deterministic operations, and organizing skills by scope (personal, team, project) to enable appropriate sharing.

Start with a minimal skill that solves one problem well. Test with multiple prompts to verify triggering accuracy. Iterate based on observed behavior—not assumptions about how Claude will interpret your instructions. As Anthropic's engineering team notes, the goal is building "an onboarding guide for a new hire"—procedural knowledge packaged for reuse across conversations and contexts.