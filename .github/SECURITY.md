# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in batipanel, please report it responsibly.

**Email:** [support@bati.ai](mailto:support@bati.ai)

Please include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We will acknowledge receipt within 48 hours and aim to release a fix within 7 days for critical issues.

## Scope

Security issues in the following areas are in scope:
- Code injection via config files or user input
- Path traversal or file system access beyond `~/.batipanel/`
- Unsafe shell expansion or variable injection
- Privilege escalation through install/uninstall scripts

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.3.x   | Yes       |
| < 0.3   | No        |
