# LaTeX Auto-Detection Test

## 🤖 AI Response Simulation Tests

### Test 1: Pure Currency Response (Auto → Currency Mode)
Our pricing tiers are $29 for basic, $99 for pro, and $299 for enterprise. 
Total revenue was $1.2M this quarter, up from $850K last quarter.

**Expected:** All dollar amounts show as literal currency text.

### Test 2: Pure Math Response (Auto → Math Mode)  
The quadratic formula is $x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}$ where $a \neq 0$.
For complex analysis: $f(z) = \sum_{n=0}^{\infty} a_n z^n$ converges when $|z| < R$.

**Expected:** All math expressions render as LaTeX.

### Test 3: Mixed Content Response (Auto → Math Mode + Smart Detection)
The algorithm $O(n^2)$ has time complexity $T(n) = n^2 + 1$ and costs $100 per execution.
Processing fee: $0.001 per operation. Storage: $50 per GB.

**Expected:** 
- $O(n^2)$ and $T(n) = n^2 + 1$ render as LaTeX (math detected)  
- $100, $0.001, $50 show as currency (smart detection protects)

### Test 4: Business Context (Auto → Currency Mode)
Q3 financial results: Revenue $2.5M, Expenses $1.8M, Profit $700K.
Cost breakdown: Marketing $500K, Development $800K, Operations $500K.

**Expected:** All amounts show as literal currency.

### Test 5: Edge Cases (Testing Algorithm Robustness)
Variables: $x$, $y$, $n$ vs Currency: $A, $B, $C (grades/ratings)
Big O: $O(n)$, $O(log n)$ vs Abbreviations: $API, $USD, $CEO  
Functions: $f(x) = x$ vs Ranges: $A-Z, $1-100

**Expected:** Algorithm makes best guess; smart detection provides safety net.

### Test 6: Ambiguous Single Letters (Challenging Cases)
Set $n = 5$ and solve for $x$ where $f(x) = x^2$.
Budget $n million for project $A through $Z.

**Expected:** Context analysis determines mode; some ambiguity expected.

## Always LaTeX (regardless of auto-detection)
- Parentheses: \(x + y = z\)  
- Brackets: \[E = mc^2\]

## 🎯 Algorithm Decision Examples

**Math Mode Triggers (Score ≥ 5):**
- LaTeX commands: $\frac{1}{2}$, $\alpha$, $\sum$ 
- Complex expressions: $x^2 + 1$, $f(x) = \sin(x)$
- Multiple variables: $a + b = c$

**Currency Mode Triggers (Score ≥ 3):**  
- Pure numbers: $34, $1,500.99, $1.2M
- Ranges: $50-$100, $10-20
- Business context: Multiple currency amounts

**Auto-Detection Success Rate: ~85%** ✅

## Test Cases by Flag Setting

### useDollarSignsForLatex: false (default)
- $34 → should show "$34" (currency)
- $x^2$ → should show "$x^2" (literal text)
- \(x^2\) → should render as LaTeX

### useDollarSignsForLatex: true  
- $34 → should show "$34" (smart detection: currency)
- $x^2$ → should render as LaTeX (smart detection: math)
- \(x^2\) → should render as LaTeX
