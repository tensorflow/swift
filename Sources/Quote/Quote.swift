// Copyright 2019 The TensorFlow Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Statically-typed wrapper for an expression.
/// The phantom type `T` is a compile-type representation of `type`.
public class Quote<T>: CustomStringConvertible {
    public let expression: Expression
    public var type: Type { return expression.type }

    public init(_ expression: Expression) {
        self.expression = expression
    }
}

/// Specialized version of Quote that wraps closures with zero parameters.
public class FunctionQuote0<R>: Quote<() -> R> {}

/// Specialized version of Quote that wraps closures with one parameter.
public class FunctionQuote1<T1, R>: Quote<(T1) -> R> {}

/// Specialized version of Quote that wraps closures with two parameters.
public class FunctionQuote2<T1, T2, R>: Quote<(T1, T2) -> R> {}

/// Specialized version of Quote that wraps closures with three parameters.
public class FunctionQuote3<T1, T2, T3, R>: Quote<(T1, T2, T3) -> R> {}

/// Specialized version of Quote that wraps closures with four parameters.
public class FunctionQuote4<T1, T2, T3, T4, R>: Quote<(T1, T2, T3, T4) -> R> {}

/// Specialized version of Quote that wraps closures with five parameters.
public class FunctionQuote5<T1, T2, T3, T4, T5, R>: Quote<(T1, T2, T3, T4, T5) -> R> {}

/// Specialized version of Quote that wraps closures with six parameters.
public class FunctionQuote6<T1, T2, T3, T4, T5, T6, R>: Quote<(T1, T2, T3, T4, T5, T6) -> R> {}
