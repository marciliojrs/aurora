/// Re-exports `AuroraCore`, so `import Aurora` is the only import a caller needs.
///
/// Without this the split between the two modules leaks into every call site. `import Aurora` alone is
/// enough to *write* `.aurora(.regular, in: .rounded(cornerRadius: 20))` — member inference resolves
/// `.rounded` through the parameter's known type — but the moment a caller names a type it stops
/// compiling: `AuroraConfiguration`, `AuroraStyle`, `AuroraShape` and `AuroraColor` are all declared in
/// `AuroraCore`. That is the worst possible split, because the terse examples work and the ones people
/// reach for next do not.
///
/// `@_exported` is an underscored attribute rather than official API. It is stable and widely used for
/// exactly this, and the alternative is worse: a wall of `public typealias` kept in step with `AuroraCore`
/// by hand, which silently rots the first time a type is added.
@_exported import AuroraCore
