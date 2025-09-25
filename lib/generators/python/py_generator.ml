open Printf
open Ast.Auth_types

(** Generate Python OAuth2 client code *)
let generate_oauth2_client (spec : auth_spec) (provider : provider) =
  sprintf {|
"""
Generated Python OAuth 2.0 Client
Specification: %s
Provider: %s
Generated at: %s
"""

import base64
import hashlib
import json
import secrets
import urllib.parse
from typing import Dict, List, Optional, Union
from dataclasses import dataclass
import requests


@dataclass
class AuthConfig:
    """Configuration for OAuth2 authentication"""
    client_id: str
    redirect_uri: str
    scopes: Optional[List[str]] = None
    extra_params: Optional[Dict[str, str]] = None


@dataclass
class TokenSet:
    """OAuth2 token response"""
    access_token: str
    expires_in: int
    token_type: str
    refresh_token: Optional[str] = None
    scope: Optional[str] = None


class AuthError(Exception):
    """OAuth2 authentication error"""
    def __init__(self, code: str, description: Optional[str] = None, uri: Optional[str] = None):
        self.code = code
        self.description = description
        self.uri = uri
        super().__init__(description or code)


class OAuth2Client:
    """OAuth 2.0 client with PKCE support"""

    # OAuth 2.0 endpoints (generated from spec)
    AUTHORIZE_URL = "%s"
    TOKEN_URL = "%s"
    DEFAULT_SCOPES = [%s]

    def __init__(self, config: AuthConfig):
        """Initialize OAuth2 client with configuration"""
        self.config = config
        if self.config.scopes is None:
            self.config.scopes = self.DEFAULT_SCOPES.copy()
        self._code_verifier = ""

    async def start_auth(self) -> str:
        """Start OAuth 2.0 authorization code flow with PKCE"""
        # Generate PKCE parameters
        self._code_verifier = self._generate_code_verifier()
        code_challenge = self._generate_code_challenge(self._code_verifier)

        # Build authorization URL
        auth_url = self._build_auth_url(code_challenge)
        return auth_url

    async def exchange_code(self, code: str, state: Optional[str] = None) -> TokenSet:
        """Exchange authorization code for tokens"""
        token_request = {
            "grant_type": "authorization_code",
            "client_id": self.config.client_id,
            "code": code,
            "redirect_uri": self.config.redirect_uri,
            "code_verifier": self._code_verifier,
        }

        response = requests.post(
            self.TOKEN_URL,
            headers={
                "Content-Type": "application/x-www-form-urlencoded",
                "Accept": "application/json",
            },
            data=token_request,
            timeout=30
        )

        if not response.ok:
            error_data = {}
            try:
                error_data = response.json()
            except json.JSONDecodeError:
                pass

            raise AuthError(
                error_data.get("error", "token_exchange_failed"),
                error_data.get("error_description", f"HTTP {response.status_code}"),
                error_data.get("error_uri")
            )

        token_data = response.json()
        return TokenSet(
            access_token=token_data["access_token"],
            expires_in=token_data["expires_in"],
            token_type=token_data["token_type"],
            refresh_token=token_data.get("refresh_token"),
            scope=token_data.get("scope")
        )

    async def refresh_token(self, refresh_token: str) -> TokenSet:
        """Refresh access token"""
        token_request = {
            "grant_type": "refresh_token",
            "client_id": self.config.client_id,
            "refresh_token": refresh_token,
        }

        response = requests.post(
            self.TOKEN_URL,
            headers={
                "Content-Type": "application/x-www-form-urlencoded",
                "Accept": "application/json",
            },
            data=token_request,
            timeout=30
        )

        if not response.ok:
            error_data = {}
            try:
                error_data = response.json()
            except json.JSONDecodeError:
                pass

            raise AuthError(
                error_data.get("error", "refresh_failed"),
                error_data.get("error_description", f"HTTP {response.status_code}"),
                error_data.get("error_uri")
            )

        token_data = response.json()
        return TokenSet(
            access_token=token_data["access_token"],
            expires_in=token_data["expires_in"],
            token_type=token_data["token_type"],
            refresh_token=token_data.get("refresh_token"),
            scope=token_data.get("scope")
        )

    # PKCE Implementation (RFC 7636)
    def _generate_code_verifier(self) -> str:
        """Generate PKCE code verifier"""
        code_verifier = base64.urlsafe_b64encode(
            secrets.token_bytes(32)
        ).decode('utf-8')
        # Remove padding
        return code_verifier.rstrip('=')

    def _generate_code_challenge(self, verifier: str) -> str:
        """Generate PKCE code challenge"""
        digest = hashlib.sha256(verifier.encode('utf-8')).digest()
        challenge = base64.urlsafe_b64encode(digest).decode('utf-8')
        # Remove padding
        return challenge.rstrip('=')

    def _build_auth_url(self, code_challenge: str) -> str:
        """Build authorization URL"""
        params = {
            "response_type": "code",
            "client_id": self.config.client_id,
            "redirect_uri": self.config.redirect_uri,
            "scope": " ".join(self.config.scopes or []),
            "code_challenge": code_challenge,
            "code_challenge_method": "S256",
            "state": secrets.token_urlsafe(32),
        }

        # Add extra parameters if provided
        if self.config.extra_params:
            params.update(self.config.extra_params)

        return f"{self.AUTHORIZE_URL}?{urllib.parse.urlencode(params)}"
|}
    spec.name
    provider.name
    (let now = Unix.time () |> Unix.gmtime in
     Printf.sprintf "%04d-%02d-%02d %02d:%02d:%02d UTC"
       (now.tm_year + 1900) (now.tm_mon + 1) now.tm_mday
       now.tm_hour now.tm_min now.tm_sec)
    provider.authorize_url
    provider.token_url
    (String.concat ", " (List.map (fun s -> sprintf "\"%s\"" s) provider.scopes))

