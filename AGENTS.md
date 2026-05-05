# AGENTS.md

## Purpose

This file is for agentic coding assistants working in this repository. The highest-value guidance here is pathing, verified commands, and the project-specific Swift conventions already in use.

## Repository Reality

- The repository root is now the Swift package root.
- The application code lives directly under the repository root in `Sources/` and `Tests/`.
- Treat `/Users/gvenzl/git/OracleFreeApp` as the working codebase for build, test, and source edits.
- Do not use stale nested worktree paths for new work; the repository root is the active project location.

## Project Overview

This is a Swift Package Manager project targeting macOS 14.

Verified from `Package.swift`:
- Package name: `OracleFreeApp`
- Platform: `.macOS(.v14)`
- Library target: `OracleFreeKit`
- Executable target: `OracleFreeApp`
- Test target: `OracleFreeKitTests`

## Where to Work

- `Sources/OracleFreeKit/`
  - Reusable and testable application logic.
  - SwiftUI views, view models, runtime abstractions, and data types live here.
- `Sources/OracleFreeApp/`
  - Executable app entry point.
  - Thin bootstrap/wiring layer for the app target.
- `Tests/OracleFreeKitTests/`
  - Swift Testing suite for `OracleFreeKit`.

Executable entry point:
- `Sources/OracleFreeApp/OracleFreeMacOSApp.swift`

That file wires `AppViewModel`, `MachineSelectionViewModel`, and `RootView`.
Prefer putting reusable and test-covered behavior into `OracleFreeKit`, not the executable target, unless the code is truly bootstrap-specific.

## Verified Commands

Run all Swift commands from the repository root.
These commands were directly verified in this repository.

### Build

```bash
cd /Users/gvenzl/git/OracleFreeApp
swift build
```

### Run all tests

```bash
cd /Users/gvenzl/git/OracleFreeApp
swift test
```

### List tests

Use this before filtering so you have the exact specifier format.

```bash
cd /Users/gvenzl/git/OracleFreeApp
swift test list
```

### Run a single test

`swift test --help` in this repo confirms filtering via:
- `--filter <test-target>.<test-case>`
- `--filter <test-target>.<test-case>/<test>`

Use `swift test list` first, then run the exact filter you need.

Example shape:

```bash
cd /Users/gvenzl/git/OracleFreeApp
swift test --filter 'OracleFreeKitTests.AppViewModelTests'
```

### Cleanup commands

Confirmed available via `swift package --help`:

```bash
cd /Users/gvenzl/git/OracleFreeApp
swift package clean
swift package reset
```

Use cleanup only when build artifacts or dependency state are the problem.

## Testing Conventions

This repository uses **Swift Testing**, not XCTest, in the current test suite.

Observed patterns in `Tests/OracleFreeKitTests/`:
- `import Testing`
- `@Test`
- `#expect(...)`
- `Issue.record(...)`
- `@testable import OracleFreeKit`

When adding tests, follow the existing framework and syntax instead of introducing XCTest-style patterns.

## Code Patterns to Preserve

### View models

View models currently use:
- `@MainActor`
- `@Observable`
- `public final class`

Examples: `AppViewModel`, `MachineSelectionViewModel`.

### Views and data types

- SwiftUI views are `public struct` types.
- Runtime/data types also use structs and enums where appropriate.
- Examples: `RootView`, `MachineListView`, `PodmanCommandRuntime`, `RuntimeStatus`.

Prefer value semantics for plain data and runtime adapters unless shared mutable state is required.

### Dependency injection

The codebase already uses explicit dependency injection.
Observed pattern:
- `AppViewModel` depends on `any PodmanRuntime`
- Tests inject fake runtime implementations

Preserve this pattern rather than hard-wiring process execution or global state into view models.

## Error Handling Conventions

Error handling is explicit and user-visible.

Observed patterns:
- Async calls use `do` / `catch`
- Errors are mapped to readable messages through `LocalizedError` or `localizedDescription`
- UI state stores user-facing failures in `RuntimeStatus.failed(message:)`

When adding new failure paths, preserve the existing error-to-message flow instead of inventing a parallel error presentation mechanism.

## Formatting and Style

No repo-local formatter or lint configuration was found.

Observed conventions:
- 4-space indentation
- Imports at the top of the file
- One import per line
- Blank lines between logical sections
- Compact, readable declarations over clever shorthand

### Naming and access control

- Types use PascalCase: `AppViewModel`, `PodmanCommandRuntime`, `RuntimeStatus`
- Properties and functions use lowerCamelCase: `loadMachines()`, `selectedMachine`, `discoverMachines()`
- Enum cases use lowerCamelCase: `.loading`, `.loaded`, `.failed`
- Tests use descriptive lowerCamelCase names
- Use `public` for package-facing APIs, `private` for helpers, and `public private(set)` where external reads but internal mutation are intended

### Types and concurrency

Observed patterns include:
- Explicit protocol existential usage with `any`
- `Sendable` on cross-concurrency-safe types where appropriate
- `@Sendable` closures for async command execution dependencies
- `@MainActor` for UI-facing mutable state

Preserve these explicit concurrency and typing choices.

## Architecture Notes

The current split is intentional:
- `OracleFreeApp` is the executable bootstrap target.
- `OracleFreeKit` contains most reusable logic and the code under test.

When deciding where code belongs:
- Put testable business/runtime/view-model logic in `OracleFreeKit`.
- Keep `OracleFreeApp` focused on app startup and composition.
- Avoid moving logic into the executable target if it can live in the library target and be tested there.

## Platform Assumptions

`Package.swift` declares macOS 14.
Do not assume iOS support, cross-platform support, alternate package managers, or Xcode-specific workflows as the primary workflow.
Use the SwiftPM workflow that is actually present unless new repo evidence indicates otherwise.

## Tooling and Rule Files Not Present

No evidence was found for these repo-local tools or instruction files:
- `.cursor/rules/`
- `.cursorrules`
- `.github/copilot-instructions.md`
- `CLAUDE.md`
- `swiftlint` config
- `swiftformat` config
- CI workflows
- `Makefile`

Do not reference, rely on, or claim support for nonexistent tooling.

## Practical Guidance

Before changing code:
1. Work in the repository root: `/Users/gvenzl/git/OracleFreeApp`
2. Read nearby source and test files first
3. Preserve the existing target split
4. Follow Swift Testing patterns already in use
5. Verify with `swift build` and `swift test`

Before running a single test:
1. Run `swift test list`
2. Copy the actual test specifier format
3. Use `swift test --filter ...`

## Common Mistakes to Avoid

- Running commands from stale nested worktree paths
- Introducing XCTest conventions into a Swift Testing suite
- Adding references to SwiftLint, SwiftFormat, Makefile targets, CI jobs, Cursor rules, or Copilot instructions that do not exist here
- Placing reusable logic in the app bootstrap target when it belongs in `OracleFreeKit`
- Replacing the current user-visible error mapping with inconsistent error handling paths

## Metadata

- Generated for repository: `/Users/gvenzl/git/OracleFreeApp`
- Branch: `main`
- Commit: `54a5d8d`
