// RUN: %target-swift-frontend -typecheck %s -verify

// MARK: - Correct type eraser

class AnyP: P1 {
  init<T: P1>(erasing t: T) {}
}

@_typeEraser(AnyP) // okay
protocol P1 {}

// MARK: - Parsing Errors

@_typeEraser // expected-error {{expected '(' in '_typeEraser' attribute}}
protocol A1 {}

@_typeEraser() // expected-error {{expected a type name in @_typeEraser()}}
protocol A2 {}

@_typeEraser(AnyP // expected-note {{to match this opening '('}}
protocol A3 {} // expected-error {{expected ')' after type name for @_typeEraser}}

@_typeEraser(AnyP) // expected-error {{@_typeEraser may only be used on 'protocol' declarations}}
func notAProtocol() {}

// MARK: - Type eraser must be a concrete nominal type

@_typeEraser(Undeclared) // expected-error {{use of undeclared type 'Undeclared'}}
protocol B1 {}

@_typeEraser((Int, Int)) // expected-error {{type eraser must be a class, struct, or enum}}
protocol B2 {}

protocol InvalidTypeEraser {}
@_typeEraser(InvalidTypeEraser) // expected-error {{type eraser must be a class, struct, or enum}}
protocol B3 {}

class Generic<Param>: B5 { // expected-note {{generic type 'Generic' declared here}}
  init<T: B5>(erasing t: T) {}
}
@_typeEraser(Generic) // expected-error {{reference to generic type 'Generic' requires arguments in <...>}}
protocol B4 {}
@_typeEraser(Generic<Int>) // bound generic is okay
protocol B5 {}

// MARK: - Type eraser must conform to the annotated protocol

class DoesNotConform {} // expected-note {{type eraser declared here}}
@_typeEraser(DoesNotConform) // expected-error {{type eraser 'DoesNotConform' must conform to protocol 'C1'}}
protocol C1 {}

// MARK: - Type eraser must have an initializer in the form init<T>(erasing: T) with T constrained to annotated protocol

class NoArgInit: D1 {} // expected-note {{type eraser declared here}}
@_typeEraser(NoArgInit) // expected-error {{type eraser 'NoArgInit' must have an initializer of the form 'init<T: 'D1'>(erasing: T)'}}
protocol D1 {}

class InvalidArgInit: D2 { // expected-note {{type eraser declared here}}
  init<T>(erasing t: T) {}
}
@_typeEraser(InvalidArgInit) // expected-error {{type eraser 'InvalidArgInit' must have an initializer of the form 'init<T: 'D2'>(erasing: T)'}}
protocol D2 {}

class ExtraArgInit: D3 { // expected-note {{type eraser declared here}}
  init<T: D3>(erasing t: T, extraArg: Int) {}
}
@_typeEraser(ExtraArgInit) // expected-error {{type eraser 'ExtraArgInit' must have an initializer of the form 'init<T: 'D3'>(erasing: T)'}}
protocol D3 {}

class WrongLabelInit: D4 { // expected-note {{type eraser declared here}}
  init<T: D4>(wrongLabel: T) {}
}
@_typeEraser(WrongLabelInit) // expected-error {{type eraser 'WrongLabelInit' must have an initializer of the form 'init<T: 'D4'>(erasing: T)'}}
protocol D4 {}

class NoLabel: D5 { // expected-note {{type eraser declared here}}
  init<T: D5>(_ t: T) {}
}
@_typeEraser(NoLabel) // expected-error {{type eraser 'NoLabel' must have an initializer of the form 'init<T: 'D5'>(erasing: T)'}}
protocol D5 {}

class FailableInit: D6 {
  init?<T: D6>(erasing t: T) {} // expected-note {{type eraser initializer declared here}}
}
@_typeEraser(FailableInit) // expected-error {{type eraser initializer must not be failable}}
protocol D6 {}
