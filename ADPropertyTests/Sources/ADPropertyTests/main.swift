/// Parsed command line arguments.
struct Invocation {
    let swiftc: String
}

/// Judges whether a compilation result is interesting.
enum Judgement: Hashable, Equatable {
    case interesting

    case boringSuccess
    case boringTimeout

    // MARK: - Known failures.

    case boringTF891
    case boringTF961
}

extension Judgement {
    init(_ result: ExecutionResult) {
        if result.status.isSuccess {
            self = .boringSuccess
            return
        }
        if result.status == .compileTimeout {
            self = .boringTimeout
            return
        }
        if result.contains(
            "bool isLargeLoadableType(swift::GenericEnvironment *, swift::SILType, irgen::IRGenModule &): Assertion `GenericEnv && \"Expected a GenericEnv\"' failed."
        ) {
            self = .boringTF961
            return
        }
        if result.contains(
            "swift::ProtocolDecl *swift::ProtocolConformanceRef::getRequirement() const: Assertion `!isInvalid()' failed"
        ) {
            self = .boringTF891
            return
        }
        self = .interesting
    }
}

extension Invocation {
    /// Generates a random AST and compiles it. Returns the AST and the compilation result.
    func attempt() -> (AST, ExecutionResult) {
        let ast = AST()
        ast.project.generate(GeneratorConfiguration())
        let result = ast.project.compile(swiftc: swiftc)
        return (ast, result)
    }

    /// Compiles random ASTs until finding an interesting result. Returns the interesting AST and
    /// result.
    func attemptUntilInteresting() -> (AST, ExecutionResult) {
        var judgements: [Judgement: Int] = [:]
        for attemptIndex in 0... {
            let (ast, result) = attempt()
            let judgement = Judgement(result)
            if judgement == .interesting {
                return (ast, result)
            }
            judgements[judgement, default: 0] += 1
            if attemptIndex % 10 == 0 {
                print(ast.project.code)
            }

            print(judgements.map { "\($0.key): \($0.value)" }.sorted().joined(separator: ", "))
        }
        fatalError("should never reach this")
    }

    func reduceInteresting(_ ast: AST) -> (AST, ExecutionResult) {
        // TODO: Implement reduction.
        let result = ast.project.compile(swiftc: swiftc)
        return (ast, result)
    }
}

func main() {
    guard CommandLine.arguments.count == 2 else {
        print("Must specify swiftc path")
        return
    }

    let invocation = Invocation(swiftc: CommandLine.arguments[1])
    print(invocation)

    let (ast, result) = invocation.attemptUntilInteresting()
    print("Found interesting AST")
    print(ast.project.code)
    print(result)
    print("")
    print("")

    let (reducedAst, reducedResult) = invocation.reduceInteresting(ast)
    print("Reduced AST")
    print(reducedAst.project.code)
    print(reducedResult)
}

main()
