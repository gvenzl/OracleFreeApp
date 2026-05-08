# Oracle Database Free macOS App — Runtime-Selectable MVP Design

> **Status note:** This is a historical MVP design document. The current app is no longer just
> a Podman-first discovery app; it has Docker, Podman, and Rancher Desktop runtime selection,
> Oracle container lifecycle management, persisted container settings, readiness/log handling,
> menu bar actions, unsigned packaging, and resolved executable path handling for packaged app
> launches. Use `README.md` and `AGENTS.md` for current implementation guidance.

**Date:** 2026-03-31  
**Repository:** `/Users/gvenzl/git/OracleFreeApp`  
**Working codebase:** `/Users/gvenzl/git/OracleFreeApp`

## Goal

Evolve the existing SwiftUI macOS app into a native-feeling Oracle Database Free manager that lets the user choose which supported container runtime to use and manages a single Oracle Database Free container on that runtime.

This milestone remains intentionally narrow. It should prove the end-to-end product shape without taking on runtime installation automation, multiple database instances, or database administration tooling.

## Current State

The current codebase already has the right architectural starting point:

- `OracleFreeApp` is a thin executable target with app startup wiring.
- `OracleFreeKit` contains reusable logic, models, views, and runtime abstractions.
- `PodmanRuntime` and `PodmanCommandRuntime` already support Podman machine discovery.
- `AppViewModel`, `MachineSelectionViewModel`, `RootView`, and `MachineListView` provide a state-driven SwiftUI flow.
- Swift Testing coverage already exists for view models, view rendering, and state transitions.

Today, the app is effectively a Podman machine discovery and selection app. It does not yet manage Oracle container lifecycle, runtime selection, or missing-runtime guidance.

## Product Scope

### In scope for this MVP

The app will:

1. Detect supported container runtimes installed on the user’s machine.
2. Inform the user when no supported container runtime is installed.
3. Tell the user clearly that installing a supported runtime is the user’s responsibility.
4. Let the user choose which detected runtime to use when more than one is available.
5. For runtimes that require machine selection, let the user choose an appropriate machine.
6. Inspect whether a designated Oracle Database Free container exists on the selected runtime context.
7. Create the container if it does not exist.
8. Start the container.
9. Stop the container.
10. Delete the container.
11. Surface container status separately from database readiness.
12. Show user-facing connection details once the database is ready.
13. Show understandable error messages when runtime or container actions fail.

### Explicitly out of scope for this MVP

The app will **not** attempt to solve these yet:

- Installing Podman, Docker, or any other runtime for the user.
- Creating or configuring runtime machines for the user.
- Managing multiple Oracle database containers.
- Embedding SQL clients or DBA workflows.
- Packaging a fully polished PostgresApp-equivalent setup experience.
- Advanced persistence, account flows, or Oracle image entitlement workflows beyond a fixed supported path.
- Full feature parity across every possible runtime backend in the first implementation pass.

## Product Philosophy

The app should feel like a native macOS app, but the first success criterion is not cosmetic parity with PostgresApp. The first success criterion is reliable, understandable orchestration of a containerized local Oracle Database Free instance, even when prerequisite tooling is missing.

This means the implementation should prioritize:

- a clean runtime abstraction boundary,
- testable domain logic,
- explicit state transitions,
- readable failure handling,
- prerequisite detection,
- and a small, comprehensible UI.

## Reference Inspiration from PostgresApp

PostgresApp is useful here primarily as a **product reference**, not a blueprint to copy directly.

Relevant product ideas to emulate:

- Native-feeling local app shell.
- Clear lifecycle actions.
- Human-readable status.
- Easy access to connection details.
- Predictable management of a local development database.
- Helpful setup guidance when prerequisites are missing.

Not directly transferable:

- Assumptions based on directly managed local binaries instead of containers.
- Postgres-specific packaging and internal runtime behaviors.
- Product complexity that exceeds the current Oracle/container-runtime MVP.

## Architecture

### Target split

Preserve the current target split.

#### `OracleFreeApp`

Responsibilities:

- application entry point,
- scene/window lifecycle,
- dependency construction,
- app-specific composition.

