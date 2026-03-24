
import os
import re
import sys

filepath = r"lib\services\api_service.dart"

print(f"Opening file: {filepath}")
try:
    if not os.path.exists(filepath):
        print(f"Error: {filepath} not found from {os.getcwd()}")
        sys.exit(1)

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Broad regex
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
        new_content = content[:match.start(2)] + replacement_body + content[match.end(2):]
        with open(filepath, 'w', encoding='utf-8', newline='\n') as f:
            f.write(new_content)
        print("SUCCESS: Pattern matched and replaced.")
    else:
        print("FAILURE: Pattern not found.")
        idx = content.find("approveExpense")
        if idx != -1:
            print(f"DEBUG: Found 'approveExpense' at position {idx}")
            print(f"DEBUG: Snippet: {repr(content[idx:idx+100])}")
except Exception as e:
    print(f"CRITICAL ERROR: {str(e)}")
