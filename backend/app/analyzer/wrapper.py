import asyncio
import json
import os
from typing import Dict, Any

# Path to the binary compiled by Docker
ANALYZER_BIN_PATH = "/app/analyzer/build/mergelens-analyzer"

async def analyze_file(filepath: str) -> Dict[str, Any]:
    """
    Executes the native C++ Tree-sitter analyzer on a given file.
    """
    if not os.path.exists(filepath):
        return {"error": f"File not found: {filepath}"}

    try:
        # Run the C++ binary asynchronously
        process = await asyncio.create_subprocess_exec(
            ANALYZER_BIN_PATH, filepath,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        stdout, stderr = await process.communicate()
        
        if stdout:
            # Parse the JSON output from the C++ binary
            return json.loads(stdout.decode('utf-8'))
        else:
            return {"error": "Analyzer produced no output", "details": stderr.decode('utf-8')}
            
    except json.JSONDecodeError as e:
        return {"error": "Failed to parse analyzer JSON output", "details": str(e)}
    except Exception as e:
        return {"error": "Failed to execute analyzer", "details": str(e)}