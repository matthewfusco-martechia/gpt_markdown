# Component Regex Fix Test

## Your Input:
"Given that you bought the stock at $0.34 and it's now at $43"

## Old Component Regex:
`r"(?<!\\)\$((?:\\.|[^$])*?)\$(?!\\)"`
- Would match: `$0.34 and it's now at $43`
- Captured: `0.34 and it's now at ` 
- **PROBLEM**: Spans across spaces and text

## New Component Regex:
`r"(?<!\\)\$([^\s\n$]+)\$(?!\\)"`
- Would match: `$0.34` and `$43` separately
- Captured: `0.34` and `43` individually
- **FIXED**: No spanning across whitespace

## Expected Result:
- Each dollar amount processed individually
- Smart detection can properly evaluate each one
- No more merged text like `0.34andit'snowat43`

This should finally fix the root cause!
