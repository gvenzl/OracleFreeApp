import SwiftUI

public enum OracleFreeWindowID {
    public static let main = "oracle-free-main"
}

public struct OracleContainerConfigurationDialogView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding private var settings: OracleContainerSettings

    public init(settings: Binding<OracleContainerSettings>) {
        self._settings = settings
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Container Configuration")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow {
                    Text("Image")
                    TextField("Image", text: settingBinding(\.image))
                        .textFieldStyle(.roundedBorder)
                }

                GridRow {
                    Text("Container Name")
                    TextField("Container Name", text: settingBinding(\.containerName))
                        .textFieldStyle(.roundedBorder)
                }

                GridRow {
                    Text("Host Port")
                    TextField(
                        "Host Port",
                        value: settingBinding(\.hostPort),
                        format: IntegerFormatStyle<Int>.number.grouping(.never)
                    )
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 96)
                }

                GridRow {
                    Text("Volume Name")
                    TextField("Volume Name", text: settingBinding(\.volumeName))
                        .textFieldStyle(.roundedBorder)
                }

                GridRow {
                    Text("Password")
                    TextField("Password", text: settingBinding(\.password))
                        .textFieldStyle(.roundedBorder)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Extra Environment Variables")

                Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 6) {
                    GridRow {
                        Text("Key")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Value")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("")
                    }

                    ForEach(Array(settings.extraEnvironmentVariables.indices), id: \.self) { index in
                        GridRow {
                            TextField("Key", text: environmentVariableNameBinding(at: index))
                                .textFieldStyle(.roundedBorder)
                            TextField("Value", text: environmentVariableValueBinding(at: index))
                                .textFieldStyle(.roundedBorder)
                            Button {
                                settings.extraEnvironmentVariables.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Remove Environment Variable")
                        }
                    }
                }

                Button("Add Variable") {
                    settings.extraEnvironmentVariables.append(
                        ContainerEnvironmentVariable(name: "", value: "")
                    )
                }
            }

            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 520)
    }

    private func settingBinding<Value>(_ keyPath: WritableKeyPath<OracleContainerSettings, Value>) -> Binding<Value> {
        Binding {
            settings[keyPath: keyPath]
        } set: { value in
            settings[keyPath: keyPath] = value
        }
    }

    private func environmentVariableNameBinding(at index: Int) -> Binding<String> {
        Binding {
            guard settings.extraEnvironmentVariables.indices.contains(index) else {
                return ""
            }

            return settings.extraEnvironmentVariables[index].name
        } set: { name in
            guard settings.extraEnvironmentVariables.indices.contains(index) else {
                return
            }

            let currentVariable = settings.extraEnvironmentVariables[index]
            settings.extraEnvironmentVariables[index] = ContainerEnvironmentVariable(
                name: name.uppercased(),
                value: currentVariable.value
            )
        }
    }

    private func environmentVariableValueBinding(at index: Int) -> Binding<String> {
        Binding {
            guard settings.extraEnvironmentVariables.indices.contains(index) else {
                return ""
            }

            return settings.extraEnvironmentVariables[index].value
        } set: { value in
            guard settings.extraEnvironmentVariables.indices.contains(index) else {
                return
            }

            let currentVariable = settings.extraEnvironmentVariables[index]
            settings.extraEnvironmentVariables[index] = ContainerEnvironmentVariable(
                name: currentVariable.name,
                value: value
            )
        }
    }
}
