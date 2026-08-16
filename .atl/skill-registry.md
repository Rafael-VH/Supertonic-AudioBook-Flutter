# Skill Registry

Index of LLM-first skills available to this project. Subagents receive exact paths and read the full `SKILL.md` as source of truth. Scope: `user` (global install) or `project` (repo-local). No project-level skills found; all entries are user-level.

## SDD Workflow Skills (excluded from registry per sdd-init rules)

`sdd-init`, `sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`, `sdd-verify`, `sdd-archive`, `sdd-onboard`, `skill-registry`, `_shared` — infrastructure, not indexed.

## General / Process

| Skill | Trigger (from description) | Path | Scope |
| --- | --- | --- | --- |
| arquic | "arquic review", "clean check", "revisar arquitectura", "arquitectura limpia", "arqui review"; before implementing any change touching `lib/features/`. Clean Architecture reviewer for learners (Dependency Rule, layer purity). | `C:\Users\rafae\.config\opencode\skills\arquic\SKILL.md` | user |
| branch-pr | Creating, opening, or preparing PRs for review. Gentle AI pull requests with issue-first checks. | `C:\Users\rafae\.config\opencode\skills\branch-pr\SKILL.md` | user |
| chained-pr | PRs over 400 lines, stacked PRs, review slices. Split oversized changes into chained PRs. | `C:\Users\rafae\.config\opencode\skills\chained-pr\SKILL.md` | user |
| cognitive-doc-design | Writing guides, READMEs, RFCs, onboarding, architecture, or review-facing docs. Design docs that reduce cognitive load. | `C:\Users\rafae\.config\opencode\skills\cognitive-doc-design\SKILL.md` | user |
| comment-writer | PR feedback, issue replies, reviews, Slack messages, or GitHub comments. Warm, direct collaboration comments. | `C:\Users\rafae\.config\opencode\skills\comment-writer\SKILL.md` | user |
| go-testing | Go tests, go test coverage, Bubbletea teatest, golden files. Focused Go testing patterns. | `C:\Users\rafae\.config\opencode\skills\go-testing\SKILL.md` | user |
| issue-creation | Creating GitHub issues, bug reports, or feature requests. Gentle AI issues with issue-first checks. | `C:\Users\rafae\.config\opencode\skills\issue-creation\SKILL.md` | user |
| judgment-day | judgment day, dual review, adversarial review, juzgar. Blind dual review, fix confirmed issues, re-judge. | `C:\Users\rafae\.config\opencode\skills\judgment-day\SKILL.md` | user |
| skill-creator | New skills, agent instructions, documenting AI usage patterns. Create LLM-first skills with valid frontmatter. | `C:\Users\rafae\.config\opencode\skills\skill-creator\SKILL.md` | user |
| skill-improver | Improve skills, audit skills, refactor skills, skill quality. Audit and upgrade existing LLM-first skills. | `C:\Users\rafae\.config\opencode\skills\skill-improver\SKILL.md` | user |
| using-fdb | Launch/attach to Flutter apps on devices, hot reload, screenshots, app logs (`fdb logs`), native syslog, crash reports, widget-tree inspection, taps/inputs/swipes, permission grant, GC. | `C:\Users\rafae\.config\opencode\skills\using-fdb\SKILL.md` | user |
| work-unit-commits | Implementation, commit splitting, chained PRs, keeping tests and docs with code. Plan commits as reviewable work units. | `C:\Users\rafae\.config\opencode\skills\work-unit-commits\SKILL.md` | user |
| find-skills | "how do I do X", "find a skill for X", extending capabilities. Discover and install agent skills. | `C:\Users\rafae\.agents\skills\find-skills\SKILL.md` | user |

## Flutter / Supabase (domain skills)

| Skill | Trigger (from description) | Path | Scope |
| --- | --- | --- | --- |
| flutter-add-integration-test | Adding integration testing to a project, exploring UI via MCP, automating user flows with `integration_test`. | `C:\Users\rafae\.agents\skills\flutter-add-integration-test\SKILL.md` | user |
| flutter-add-widget-preview | Creating new UI components or updating existing screens. Interactive widget previews via `previews.dart`. | `C:\Users\rafae\.agents\skills\flutter-add-widget-preview\SKILL.md` | user |
| flutter-add-widget-test | Validating a specific widget displays data and responds to events. Component tests with `WidgetTester`. | `C:\Users\rafae\.agents\skills\flutter-add-widget-test\SKILL.md` | user |
| flutter-apply-architecture-best-practices | Structuring a new project or refactoring for scalability. Layered approach (UI, Logic, Data). | `C:\Users\rafae\.agents\skills\flutter-apply-architecture-best-practices\SKILL.md` | user |
| flutter-build-responsive-layout | UI needs to look good on mobile and tablet/desktop. `LayoutBuilder`, `MediaQuery`, `Expanded/Flexible`. | `C:\Users\rafae\.agents\skills\flutter-build-responsive-layout\SKILL.md` | user |
| flutter-fix-layout-issues | "RenderFlex overflowed", "Vertical viewport was given unbounded height", similar layout errors. | `C:\Users\rafae\.agents\skills\flutter-fix-layout-issues\SKILL.md` | user |
| flutter-implement-json-serialization | Manually mapping JSON keys to class properties for simple data structures. `fromJson`/`toJson` with `dart:convert`. | `C:\Users\rafae\.agents\skills\flutter-implement-json-serialization\SKILL.md` | user |
| flutter-setup-declarative-routing | Advanced URL-based navigation, deep linking, browser history. `MaterialApp.router` with `go_router`. | `C:\Users\rafae\.agents\skills\flutter-setup-declarative-routing\SKILL.md` | user |
| flutter-setup-localization | Initializing localization support for a new Flutter project. `flutter_localizations`, `intl`, `l10n.yaml`, `generate: true`. | `C:\Users\rafae\.agents\skills\flutter-setup-localization\SKILL.md` | user |
| flutter-use-http-package | Fetch from / send data to a REST API. GET, POST, PUT, DELETE with the `http` package. | `C:\Users\rafae\.agents\skills\flutter-use-http-package\SKILL.md` | user |
| supabase | ANY task involving Supabase (Database, Auth, Edge Functions, Realtime, Storage, Vectors, Cron, Queues, SSR, RLS, CLI, MCP). | `C:\Users\rafae\.agents\skills\supabase\SKILL.md` | user |
| supabase-postgres-best-practices | Writing, reviewing, or optimizing Postgres queries, schema designs, database configurations. | `C:\Users\rafae\.agents\skills\supabase-postgres-best-practices\SKILL.md` | user |

## Convention Files

No project convention files found (`AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `GEMINI.md`, `copilot-instructions.md`). User-level conventions live in `C:\Users\rafae\.config\opencode\AGENTS.md`.
