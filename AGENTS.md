# Project

- Y2K Snake is a native iOS game; the internal Xcode project is RetroSnake.
- Technologies: Swift, SwiftUI, and UIKit; custom grid-based Snake logic, with no third-party game engine.
- Audio uses AVFoundation and AudioToolbox; testing uses Swift Testing and XCTest.
- Founder owns product decisions and Git permissions; ChatGPT Development Lead defines tasks and coordinates work; Codex investigates, implements agreed changes, verifies, and reports.

## Release First

- Prioritize a stable App Store release of version 1.0; separate release blockers from future improvements.
- Keep changes minimal and scoped to the agreed task; avoid unrelated refactoring.
- Add features only with Founder approval; rewrite architecture only with a justified need and explicit approval.
- Preserve the existing visual style and game mechanics unless the task explicitly changes them.

## Source of Truth

- Use the current Git repository as the canonical working copy, wherever it is located.
- Treat the active Xcode target configuration as authoritative for which code and resources are built.
- Verify target membership before treating old, duplicate, or disconnected files as current.
- Inspect the existing implementation before editing; code presence alone does not prove working behavior.

## Skills

- Read the relevant installed skill instructions before applying them; select only skills suited to the task and available capabilities.
- `diagnosing-bugs`: use to investigate causes of reproducible bugs, unstable behavior, and regressions.
- `tdd`: use when changing testable game logic, scoring, collisions, game states, or other automatically testable behavior.
- `code-review`: use to review substantial changes, release issue fixes, and potentially risky changes.
- `writing-for-agents`: use when creating or substantially changing coding agent instructions.
- `domain-modeling`: use for complex changes to game rules, states, and interconnected models.
- Report missing tools or capabilities required by a skill; keep its application within task scope and claim use only when its instructions were applied.

## Testing

- Run checks proportionate to the change; a minor edit does not require the full test suite.
- Add regression tests for game logic changes where feasible.
- Build the app when changing compiled code or resources; check UI changes in Simulator or on a real device when needed.
- Distinguish static analysis, builds, automated tests, Simulator checks, real-device checks, and TestFlight validation.
- Report actual checks and results, environment limitations, and unverified scenarios; claim tests passed only if they ran and passed.

## Git Safety

- Check Git status before editing; preserve all existing user changes and modify only files within the agreed task.
- Do not commit without explicit Founder permission; push requires separate explicit Founder permission.
- Create branches or Pull Requests only when requested.
- Perform destructive Git operations only with explicit permission.
- Delete or overwrite user files only with agreement; make scoped edits while preserving unrelated content.

## Reporting

After each engineering task, provide a concise two-part report in Russian, with enough detail for technical review and without unnecessary repetition.

### PART 1 — PRODUCT OWNER SUMMARY

- Explain what was done, why it was needed, the product impact, checks performed, and any remaining problems.

### PART 2 — TECHNICAL REPORT

- List changed files, key technical decisions, and skills actually used.
- State tests and results, unverified scenarios, limitations, remaining risks, and the recommended next step.
