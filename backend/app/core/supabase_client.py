from supabase import create_client, Client
from app.core.config import settings

def get_supabase_client() -> Client:
    """
    Initializes and returns a synchronous Supabase client.
    Used for database persistence and querying.
    """
    return create_client(settings.supabase_url, settings.supabase_key)

supabase = get_supabase_client()