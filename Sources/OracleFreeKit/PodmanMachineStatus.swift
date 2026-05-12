public enum PodmanMachineStatus: Equatable, Sendable {
    case loading
    case noMachinesFound
    case selectionRequired([PodmanMachine])
    case stopped(PodmanMachine)
    case starting(PodmanMachine)
    case selected(PodmanMachine)
    case failed(message: String)
}