This target should remain thin.

#### `OracleFreeKit`

Responsibilities:

- domain models,
- runtime protocols,
- runtime detection and command adapters,
- Oracle-specific orchestration services,
- view models,
- reusable SwiftUI views,
- testable logic.

This target should remain the home of nearly all behavior.

## Design Principles

### 1. Introduce a runtime abstraction without pretending all runtimes are identical

The app should support user choice of runtime, but the design should not flatten away meaningful backend differences.

A shared runtime interface should model the primitives the product needs, while concrete adapters can preserve backend-specific behavior. The current Podman implementation becomes the first concrete backend, not the permanent architecture boundary.

### 2. Keep runtime-specific and Oracle-specific logic separate

Runtime adapters should know how to detect tooling, run runtime commands, and parse runtime outputs. They should not own Oracle product rules such as container naming, port conventions, image selection, or readiness interpretation.

Those Oracle-specific decisions belong in a separate service above the runtime adapter.

### 3. Avoid a god view model

The existing machine discovery and selection flow is already separate. Preserve that separation.

Do not turn `AppViewModel` into a single object that owns:

- runtime detection,
- runtime selection,
- machine discovery,
- machine selection,
- container inspection,
- create/start/stop/delete actions,
- readiness polling,
- and UI routing.

Instead, split these concerns across dedicated view models or coordinators and keep `RootView` acting as a state router.

### 4. Model readiness explicitly

For Oracle Database Free, a running container is not the same thing as a ready-to-use database.

The app must distinguish at least:

- no supported runtime installed,
- runtime selected but context not yet selected,
- container missing,
- container created but stopped,
- container starting,
- container running but database not yet ready,
- database ready,
- failed state.

### 5. Keep user-facing errors readable and actionable

The repository already maps runtime failures to readable UI messages. Preserve that pattern.

Internal command failures should be translated into state that the UI can render clearly. Missing prerequisites should be reported with clear language that the runtime must be installed by the user.

## Supported Runtime Model

The product should treat runtime choice as user-facing state.

At minimum, the design should support:

- detecting which known runtimes are installed,
- presenting those runtimes to the user,
- remembering the selected runtime for the current session,
- and routing subsequent runtime operations through the selected backend.

The first implementation can still deliver one concrete backend first, but the product contract should already reflect runtime selection.

## Proposed Domain Model Additions

These names are illustrative. Exact naming can follow surrounding code style.

### Runtime kind

A type should represent supported runtime backends, for example:

- podman,
- docker,
- others only if intentionally supported.

### Runtime installation state

A type should represent whether the app found any supported runtime.

Possible cases:

- noSupportedRuntimeInstalled,
- oneRuntimeAvailable(runtimeKind),
- multipleRuntimesAvailable([runtimeKind]).

### Runtime selection

A type should represent the currently chosen runtime and any selected machine/context required by that runtime.

For example, Podman may require machine selection while another runtime may not.

### Oracle instance configuration

A configuration type should define the single supported Oracle Free container shape for this MVP.

Likely fields:

- container name,
- image reference,
- published database port,
- published management port if needed,
- environment values required to create the container,
- selected runtime,
- selected runtime context or machine if needed.

This may be represented as a fixed configuration with limited customization for the MVP.

### Container summary/state

A type should represent the container state relevant to the app.

Likely fields:

- container id,
- container name,
- image,
- state/status string or normalized enum,
- exposed ports,
- created/running metadata as needed.

### Oracle instance status

A higher-level status type should represent the app’s understanding of the Oracle instance, not just raw container state.

Possible cases:

- noSupportedRuntimeInstalled,
- runtimeSelectionRequired,
- runtimeContextSelectionRequired,
- inspecting,
- missing,
- creating,
- stopped,
- starting,
- running,
- ready(connectionInfo),
- deleting,
- failed(message).

Exact enum shape can vary, but readiness must be distinct from raw running state and missing-runtime state must be explicit.

### Connection info

A small value type should represent the connection details shown to the user.

Likely fields:

- host,
- port,
- service name or SID,
- username if fixed,
- optional convenience connection string.

## Runtime Boundary Changes

