# auth.py

import jwt
import requests
from fastapi import Header, HTTPException
from config import SUPABASE_URL

# Cache the public key
_public_key = None

def get_public_key():
    global _public_key
    if _public_key is None:
        jwks_url = f"{SUPABASE_URL}/.well-known/jwks.json"
        response = requests.get(jwks_url)
        response.raise_for_status()
        jwks = response.json()
        # Assuming the first key is the one to use
        key_data = jwks['keys'][0]
        _public_key = jwt.algorithms.ECAlgorithm.from_jwk(key_data)
    return _public_key

def get_user_id(authorization: str = Header(...)):
    try:
        token = authorization.replace("Bearer ", "")

        # Decode header to get algorithm
        header = jwt.get_unverified_header(token)
        alg = header.get("alg")

        if alg == "ES256":
            public_key = get_public_key()
            algorithms = ["ES256"]
        else:
            # Fallback, but probably not needed
            raise HTTPException(status_code=401, detail="Unsupported algorithm")

        payload = jwt.decode(
            token,
            public_key,
            algorithms=algorithms,
            audience="authenticated"
        )

        user_id = payload.get("sub")

        if not user_id:
            raise HTTPException(status_code=401, detail="Invalid token")

        return user_id

    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))