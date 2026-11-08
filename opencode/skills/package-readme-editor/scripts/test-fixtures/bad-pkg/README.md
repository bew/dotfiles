# demo-bad

Fixture for the mechanical-checks defect detection.

**Frame layout.** The period sits inside the span, which is a violation.

**Serialization**: The colon sits outside the span, which is correct.

**Payloads**:

```
fenced block after a blank line
```

**Input**:

- a list item after a blank line

---

## Missing on purpose

- `missing.rs`
- `src/lib.rs`

```
**Not a lead-in.**
```
