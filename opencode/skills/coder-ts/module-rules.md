# TypeScript module code rules

Rules for TypeScript module code — `.ts`/`.tsx` files imported by other code.
These extend the generic module rules. All generic module rules still apply.

## Rules

- No shebang — modules are imported, not executed directly.
- Import types with `import type { ... }`, separate from value imports.
- Use named imports only — import a module's own exported namespace by name, never a default
  import or `import * as`.
- Prefer named exports over default exports.
- Reuse an exported type from the source module instead of redeclaring its shape.
- Use the `.ts` extension; use `.tsx` only when the file contains JSX.

## Guidelines

- Put private helpers after the exported API.
- Group related exports together.