The current `PodmanRuntime` only supports machine discovery. The design should evolve toward a more general runtime boundary that supports the Oracle workflow while allowing backend-specific implementations.

Likely shared capabilities:

- detect runtime availability,
- enumerate runtime contexts if required,
- inspect a named container,
- list relevant containers,
- create container,
- start container,
- stop container,
- delete container,
- optionally fetch logs or probe command output for readiness.

The protocol should stay focused on runtime primitives. Oracle-specific orchestration should sit above it.

The first concrete implementation can still be Podman-first, but the design should leave room for additional runtime adapters.

## Runtime Detection Service

Add a dedicated service in `OracleFreeKit` responsible for discovering supported runtimes and exposing runtime availability to the app.

Responsibilities:

- detect whether known runtime CLIs are installed,
- expose the list of supported installed runtimes,
- provide user-facing state when none are installed,
- and help bootstrap runtime selection.

This service owns prerequisite detection, not the Oracle orchestration service.

## Oracle Orchestration Service

Add a dedicated service in `OracleFreeKit` that coordinates Oracle Database Free lifecycle behavior for the selected runtime context.

Responsibilities:

- decide the supported Oracle Free image/configuration,
- inspect whether the expected container exists,
- create it if missing,
- translate raw container state into app-ready instance status,
- determine when the database is ready,
- produce connection details for the UI,
- centralize Oracle-specific behavior so the UI and runtime adapter stay small.

This service becomes the main seam for unit tests around the Oracle product workflow.

## View Model Design

### Existing view models to preserve or evolve

- `AppViewModel` should evolve toward app-level orchestration state, including runtime availability.
- `MachineSelectionViewModel` may remain focused on machine/context selection for runtimes that require it.

### New runtime selection view model

Add a dedicated view model for runtime detection and runtime selection.

Responsibilities:

- load installed supported runtimes,
- expose “no runtime installed” state,
- let the user select a runtime when more than one is available,
- coordinate any next-step context selection required by the chosen runtime.

### New lifecycle view model

Add a dedicated view model for the Oracle instance workflow.

Responsibilities:

- react to selected runtime and selected context changes,
- inspect current Oracle instance state,
- expose Oracle instance status for the UI,
- trigger create/start/stop/delete actions,
- surface user-facing errors,
- expose connection details when ready,
- manage any polling or refresh behavior needed for lifecycle transitions.

This keeps runtime selection separate from Oracle lifecycle operations.

## UI Flow

### Root flow

The root flow should evolve into a staged experience:

1. runtime detection,
2. runtime selection when more than one supported runtime is available,
3. runtime context or machine selection when required,
4. Oracle instance management for the selected runtime context.

### Missing-runtime experience

If no supported runtime is detected, the app should present a clear state explaining:

- no supported container runtime was found,
- the app requires a supported runtime to be installed,
- installation must be done by the user,
- and the user can retry detection after installation.

The app should be informative here, not silently broken.

### UI states

The UI should clearly communicate:

- no supported runtime installed,
- runtime selection required,
- runtime context selection required,
- Oracle container missing,
- Oracle container being created,
- Oracle container stopped,
- Oracle container starting,
- Oracle running but not yet ready,
- Oracle ready,
- operation failure.

### Actions

Depending on state, the user should be able to:

- Retry runtime detection,
- Select runtime,
- Select machine/context if needed,
- Create Oracle Free container,
- Start,
- Stop,
- Delete,
- Refresh/reinspect.

The UI should not offer destructive or contradictory actions when the state does not support them.

## Readiness Strategy

This is one of the main technical risks in the MVP.

The implementation must not assume that a container being in a running state means Oracle Database Free is ready to accept connections.

The readiness strategy should therefore be isolated behind the Oracle-specific service. The exact mechanism can evolve, but the design should leave room for:

- inspecting container state,
- probing logs,
- running a readiness command,
- or using another deterministic signal.

The important requirement is that the app produces a stable, user-facing readiness state rather than exposing only raw container status.

## Error Handling

Error handling should preserve the current repo style:

- catch lower-level runtime errors,
- map them to readable messages,
- expose them via explicit view model state,
- and let SwiftUI render the error clearly.

