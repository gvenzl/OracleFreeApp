# Runtime-Selectable Oracle Database Free MVP Implementation Plan

> **Status note:** This is a historical implementation plan. The current app has moved beyond
> this plan: it supports Docker, Podman, and Rancher Desktop runtime selection; Podman machine
> readiness; Oracle container create/start/stop/delete; persisted container configuration; app
> icon/menu bar integration; unsigned packaging; and resolved runtime executable paths for
> packaged app launches. Use `README.md` and `AGENTS.md` for current repository guidance.

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the current Podman-machine-discovery macOS app into a runtime-selectable Oracle Database Free manager that can detect supported runtimes, inform the user when none are installed, let the user choose a runtime, and manage one Oracle Database Free container through the first concrete backend implementation.

**Architecture:** Keep `OracleFreeApp` as a thin bootstrap target and place nearly all behavior in `OracleFreeKit`. Build the product in layers: runtime detection and selection first, then a generalized runtime boundary with Podman as the first concrete backend, then Oracle-specific orchestration, then lifecycle UI and polish.

**Tech Stack:** SwiftPM, SwiftUI, Observation, Swift Testing, Process-based CLI integration, macOS 14.

---

## File Structure Plan

### Existing files to modify

- Modify: `Sources/OracleFreeApp/OracleFreeMacOSApp.swift`
- Modify: `Sources/OracleFreeKit/AppViewModel.swift`
- Modify: `Sources/OracleFreeKit/RootView.swift`
- Modify: `Sources/OracleFreeKit/PodmanRuntime.swift`
- Modify: `Sources/OracleFreeKit/PodmanCommandRuntime.swift`
- Modify: `Tests/OracleFreeKitTests/AppViewModelTests.swift`
- Modify: `Tests/OracleFreeKitTests/RootViewTests.swift`

### New source files to create

- Create: `Sources/OracleFreeKit/ContainerRuntimeKind.swift`
- Create: `Sources/OracleFreeKit/ContainerRuntimeInstallationStatus.swift`
- Create: `Sources/OracleFreeKit/ContainerRuntimeSelection.swift`
- Create: `Sources/OracleFreeKit/ContainerRuntime.swift`
- Create: `Sources/OracleFreeKit/ContainerRuntimeDetector.swift`
- Create: `Sources/OracleFreeKit/DefaultContainerRuntimeDetector.swift`
- Create: `Sources/OracleFreeKit/ContainerContext.swift`
- Create: `Sources/OracleFreeKit/ContainerSummary.swift`
- Create: `Sources/OracleFreeKit/OracleContainerConfiguration.swift`
- Create: `Sources/OracleFreeKit/OracleConnectionInfo.swift`
- Create: `Sources/OracleFreeKit/OracleInstanceStatus.swift`
- Create: `Sources/OracleFreeKit/RuntimeSelectionViewModel.swift`
- Create: `Sources/OracleFreeKit/OracleInstanceViewModel.swift`
- Create: `Sources/OracleFreeKit/OracleInstanceService.swift`
- Create: `Sources/OracleFreeKit/RuntimeSelectionView.swift`
- Create: `Sources/OracleFreeKit/OracleInstanceView.swift`
- Create: `Sources/OracleFreeKit/MissingRuntimeView.swift`

### New test files to create

- Create: `Tests/OracleFreeKitTests/RuntimeSelectionViewModelTests.swift`
- Create: `Tests/OracleFreeKitTests/ContainerRuntimeDetectorTests.swift`
- Create: `Tests/OracleFreeKitTests/PodmanCommandRuntimeContainerTests.swift`
- Create: `Tests/OracleFreeKitTests/OracleInstanceServiceTests.swift`
- Create: `Tests/OracleFreeKitTests/OracleInstanceViewModelTests.swift`

## Phase Ordering

Implement strictly in this order:

1. Runtime detection and missing-runtime UX
2. Runtime selection UX
3. Generalized runtime boundary with Podman as the first backend
4. Oracle-specific service and state model
5. Oracle lifecycle view model and UI
6. Integration cleanup and verification

Do not start UI polish before the underlying state model and tests are in place.

---

## Task 1: Add runtime domain types and runtime detection

**Files:**
- Create: `Sources/OracleFreeKit/ContainerRuntimeKind.swift`
- Create: `Sources/OracleFreeKit/ContainerRuntimeInstallationStatus.swift`
- Create: `Sources/OracleFreeKit/ContainerRuntimeSelection.swift`
- Create: `Sources/OracleFreeKit/ContainerRuntimeDetector.swift`
- Create: `Sources/OracleFreeKit/DefaultContainerRuntimeDetector.swift`
- Create: `Tests/OracleFreeKitTests/ContainerRuntimeDetectorTests.swift`

