# Oracle Free App

Oracle Free App is a macOS app for running Oracle Database Free in a local container. It detects supported container runtimes, creates and manages one Oracle Database Free container, and shows the connection details needed to use the database.

The repository name and Swift package name remain `OracleFreeApp`.

## Requirements

- macOS 14 or newer
- Swift 6.1 or newer for local development
- One supported container runtime:
  - Docker, using the `docker` CLI
  - Podman, using the `podman` CLI
  - Rancher Desktop, using `rdctl` for detection and `nerdctl` for container commands

Podman machine management is only used for Podman. Docker and Rancher Desktop go directly to the Oracle Database Free lifecycle view.

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
```

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

If the volume name is empty, the app does not pass a `--volume` option to the runtime. When deleting Oracle Database Free, the app removes the container and the configured volume if a volume name is set.

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

On launch, the app detects installed runtimes. If multiple runtimes are available, it asks you to choose Docker, Podman, or Rancher Desktop.

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

## Troubleshooting

**No supported container runtime found**

Install Docker, Podman, or Rancher Desktop and make sure the required CLI command is on `PATH`.

**Rancher Desktop is not offered**

The app currently requires both `rdctl` and `nerdctl` to be available. Rancher Desktop must be installed and configured so its command line tools are reachable from the app environment.

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
