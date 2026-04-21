
import os
import re
import sys

filepath = r"d:\2. Organize\1. Projects\MiniProjectKPI_EWI\frontend\lib\services\api_service.dart"

print(f"Opening file: {filepath}")
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Very broad regex to find the approveExpense method body
# We look for the start of the method and capture everything until the next method or end of block
pattern = re.compile(r"(Future<Map<String, dynamic>> approveExpense\(.*?\)\s*async\s*\{)(.*?)(\})(\s*// categories)", re.DOTALL)

replacement_body = """
    final ep = action == 'reject' ? 'reject' : 'approve';
    final res = await http.post(
      Uri.parse('$baseUrl/expenses/$id/$ep'),
      headers: _headers,
      body: jsonEncode({'notes': notes}),
    );
    return _handleResponse(res);
  """

match = pattern.search(content)
if match:
    # match.group(1) is the header, match.group(3) is the closing brace, match.group(4) is the footer
    new_content = content[:match.start(2)] + replacement_body + content[match.end(2):]
    with open(filepath, 'w', encoding='utf-8', newline='\n') as f:
        f.write(new_content)
    print("SUCCESS: Pattern matched and replaced.")
else:
    print("FAILURE: Pattern not found.")
    # Show exactly what's at that line range for debugging
    idx = content.find("approveExpense")
    if idx != -1:
        print("DEBUG: Found approveExpense at position", idx)
        print("DEBUG: Snippet around it:")
        print(repr(content[idx:idx+200]))
    else:
        print("DEBUG: Could not even find 'approveExpense' string!")