- [ ] **Step 1: Write the failing detector tests**

Add tests covering:
- no supported runtime installed
- exactly one runtime installed
- multiple runtimes installed

Use dependency injection for command/path lookup rather than real shelling in tests.

- [ ] **Step 2: Run the new detector tests to verify they fail**

Run:
```bash
cd /Users/gvenzl/git/OracleFreeApp
swift test list
swift test --filter 'OracleFreeKitTests.ContainerRuntimeDetectorTests'
```

Expected: FAIL because detector/domain types do not exist yet.

- [ ] **Step 3: Implement minimal runtime domain types and detector**

Requirements:
- `ContainerRuntimeKind` should represent at least `podman` and `docker`
- `ContainerRuntimeInstallationStatus` should model zero/one/multiple installed runtimes
- `DefaultContainerRuntimeDetector` should detect runtime executables via injected lookup logic
- keep all logic in `OracleFreeKit`

- [ ] **Step 4: Re-run detector tests until they pass**

Run:
```bash
cd /Users/gvenzl/git/OracleFreeApp
swift test --filter 'OracleFreeKitTests.ContainerRuntimeDetectorTests'
```

Expected: PASS

- [ ] **Step 5: Refactor names and test helpers without changing behavior**

Keep tests green.

---

## Task 2: Extend app-level state for runtime detection and selection

**Files:**
- Modify: `Sources/OracleFreeKit/AppViewModel.swift`
- Modify: `Tests/OracleFreeKitTests/AppViewModelTests.swift`
- Create: `Sources/OracleFreeKit/RuntimeSelectionViewModel.swift`
- Create: `Tests/OracleFreeKitTests/RuntimeSelectionViewModelTests.swift`

- [ ] **Step 1: Write failing tests for app-level runtime availability behavior**

Cover:
- app starts in loading state
- app can load runtime availability
- app exposes readable error when detection fails
- runtime selection view model can select one runtime when multiple are available

- [ ] **Step 2: Run the targeted tests to verify failure**

Run:
```bash
cd /Users/gvenzl/git/OracleFreeApp
swift test --filter 'OracleFreeKitTests.AppViewModelTests'
swift test --filter 'OracleFreeKitTests.RuntimeSelectionViewModelTests'
```

Expected: FAIL because the new runtime selection state and view model do not exist yet.

- [ ] **Step 3: Evolve `AppViewModel` minimally**

Requirements:
- inject a runtime detector dependency instead of only a Podman machine runtime
- publish runtime installation state
- preserve readable error handling
- avoid turning `AppViewModel` into the full Oracle lifecycle owner

- [ ] **Step 4: Implement `RuntimeSelectionViewModel` minimally**

Requirements:
- hold detected runtimes
- expose selected runtime
- support explicit selection when more than one runtime exists
- remain independent from Oracle container lifecycle logic

- [ ] **Step 5: Re-run the targeted tests**

Run:
```bash
cd /Users/gvenzl/git/OracleFreeApp
swift test --filter 'OracleFreeKitTests.AppViewModelTests'
swift test --filter 'OracleFreeKitTests.RuntimeSelectionViewModelTests'
```

Expected: PASS

---

## Task 3: Introduce missing-runtime and runtime-selection UI

**Files:**
- Modify: `Sources/OracleFreeKit/RootView.swift`
- Create: `Sources/OracleFreeKit/MissingRuntimeView.swift`
- Create: `Sources/OracleFreeKit/RuntimeSelectionView.swift`
- Modify: `Tests/OracleFreeKitTests/RootViewTests.swift`

- [ ] **Step 1: Write failing root view tests for new runtime states**

Cover:
- missing-runtime message renders
- runtime-selection view renders when multiple runtimes are available
- existing loading/error states remain intact

- [ ] **Step 2: Run the root view tests to verify failure**

Run:
```bash
cd /Users/gvenzl/git/OracleFreeApp
swift test --filter 'OracleFreeKitTests.RootViewTests'
```

Expected: FAIL because these UI states do not exist yet.

- [ ] **Step 3: Implement `MissingRuntimeView` and `RuntimeSelectionView`**

Requirements for missing-runtime UX:
- clearly state that no supported runtime was found
- clearly state that installation must be done by the user
- include a retry action hook

