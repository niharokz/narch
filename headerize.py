#!/usr/bin/env python3
 
#
#       ███╗   ██╗██╗██╗  ██╗ █████╗ ██████╗ ███████╗
#       ████╗  ██║██║██║  ██║██╔══██╗██╔══██╗██╔════╝
#       ██╔██╗ ██║██║███████║███████║██████╔╝███████╗
#       ██║╚██╗██║██║██╔══██║██╔══██║██╔══██╗╚════██║
#       ██║ ╚████║██║██║  ██║██║  ██║██║  ██║███████║
#       ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
#       DRAFTED BY [https://nih.ar] ON 01-06-2025
#       SOURCE [headerize.py] LAST MODIFIED ON 01-06-2025
#

import sys
import os
from datetime import datetime
import pathlib

def main():
    if len(sys.argv) < 2:
        print("Usage: headerize <filename>")
        sys.exit(1)

    file_path = sys.argv[1]
    file_name = os.path.basename(file_path)
    ext = pathlib.Path(file_path).suffix.lower()
    today = datetime.now().strftime("%d-%m-%Y")  # DD-MM-YYYY format
    website = "https://nih.ar"

    # Determine comment prefix and shebang
    comment = "#"
    shebang = ""
    if ext in [".go", ".js", ".ts", ".java", ".c", ".cpp", ".h", ".rs", ".kt", ".swift", ".scala", ".php"]:
        comment = "//"
    elif ext in [".hs", ".lua"]:
        comment = "--"
    elif ext in [".py", ".sh", ".yaml", ".yml", ".toml", ".json", ".rb", ".vim", ".bash"]:
        comment = "#"
        if ext == ".py":
            shebang = "#!/usr/bin/env python3"
        elif ext in [".sh", ".bash"]:
            shebang = "#!/bin/bash"

    # Define header lines
    header_lines = [
        f" ",
        f"{comment}",
        f"{comment}       ███╗   ██╗██╗██╗  ██╗ █████╗ ██████╗ ███████╗",
        f"{comment}       ████╗  ██║██║██║  ██║██╔══██╗██╔══██╗██╔════╝",
        f"{comment}       ██╔██╗ ██║██║███████║███████║██████╔╝███████╗",
        f"{comment}       ██║╚██╗██║██║██╔══██║██╔══██║██╔══██╗╚════██║",
        f"{comment}       ██║ ╚████║██║██║  ██║██║  ██║██║  ██║███████║",
        f"{comment}       ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝",
        f"{comment}       DRAFTED BY [{website}] ON {today}",
        f"{comment}       SOURCE [{file_name}] LAST MODIFIED ON {today}",
        f"{comment}",
    ]
    header = "\n".join(header_lines) + "\n"

    # Read file content
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"Error reading file: {e}")
        sys.exit(1)

    # Split content into lines
    lines = content.split("\n")
    existing_shebang = ""
    content_start = 0

    # Check for existing shebang
    if lines and lines[0].startswith("#!"):
        existing_shebang = lines[0] + "\n"
        content_start = 1

    # Check if header already exists
    if f"DRAFTED BY [{website}]" in content:
        for i in range(content_start, len(lines)):
            if "SOURCE [" in lines[i] and "LAST MODIFIED ON" in lines[i]:
                lines[i] = f"{comment}       SOURCE [{file_name}] LAST MODIFIED ON {today}"
                break
        new_content = "\n".join(lines)
    else:
        # Use existing shebang if present, otherwise use the defined shebang
        shebang_line = existing_shebang if existing_shebang else (shebang + "\n" if shebang else "")
        new_content = shebang_line + header + "\n".join(lines[content_start:])

    # Write updated content
    try:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
    except Exception as e:
        print(f"Error writing file: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
