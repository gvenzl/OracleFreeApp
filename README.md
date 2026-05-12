# Oracle Free App

Oracle Free App is a macOS app for running Oracle Database Free in a local container. It detects supported container runtimes, creates and manages one Oracle Database Free container, and shows the connection details needed to use the database.

## Requirements

- macOS 14 or newer
- Swift 6.1 or newer for local development
- One supported container runtime:
  - Docker, using the `docker` CLI
  - Podman, using the `podman` CLI
  - Rancher Desktop, using `rdctl` for detection and `nerdctl` for container commands

Podman machine management is only used for Podman. Docker and Rancher Desktop go directly to the Oracle Database Free lifecycle view.

The app resolves runtime commands by checking common macOS install locations before falling back to the launch environment's `PATH`. This keeps packaged/Finder launches from depending solely on a terminal shell configuration.

## Running Locally

Use the project script from the repository root:

```bash
./script/build_and_run.sh
```

The script builds the Swift package, creates `dist/Oracle Free App.app`, and launches the app bundle. It also stops any existing `OracleFreeApp` process before relaunching.

Useful variants:

```bash
./script/build_and_run.sh --verify
./script/build_and_run.sh --logs
./script/build_and_run.sh --telemetry
./script/build_and_run.sh --debug
./script/build_and_run.sh --package
```

The `--package` mode creates a disk image at `dist/Oracle Free App-1.0.0.dmg`. The assembled `.app` inside the DMG is ad hoc signed so its bundle resources validate correctly, but it is not Developer ID signed, notarized, or ready for Gatekeeper distribution.

## Default Container Configuration

The default settings are:

- Image: `ghcr.io/gvenzl/oracle-free`
- Container name: `oracle-free`
- Host port: `1521`
- Container port: `1521`
- Volume: `oracle-free-data`
- Password: `OracleFree123`
- Environment: `ORACLE_PASSWORD=OracleFree123`

Open **Configuration** from the main view or menu bar item to change the image, container name, host port, volume name, password, and extra environment variables before creating the container.

Configuration changes are persisted in a JSON file under the user's Application Support folder and are reloaded on the next app start.

If the volume name is empty, the app does not pass a `--volume` option to the runtime. When deleting Oracle Database Free and a volume is configured, the delete dialog lets you choose whether to preserve that volume or delete it alongside the container.

## Connection Details

Once the container is ready, the app displays selectable connection details:

- Host: `localhost`
- Port: configured host port, default `1521`
- Service: `FREEPDB1`
- Username: `system`
- Password: configured password, default `OracleFree123`
- Connection string: `system/OracleFree123@localhost:1521/FREEPDB1`

The password is shown in clear text because it is local container configuration needed for connecting to the database.

## Runtime Behavior

On launch, the app detects installed runtimes. If multiple runtimes are available, it asks you to choose Docker, Podman, or Rancher Desktop. After a runtime is selected, the main window shows the active runtime and offers a **Change Runtime** button when more than one runtime is available.

Runtime detection records the resolved executable paths and reuses those paths for later container commands. Current lookup locations include Docker.app, Rancher Desktop.app, `~/.rd/bin`, `/opt/homebrew/bin`, `/usr/local/bin`, and standard system binary directories.

For Podman, the app loads available Podman machines. A single running default machine is selected automatically. Otherwise, the app shows the machine list or a start button for a stopped machine.

The app checks the container health status and only marks Oracle Database Free as ready once the runtime reports a healthy container. While the container is starting or after failures, the app can show recent container logs.

When the app quits or the main window closes, it attempts to stop the Oracle Database Free container.

## Development

Build:

```bash
swift build
```

Run all tests:

```bash
swift test
```

List tests:

```bash
swift test list
```

Run one test suite:

```bash
swift test --filter 'OracleFreeKitTests.RootViewTests'
```

This project uses Swift Testing, not XCTest.

## Continuous Integration

GitHub Actions workflows are defined under `.github/workflows/`:

- `tests.yml` runs `swift build` and `swift test`.
- `build-app.yml` is on-demand only, runs `./script/build_and_run.sh --package`, and uploads the ad hoc signed, non-notarized app archive as an artifact. When manually dispatching the workflow, enable `publish_release` and provide `release_tag` to publish the DMG directly as a GitHub Release.

Both workflows run on `macos-15`.

## Troubleshooting

**No supported container runtime found**

Install Docker, Podman, or Rancher Desktop. The app checks common macOS install locations and then falls back to `PATH`; if you installed a runtime somewhere custom, add its CLI to `PATH` or symlink it into a common location such as `/opt/homebrew/bin` or `/usr/local/bin`.

**Rancher Desktop is not offered**

The app currently requires both `rdctl` and `nerdctl` to be available. Rancher Desktop must be installed and configured so its command line tools are available in Rancher Desktop.app, `~/.rd/bin`, or another location the app can resolve.

**Configuration warning on startup or save**

The app stores container configuration as JSON in the user's Application Support folder. If that file is corrupt or cannot be written, the app shows a configuration warning, uses defaults when loading fails, and keeps the current in-memory values when saving fails.

**Podman machine cannot be started**

Check Podman directly:

```bash
podman machine list
podman machine start <machine-name>
podman ps
```

**Port conflict while creating Oracle Database Free**

Another process or container is already using the configured host port. Change the host port in Configuration or stop the other process/container.

**Image pull failure**

Check the configured image name and network access. The default image is `ghcr.io/gvenzl/oracle-free`.

**Container stays in starting state**

Oracle Database Free can take a while to initialize on first startup. Check the container logs shown in the app. You can also inspect them directly:

```bash
docker logs --tail 120 oracle-free
podman logs --tail 120 oracle-free
nerdctl logs --tail 120 oracle-free
```

Use the command for the runtime you selected.
