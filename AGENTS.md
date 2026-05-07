# AGENTS.md

This document aims to standardize the development of the Gleam Agent framework, unify team coding style, module design, and collaboration processes, and improve readability and maintainability.

## Git Workflow
- Before submitting code, be sure to perform gleam format, gleam test, and gleam build.
- Break the entire task down into multiple units, with code submissions for each unit, and each submission consisting of 3-6 files.

## Command
- gleam format // Format code
- gleam build // Build project
- gleam test // Test project

## Code style

1. File and Module Naming

- File names and module names should use snake_case.
- Module names start with lowercase, e.g., math_utils.gleam → module name math_utils.
- One main module per file; avoid defining multiple modules in a single file.

2. Function Naming
- Use snake_case.
- Function names should describe the action, e.g., calculate_sum.
- Avoid single-letter names unless common conventions (e.g., id).

3. Variable Naming

- Use snake_case.
- Constants use UPPER_SNAKE_CASE, e.g., MAX_RETRIES.
- Use meaningful names; avoid x, y, tmp unless in a small local context.

4. Types and Type Aliases
- Type aliases use PascalCase.
- Enum constructors use PascalCase, e.g.:
- type Color {  Red  Green  Blue}

5. Function Parameters and Type Annotations

- Public functions should always have type annotations.
- For functions with many parameters, break lines and indent 2 spaces per line:
- pub fn add_user(  name: String,  age: Int,  email: String) -> Result(User, String) {  ...}

6. Function Length and Complexity

- Keep functions small; each function should do one thing.
- Use private helper functions for complex logic.
- Prefer pure functions; avoid side effects unless explicitly handling IO.

7. Control Flow

- Use pattern matching instead of nested if/else:
- case user_status {  Active -> Ok("Active")  Inactive -> Ok("Inactive")  _ -> Error("Unknown status")}
- Avoid deep nesting; consider early returns.

8. Comments and Documentation

- Public functions should have doc comments /// describing functionality and parameters:
```gleam
/// Calculate the sum of two integerspub fn sum(a: Int, b: Int) -> Int {  a + b}
```
- Use regular comments // for internal logic; keep them concise.

9.  Error Handling
- Use Result or Option for potentially failing operations.
- Avoid exceptions or panic unless unavoidable.

10.  Tests and Documentation

- Each module should have at least one test module:
```gleam
pub fn add(a: Int, b: Int) -> Int {  a + b}test "sum of two numbers" {  assert add(1, 2) == 3}
```
- Test functions use snake_case and describe the purpose clearly.


11. Imports and Dependencies
- Import modules alphabetically.
- Avoid wildcard or overly broad imports; keep code readable.

## Reference Links
Official Documentation

- https://gleam.run/docs/