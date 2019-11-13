struct GeneratorConfiguration {
    // MARK: - Project-level configs.
    var modulesPerProject: Int = 2

    // MARK: - Module-level configs.
    var filesPerModule: Int = 2

    // MARK: - File-level configs.
    var importsPerFile: Int = 2
    var protocolsPerFile: Int = 2
    var structsPerFile: Int = 2
    var functionsPerFile: Int = 4

    // MARK: - Protocol-level configs.
    var refinementsPerProtocol: Int = 2
    var requirementsPerProtocol: Int = 2

    // MARK: - Struct-level configs.
    var conformancesPerStruct: Int = 2
    var fieldsPerStruct: Int = 4

    // MARK: - Function-level configs.
    var genericArgumentsPerFunction: Int = 2
    var constraintsPerGenericArgument: Int = 1
    var argumentsPerFunction: Int = 3
}
