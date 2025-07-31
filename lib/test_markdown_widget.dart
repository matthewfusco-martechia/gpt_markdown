import 'package:flutter/material.dart';
import 'markdown_widget.dart';

class TestMarkdownWidget extends StatelessWidget {
  const TestMarkdownWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const testMarkdown = '''
# Main Heading
This is a test of the enhanced markdown widget with all the new features!

## Subheading
Here's some **bold text** and *italic text* and `inline code`.

### Enhanced LaTeX Math
Simple inline math: \\( x = 5 \\)

More complex inline: \\( x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a} \\)

Display math with professional UI:
\\[
\\int_{-\\infty}^{\\infty} e^{-x^2} \\, dx = \\sqrt{\\pi}
\\]

Chemical kinetics equation:
\\[
k = A e^{-\\frac{E_a}{RT}}
\\]

You can also use dollar syntax: $$ E = mc^2 $$

### Code Blocks
Here's a Python code block:

```python
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)

print(fibonacci(10))
```

### Tables
| Feature | Status | Notes |
|---------|--------|-------|
| Headings | ✅ | Customizable sizes |
| LaTeX | ✅ | Professional UI |
| Code | ✅ | Syntax highlighting |

### Lists
1. First item
2. Second item
   - Nested bullet
   - Another bullet
3. Third item

### Links and More
Check out [this link](https://flutter.dev) and see how it looks!

> This is a blockquote with some **bold** text and `inline code`.

### Think Block Test
<think>
This is some thinking content with LaTeX: \\( \\alpha + \\beta = \\gamma \\)

And some code:
```dart
void main() {
  print('Hello from think block!');
}
```
</think>

---

That's it! The LaTeX should now have professional dark UI with copy, share, and expand buttons.
''';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Markdown Widget'),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[900],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: MarkdownWidget(
          data: testMarkdown,
          fontSize: 16.0,
          mdcolor: Colors.white,
          iconFillColor: Colors.blueAccent,
          iconBorderColor: Colors.blueAccent,
          linkContainerColor: Colors.lightBlueAccent,
        ),
      ),
    );
  }
}

// Simple app to run the test
class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Markdown Widget Test',
      theme: ThemeData.dark(),
      home: const TestMarkdownWidget(),
      debugShowCheckedModeBanner: false,
    );
  }
}

void main() {
  runApp(const TestApp());
} 