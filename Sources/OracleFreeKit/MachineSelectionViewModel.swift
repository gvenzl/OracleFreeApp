import Foundation
import Observation

@MainActor
@Observable
public final class MachineSelectionViewModel {
    public private(set) var status: PodmanMachineStatus
    public private(set) var selectedMachine: PodmanMachine?

    private var runtime: (any PodmanRuntime)?
    @ObservationIgnored private var machineReadyHandler: (@MainActor @Sendable (PodmanMachine) -> Void)?

    public init(
        runtime: (any PodmanRuntime)? = nil,
        selectedMachine: PodmanMachine? = nil,
        machineReadyHandler: (@MainActor @Sendable (PodmanMachine) -> Void)? = nil
    ) {
        self.runtime = runtime
        self.selectedMachine = selectedMachine
        self.machineReadyHandler = machineReadyHandler
        if let selectedMachine {
            self.status = selectedMachine.isRunning ? .selected(selectedMachine) : .stopped(selectedMachine)
        } else {
            self.status = .loading
        }
    }

    public func configure(
        runtime: any PodmanRuntime,
        machineReadyHandler: (@MainActor @Sendable (PodmanMachine) -> Void)? = nil
    ) {
        self.runtime = runtime
        self.machineReadyHandler = machineReadyHandler
        selectedMachine = nil
        status = .loading
    }

    public func reset() {
        runtime = nil
        machineReadyHandler = nil
        selectedMachine = nil
        status = .loading
    }

    public func loadMachines() async {
        guard let runtime else {
            status = .failed(message: "Podman runtime is not configured")
            return
        }

        status = .loading

        do {
            let machines = try await runtime.discoverMachines()
            updateStatus(for: machines)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            status = .failed(message: message)
        }
    }

    public func select(_ machine: PodmanMachine) {
        if machine.isRunning {
            markMachineReady(machine)
        } else {
            selectedMachine = machine
            status = .stopped(machine)
        }
    }

    public func startSelectedMachine() async {
        guard let runtime, let selectedMachine else {
            return
        }

        do {
            try await runtime.startMachine(named: selectedMachine.name)
            let runningMachine = PodmanMachine(
                id: selectedMachine.id,
                name: selectedMachine.name,
                isRunning: true,
                isDefault: selectedMachine.isDefault,
                connectionName: selectedMachine.connectionName
            )
            markMachineReady(runningMachine)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            status = .failed(message: message)
        }
    }

    private func updateStatus(for machines: [PodmanMachine]) {
        guard !machines.isEmpty else {
            selectedMachine = nil
            status = .noMachinesFound
            return
        }

        if machines.count == 1, let machine = machines.first, machine.isDefault {
            if machine.isRunning {
                markMachineReady(machine)
            } else {
                selectedMachine = machine
                status = .stopped(machine)
            }
            return
        }

        if let runningDefault = machines.first(where: { $0.isDefault && $0.isRunning }) {
            markMachineReady(runningDefault)
            return
        }

        selectedMachine = nil
        status = .selectionRequired(machines)
    }

    private func markMachineReady(_ machine: PodmanMachine) {
        selectedMachine = machine
        status = .selected(machine)
        machineReadyHandler?(machine)
    }
}