Requirements for runtime selection UX:
- show available runtimes
- allow choosing one
- keep the UI minimal and state-driven

- [ ] **Step 4: Update `RootView` to route runtime states first**

Requirements:
- loading → loading UI
- detection failure → readable failure UI
- no runtime installed → missing-runtime UI
- multiple runtimes → runtime-selection UI
- one runtime or selected runtime → continue to next stage

- [ ] **Step 5: Re-run the root view tests**

Run:
```bash
cd /Users/gvenzl/git/OracleFreeApp
swift test --filter 'OracleFreeKitTests.RootViewTests'
```

Expected: PASS

---

## Task 4: Generalize the runtime boundary while keeping Podman first

**Files:**
- Create: `Sources/OracleFreeKit/ContainerRuntime.swift`
- Create: `Sources/OracleFreeKit/ContainerContext.swift`
- Create: `Sources/OracleFreeKit/ContainerSummary.swift`
- Modify: `Sources/OracleFreeKit/PodmanRuntime.swift`
- Modify: `Sources/OracleFreeKit/PodmanCommandRuntime.swift`
- Create: `Tests/OracleFreeKitTests/PodmanCommandRuntimeContainerTests.swift`

- [ ] **Step 1: Write failing tests for Podman container operations and parsing**

Cover:
- machine discovery still works
- list/inspect container parsing works
- create/start/stop/delete command construction is correct
- parsing failures become readable errors

- [ ] **Step 2: Run the Podman runtime tests to verify failure**

Run:
```bash
cd /Users/gvenzl/git/OracleFreeApp
swift test --filter 'OracleFreeKitTests.PodmanCommandRuntimeContainerTests'
```

Expected: FAIL because container runtime operations do not exist yet.

- [ ] **Step 3: Add the shared runtime protocol and minimal container types**

Requirements:
- `ContainerRuntime` should model the shared runtime primitives the product needs
- keep backend-specific details in Podman implementation
- do not over-generalize backend differences away

- [ ] **Step 4: Extend `PodmanCommandRuntime` as the first concrete backend**

Requirements:
- preserve current machine discovery behavior
- add Podman-backed container inspection/lifecycle methods
- keep process execution injectable for tests
- translate command failures into readable errors

- [ ] **Step 5: Re-run the Podman runtime tests**

Run:
```bash
cd /Users/gvenzl/git/OracleFreeApp
swift test --filter 'OracleFreeKitTests.PodmanCommandRuntimeContainerTests'
```

Expected: PASS

---

## Task 5: Add Oracle container configuration and orchestration service

**Files:**
- Create: `Sources/OracleFreeKit/OracleContainerConfiguration.swift`
- Create: `Sources/OracleFreeKit/OracleConnectionInfo.swift`
- Create: `Sources/OracleFreeKit/OracleInstanceStatus.swift`
- Create: `Sources/OracleFreeKit/OracleInstanceService.swift`
- Create: `Tests/OracleFreeKitTests/OracleInstanceServiceTests.swift`

- [ ] **Step 1: Write failing service tests for Oracle orchestration**

Cover:
- missing container maps to `missing`
- stopped container maps to `stopped`
- running but not ready maps to a non-ready running state
- ready container produces connection info
- create/start/stop/delete operations delegate to runtime correctly
- runtime failures become readable failed state

- [ ] **Step 2: Run the service tests to verify failure**

Run:
```bash
cd /Users/gvenzl/git/OracleFreeApp
swift test --filter 'OracleFreeKitTests.OracleInstanceServiceTests'
```

Expected: FAIL because the Oracle service and status types do not exist yet.

- [ ] **Step 3: Implement minimal Oracle orchestration logic**

Requirements:
- keep Oracle-specific rules out of runtime adapter
- centralize image/container-name/port assumptions in the service/configuration
- model readiness separately from running
- produce connection info only when appropriate

- [ ] **Step 4: Re-run the service tests**

Run:
```bash
cd /Users/gvenzl/git/OracleFreeApp
swift test --filter 'OracleFreeKitTests.OracleInstanceServiceTests'
```

Expected: PASS

---

## Task 6: Add Oracle lifecycle view model

**Files:**
- Create: `Sources/OracleFreeKit/OracleInstanceViewModel.swift`
- Create: `Tests/OracleFreeKitTests/OracleInstanceViewModelTests.swift`

- [ ] **Step 1: Write failing view-model tests**

Cover:
- reacts to selected runtime/context
- loads instance status
- exposes create/start/stop/delete actions
- exposes readable failures
- refreshes status after actions

