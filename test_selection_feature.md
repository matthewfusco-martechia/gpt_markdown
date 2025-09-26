# Test Selection Feature

This markdown content should be **fully selectable** with custom colors!

## Features Tested

1. **Regular text selection** - This paragraph should be selectable
2. **Bold text selection** - **This bold text** should also be selectable  
3. **Italic text selection** - *This italic text* should be selectable
4. **Code selection** - `This inline code` should be selectable
5. **List selection**:
   - First list item should be selectable
   - Second list item should be selectable
   - Third list item should be selectable

## Mathematical Content

Even mathematical expressions should be selectable:
- Simple math: 2 + 2 = 4
- Currency: The stock price is $24 per share
- Calculation: $24 * 100,000 shares = $2,400,000

## Code Block Selection

```dart
// This entire code block should be selectable
void main() {
  print('Hello, selectable world!');
}
```

## Selection Color Test

Try selecting text with different colors:
- Default system selection color (when selectionColor is null)
- Custom blue selection color
- Custom red selection color
- Custom green selection color

**Instructions**: 
1. Set `selectable: true` (default)
2. Set `selectionColor: Colors.blue` for blue selection
3. Set `selectionColor: Colors.red` for red selection
4. Set `selectionColor: null` for system default
