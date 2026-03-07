from pydantic import BaseModel
from typing import Optional, List

class SearchRequest(BaseModel):
    query: str
    filter: Optional[str] = None