import Quote

protocol A {
}

protocol B {
}

class Context {
  public init() {}
  static let local = Context()
}

enum E {
  case a
}

func f() -> P {
  fatalError("")
}

public func g() {
}

protocol P {
  func m()
}

class X: Error {
}

extension FunctionQuote0 {
  @discardableResult
  public func callAsFunction() -> R {
    fatalError("implement me")
  }
}

extension FunctionQuote1 {
  @discardableResult
  public func callAsFunction(_ t1: T1) -> R {
    fatalError("implement me")
  }
}

extension FunctionQuote2 {
  @discardableResult
  public func callAsFunction(_ t1: T1, _ t2: T2) -> R {
    fatalError("implement me")
  }
}

extension FunctionQuote3 {
  @discardableResult
  public func callAsFunction(_ t1: T1, _ t2: T2, _ t3: T3) -> R {
    fatalError("implement me")
  }
}

extension FunctionQuote4 {
  @discardableResult
  public func callAsFunction(_ t1: T1, _ t2: T2, _ t3: T3, _ t4: T4) -> R {
    fatalError("implement me")
  }
}
