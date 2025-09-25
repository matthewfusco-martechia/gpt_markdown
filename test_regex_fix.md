# Test Regex Fix

## Your Input:
"Initial cost = $23\n Current value = $43"

## Old Regex Analysis:
`RegExp(r'\$([^$]+)\$')` would match:
- Match: `$23\n Current value = $43`
- Captured: `23\n Current value = ` 
- **PROBLEM**: Spans across newlines and multiple dollar signs!

## New Regex Analysis:
`RegExp(r'\$([^$\s\n]+)\$')` should match:
- Match 1: `$23` → Captured: `23`
- Match 2: `$43` → Captured: `43`
- **FIXED**: Individual patterns only!

## Expected Result:
- $23 → Currency detection → Currency mode
- $43 → Currency detection → Currency mode
- Decision: Currency mode (no math mode enabled)
- Rendering: Both show as regular text, not LaTeX