- [ ] **Step 2: Run the view-model tests to verify failure**

Run:
```bash
cd /Users/gvenzl/git/OracleFreeApp
swift test --filter 'OracleFreeKitTests.OracleInstanceViewModelTests'
```

Expected: FAIL because the view model does not exist yet.

- [ ] **Step 3: Implement the view model minimally**

Requirements:
- inject Oracle service
- keep state transitions explicit
- avoid owning unrelated runtime detection logic
- keep actor isolation aligned with existing view-model style

- [ ] **Step 4: Re-run the view-model tests**

Run:
```bash
cd /Users/gvenzl/git/OracleFreeApp
swift test --filter 'OracleFreeKitTests.OracleInstanceViewModelTests'
```

Expected: PASS

---

## Task 7: Add Oracle lifecycle UI and integrate app composition

**Files:**
- Create: `Sources/OracleFreeKit/OracleInstanceView.swift`
- Modify: `Sources/OracleFreeKit/RootView.swift`
- Modify: `Sources/OracleFreeApp/OracleFreeMacOSApp.swift`
- Modify: `Tests/OracleFreeKitTests/RootViewTests.swift`

- [ ] **Step 1: Write failing UI tests for Oracle lifecycle states**

Cover:
- missing Oracle container message and create action state
- stopped state renders start action
- running but not ready message renders
- ready state renders connection information

- [ ] **Step 2: Run the root view tests to verify failure**

Run:
```bash
cd /Users/gvenzl/git/OracleFreeApp
swift test --filter 'OracleFreeKitTests.RootViewTests'
```

Expected: FAIL because Oracle lifecycle UI does not exist yet.

- [ ] **Step 3: Implement `OracleInstanceView` minimally**

Requirements:
- render major lifecycle states only
- keep action availability state-driven
- keep messaging readable and concise

- [ ] **Step 4: Update `RootView` and app bootstrap wiring**

Requirements:
- root flow: runtime detection → runtime selection → context selection if needed → Oracle instance management
- keep `OracleFreeMacOSApp.swift` thin; compose dependencies only
- avoid moving business logic into app target

- [ ] **Step 5: Re-run root view tests**

Run:
```bash
cd /Users/gvenzl/git/OracleFreeApp
swift test --filter 'OracleFreeKitTests.RootViewTests'
```

Expected: PASS

---

## Task 8: Full verification and cleanup

**Files:**
- Modify: any touched files above only as needed to resolve issues caused by implementation

- [ ] **Step 1: Run all targeted tests**

Run:
```bash
cd /Users/gvenzl/git/OracleFreeApp
swift test --filter 'OracleFreeKitTests.ContainerRuntimeDetectorTests'
swift test --filter 'OracleFreeKitTests.RuntimeSelectionViewModelTests'
swift test --filter 'OracleFreeKitTests.PodmanCommandRuntimeContainerTests'
swift test --filter 'OracleFreeKitTests.OracleInstanceServiceTests'
swift test --filter 'OracleFreeKitTests.OracleInstanceViewModelTests'
swift test --filter 'OracleFreeKitTests.RootViewTests'
```

Expected: all PASS

- [ ] **Step 2: Run the full suite**

Run:
```bash
cd /Users/gvenzl/git/OracleFreeApp
swift test
```

Expected: PASS

- [ ] **Step 3: Run the build**

Run:
```bash
cd /Users/gvenzl/git/OracleFreeApp
swift build
```

Expected: PASS

- [ ] **Step 4: Smoke-check user-visible states manually**

At minimum verify:
- missing runtime state is reachable with test doubles
- runtime selection state is reachable
- Podman-backed lifecycle state renders without obvious broken text flow

- [ ] **Step 5: Keep scope honest**

Do not add:
- multi-instance support
- runtime installation automation
- advanced database tooling
- full parity for all runtime backends in this pass

---

## Implementation Notes

- Follow the existing repository pattern of `@MainActor`, `@Observable`, and `public final class` for view models.
- Keep value types as `struct`/`enum` where possible.
- Preserve dependency injection through protocols and injected closures.
- Use Swift Testing, not XCTest.
- Keep user-visible errors routed through explicit state, not ad hoc alerts scattered across the UI.
- The first concrete backend should remain Podman, even though runtime selection is now part of the product contract.

## Suggested Milestone Breakdown

If execution needs to pause between review points, pause after:

1. runtime detection + missing-runtime UI
2. backend-aware runtime abstraction + Podman container operations
3. Oracle service + Oracle lifecycle view model
4. end-to-end UI integration and full verification