Failure classes likely include:

- no supported runtime installed,
- runtime unavailable after selection,
- context or machine unavailable,
- container create/start/stop/delete failure,
- Oracle readiness timeout or readiness failure,
- invalid runtime output/parsing failures.

## Testing Strategy

The repository already uses Swift Testing and dependency injection. Keep leaning into that.

### Unit tests should cover

- runtime detection and runtime availability mapping,
- runtime selection state,
- runtime output parsing for the first concrete backend,
- Oracle service state mapping,
- lifecycle transitions,
- readable error propagation,
- view-model behavior under success and failure cases,
- readiness distinctions between running and ready.

### View tests should cover

- missing-runtime rendering,
- runtime selection rendering,
- major lifecycle state rendering,
- correct action visibility or labels for major states,
- high-value UI messaging.

Do not over-invest in brittle rendering assertions when the behavior can be tested more robustly in view models and services.

## Implementation Phases

### Phase 1 — Add runtime detection and selection foundation

Add runtime-kind models, runtime detection service, runtime availability state, and UI for missing-runtime and runtime-selection flows.

Deliverable:

- the app can detect supported runtimes, show when none are installed, and let the user choose among detected runtimes.

### Phase 2 — Generalize the runtime boundary and keep Podman as the first backend

Refactor the current Podman-specific boundary into a backend-friendly runtime abstraction, then implement the first concrete container lifecycle operations through Podman.

Deliverable:

- a backend-aware runtime layer with Podman as the first working implementation.

### Phase 3 — Add Oracle-specific orchestration

Add Oracle service types, instance status mapping, readiness modeling, and service tests for the selected runtime context.

Deliverable:

- Oracle workflow logic that can be exercised independently of SwiftUI.

### Phase 4 — Add lifecycle view model and UI

Add the Oracle lifecycle view model and extend the current views/root flow to render the new state machine and actions.

Deliverable:

- a usable end-to-end app flow from runtime selection to Oracle lifecycle management.

### Phase 5 — Polish and resilience

Add refresh behavior, better progress messaging, optional lightweight persistence, and final UX cleanup.

Deliverable:

- a more stable and understandable MVP without changing the core scope.

## Acceptance Criteria

The MVP is successful when all of the following are true:

1. The app can detect supported container runtimes.
2. If no supported runtime is installed, the app clearly informs the user and tells them installation is their responsibility.
3. If multiple supported runtimes are installed, the app lets the user choose one.
4. For runtimes that require a machine/context, the app supports selecting that context before container operations.
5. With a selected runtime context, the app can determine whether the expected Oracle Database Free container exists.
6. The app can create the Oracle Database Free container when missing.
7. The app can start, stop, and delete that container.
8. The app distinguishes between container running and database ready states.
9. The app shows usable connection details when the database is ready.
10. User-visible failures are readable and state-driven.
11. The new behavior is covered by Swift Testing tests in `OracleFreeKitTests`.
12. The app continues to follow the current target split and dependency-injection patterns.

## Risks and Deferred Decisions

### Known risks

- Runtime backends do not behave identically, so over-generalization would create fragile abstractions.
- Oracle image and startup behavior may be slower or less deterministic than raw container state suggests.
- Runtime CLI output shape may vary and should be isolated behind parsing logic.
- Destructive lifecycle operations can create confusing UX if state transitions are not explicit.

### Deferred decisions

These should remain explicitly deferred unless they become necessary during implementation:

- supporting more than one Oracle container,
- achieving full lifecycle parity across all supported runtime backends in the first pass,
- managing runtime installation/setup,
- storing secrets in Keychain or app settings,
- embedding advanced database tooling.

## Summary

The correct next step for this repository is not a wholesale redesign. It is a layered expansion of the current architecture into a runtime-selectable Oracle Database Free lifecycle app.

The existing repo already has the right foundations: SwiftUI state-driven views, injected runtime abstractions, and tests. The MVP should build on those foundations by adding runtime detection, runtime selection, a backend-aware runtime layer, an Oracle-specific orchestration layer, a dedicated lifecycle view model, and a small native UI for managing one Oracle Database Free container end to end.
