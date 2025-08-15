#!/usr/bin/env python3
"""
Fix JSON serialization issues in real_alphagenome_service.py
"""

def fix_json_serialization():
    """Fix the JSON serialization issues with OutputType objects"""
    
    # Read the file
    with open('real_alphagenome_service.py', 'r') as f:
        content = f.read()
    
    # Replace all instances of the problematic line
    old_pattern = '"requested_outputs": [ot for ot in requested_outputs if ot is not None]'
    new_pattern = '"requested_outputs": [ot.value if hasattr(ot, \'value\') else str(ot) for ot in requested_outputs if ot is not None]'
    
    # Count occurrences
    count = content.count(old_pattern)
    print(f"Found {count} occurrences to fix")
    
    # Replace
    content = content.replace(old_pattern, new_pattern)
    
    # Write back
    with open('real_alphagenome_service.py', 'w') as f:
        f.write(content)
    
    print("JSON serialization issues fixed!")

if __name__ == "__main__":
    fix_json_serialization()
