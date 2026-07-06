from typing import TypedDict, List, Dict, Any, Optional

class ReviewState(TypedDict):
    file_path: str
    patch: str
    language: str
    # Data provided by our C++ core tool
    cpp_structure: Optional[Dict[str, Any]]
    # AI generated analysis layers
    structural_intent: Optional[str]
    review_comments: List[Dict[str, Any]]
    next_step: str