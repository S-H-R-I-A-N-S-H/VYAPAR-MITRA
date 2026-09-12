---
name: tdd
description: Enforces strict Test-Driven Development (TDD) workflow with Red-Green-Refactor cycles, rigorous boundary testing, and regression prevention for backend and frontend features.
---

# Test-Driven Development (TDD) Skill

## Core Philosophy
Never write functional implementation code before writing an automated test that fails for the right reason. Follow the strict Red-Green-Refactor rhythm for every single module, service, and endpoint.

## The TDD Cycle

### 1. Phase RED: Write a Failing Test
- Define the desired behavior from the feature specification (purpose, inputs, outputs, edge cases).
- Write a unit or integration test targeting the public interface of the module.
- Execute the test suite and verify that:
  1. The test **fails** (exit code != 0 or assertion error).
  2. The failure reason matches the missing capability (e.g., `AttributeError`, `AssertionError: expected X but got Y`), NOT a syntax error or broken test setup.

### 2. Phase GREEN: Make it Pass with Minimal Code
- Implement only the simplest code required to make the failing test pass.
- Do not introduce speculative generalizations or unneeded features at this stage.
- Re-run the test suite and confirm all tests pass cleanly.

### 3. Phase REFACTOR: Clean and Optimize
- Clean up duplicate logic, improve variable naming, and enhance readability.
- Ensure type hints and docstrings are complete.
- Verify that performance and error handling satisfy all acceptance criteria.
- Run tests again to guarantee zero regressions.

## Edge Case Checklist
Every feature test suite must test:
- **Boundary values**: Zero, negative, max limits, off-by-one thresholds.
- **Empty / Null values**: Missing optional fields, empty strings, None / null inputs.
- **Malformed inputs**: Invalid types, invalid formats, out-of-bounds ranges.
- **Exception paths**: Graceful error handling (e.g., custom HTTP exceptions, 4xx/5xx responses).
- **Concurrency & State isolation**: Tests must never leak database rows, files, or environment modifications.
