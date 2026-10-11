# Chance – SDLC

How Chance is built, one document per phase of the software development
life cycle:

| Phase | Document | Output in the repo |
|---|---|---|
| 1. Requirements gathering & analysis | [01-requirements.md](01-requirements.md) | Requirement IDs F1–F13, N1–N6 |
| 2. System architecture & design | [02-architecture.md](02-architecture.md) | Layered design, lesson engine contract |
| 3. Implementation | [03-implementation.md](03-implementation.md) | `lib/` |
| 4. Quality assurance & testing | [04-testing.md](04-testing.md) | `test/`, CI checks |
| 5. Release & deployment | [05-release.md](05-release.md) | `.github/workflows/ci.yml`, signing config |
| 6. Ongoing maintenance & enhancements | [06-maintenance.md](06-maintenance.md) | `CHANGELOG.md`, roadmap |

Each phase feeds the next and loops back: test failures go back to
implementation, store feedback goes back to requirements.