(** Generate Python package setup file *)
let generate_setup_py (_spec : auth_spec) (provider : provider) =
  sprintf {|
from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="%s-auth-sdk",
    version="1.0.0-prototype",
    author="Auth SDK Generator",
    author_email="noreply@example.com",
    description="Generated OAuth 2.0 authentication SDK",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/example/auth-sdk",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
    ],
    python_requires=">=3.8",
    install_requires=[
        "requests>=2.31.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.4.0",
            "pytest-asyncio>=0.21.0",
            "black>=23.0.0",
            "mypy>=1.5.0",
            "flake8>=6.0.0",
        ],
    },
)
|}
    (String.lowercase_ascii provider.name)

(** Generate Python requirements.txt *)
let generate_requirements () =
  {|requests>=2.31.0
|}

(** Generate Python README.md *)
let generate_readme (spec : auth_spec) (provider : provider) =
  sprintf {|# %s Auth SDK

Generated OAuth 2.0 authentication SDK with PKCE support.

## Installation

```bash
pip install -e .
```

## Usage

```python
import asyncio
from auth_sdk import OAuth2Client, AuthConfig

async def main():
    client = OAuth2Client(AuthConfig(
        client_id='your-client-id-here',
        redirect_uri='http://localhost:3000/callback',
        scopes=['%s']
    ))

    # Start authentication
    auth_url = await client.start_auth()
    print(f"Visit this URL: {auth_url}")

    # Handle callback (extract code from URL parameters)
    # In a real app, you'd get this from your callback handler
    code = input("Enter the authorization code: ")

    # Exchange code for tokens
    try:
        tokens = await client.exchange_code(code)
        print(f"Access token: {tokens.access_token}")
    except AuthError as e:
        print(f"Error: {e.code} - {e.description}")

if __name__ == "__main__":
    asyncio.run(main())
```

## Generated Configuration

- **Provider**: %s
- **Authorize URL**: %s
- **Token URL**: %s
- **Default Scopes**: %s
- **PKCE**: Enabled (S256)
- **State Parameter**: Required

## Development

This SDK was generated using the OCaml-based auth SDK generator.
To regenerate, run the generator with your updated specification.

### Running Tests

```bash
pip install -e ".[dev]"
pytest
```

### Code Formatting

```bash
black auth_sdk/
```

### Type Checking

```bash
mypy auth_sdk/
```
|}
    spec.name
    (String.concat "', '" provider.scopes)
    provider.name
    provider.authorize_url
    provider.token_url
    (String.concat ", " provider.scopes)

