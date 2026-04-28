import os
import re

files_to_clean = [
    r'd:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\routes\reports\annual.py',
    r'd:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\routes\reports\helpers.py'
]

emoji_pattern = re.compile(r'[^\x00-\x7f]')

for file_path in files_to_clean:
    if os.path.exists(file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        new_content = emoji_pattern.sub('?', content)
        
        if new_content != content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"Cleaned {file_path}")
        else:
            print(f"No non-ASCII found in {file_path}")
    else:
        print(f"File not found: {file_path}")
