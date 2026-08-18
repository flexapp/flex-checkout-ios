# Review.md (Entrypoint)
Load the guidelines from current repo and apply them while reviewing the code.
## Load order (apply in this order)
- /review-guidelines/base/*.md
- /review-guidelines/profiles/mysql-java.md - **ONLY** load this guideline if the PR includes SQL or Java changes.
- /review-guidelines/profiles/testing-requirements-java.md - **ONLY** load this guideline if the PR includes Java changes.
- /review-guidelines/profiles/testing-requirements-genoa.md - **ONLY** load this guideline if the PR is in the Flexapp Genoa repo.
- /review-guidelines/service/*.md

## Precedence rules
- Base modules apply to all repos.
- Service/profiles overlays only apply when relevant (matching language, framework, or service type).
- If a rule conflicts, the *more specific* module wins (service > profile > base).