(** Generate Python __init__.py file *)
let generate_init () =
  {|"""
OAuth 2.0 Authentication SDK

This package provides OAuth 2.0 authentication with PKCE support.
"""

from .oauth2_client import OAuth2Client, AuthConfig, TokenSet, AuthError

__all__ = ["OAuth2Client", "AuthConfig", "TokenSet", "AuthError"]
__version__ = "1.0.0-prototype"
|}

(** Generate Python pytest configuration *)
let generate_pytest_ini () =
  {|[tool:pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = -v --tb=short
asyncio_mode = auto
|}

(** Generate Python mypy configuration *)
let generate_mypy_ini () =
  {|[mypy]
python_version = 3.8
warn_return_any = True
warn_unused_configs = True
disallow_untyped_defs = True
disallow_incomplete_defs = True
check_untyped_defs = True
disallow_untyped_decorators = True
no_implicit_optional = True
warn_redundant_casts = True
warn_unused_ignores = True
warn_no_return = True
warn_unreachable = True
strict_equality = True
|}

(** Create directory structure and write all Python SDK files *)
let generate_python_sdk (spec : auth_spec) (output_dir : string) =
  let provider = List.hd spec.providers in

  (* Create directory structure *)
  let () = if not (Sys.file_exists output_dir) then Unix.mkdir output_dir 0o755 in
  let auth_sdk_dir = Filename.concat output_dir "auth_sdk" in
  let () = if not (Sys.file_exists auth_sdk_dir) then Unix.mkdir auth_sdk_dir 0o755 in
  let tests_dir = Filename.concat output_dir "tests" in
  let () = if not (Sys.file_exists tests_dir) then Unix.mkdir tests_dir 0o755 in

  (* Write main source files *)
  let client_file = Filename.concat auth_sdk_dir "oauth2_client.py" in
  let client_code = generate_oauth2_client spec provider in
  let oc = open_out client_file in
  let () = output_string oc client_code in
  let () = close_out oc in

  let init_file = Filename.concat auth_sdk_dir "__init__.py" in
  let init_code = generate_init () in
  let oc = open_out init_file in
  let () = output_string oc init_code in
  let () = close_out oc in

  (* Write configuration files *)
  let setup_file = Filename.concat output_dir "setup.py" in
  let setup_code = generate_setup_py spec provider in
  let oc = open_out setup_file in
  let () = output_string oc setup_code in
  let () = close_out oc in

  let requirements_file = Filename.concat output_dir "requirements.txt" in
  let requirements_code = generate_requirements () in
  let oc = open_out requirements_file in
  let () = output_string oc requirements_code in
  let () = close_out oc in

  let readme_file = Filename.concat output_dir "README.md" in
  let readme_code = generate_readme spec provider in
  let oc = open_out readme_file in
  let () = output_string oc readme_code in
  let () = close_out oc in

  let pytest_file = Filename.concat output_dir "pytest.ini" in
  let pytest_code = generate_pytest_ini () in
  let oc = open_out pytest_file in
  let () = output_string oc pytest_code in
  let () = close_out oc in

  let mypy_file = Filename.concat output_dir "mypy.ini" in
  let mypy_code = generate_mypy_ini () in
  let oc = open_out mypy_file in
  let () = output_string oc mypy_code in
  let () = close_out oc in

  printf "✅ Generated Python SDK in %s\n" output_dir;
  printf "   - Source: %s/auth_sdk/oauth2_client.py\n" output_dir;
  printf "   - Config: setup.py, requirements.txt\n";
  printf "   - Docs: README.md\n"