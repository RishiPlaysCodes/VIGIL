# Security Policy

## Reporting Vulnerabilities

If you discover a security vulnerability, please report it responsibly:

1. **Do NOT** open a public GitHub issue
2. Email security concerns to the maintainers directly
3. Include steps to reproduce and potential impact
4. Allow 72 hours for initial response

## Security Measures

### Backend
- Token-based authentication with automatic expiration (30 days default)
- Rate limiting on authentication endpoints (5 attempts / 5 minutes)
- CSRF protection on all non-API views
- SQL injection prevention via Django ORM
- File upload size limits (10MB)
- Content-Length validation middleware
- Security headers (HSTS, X-Frame-Options, X-Content-Type-Options)
- Non-root Docker container execution
- PostgreSQL with parameterized queries

### Mobile App
- Encrypted token storage (Android EncryptedSharedPreferences / iOS Keychain)
- Security PIN stored in platform keychain (not SharedPreferences)
- No hardcoded credentials or secrets
- ProGuard/R8 code obfuscation in release builds
- Certificate pinning support via app configuration
- Biometric verification option for alert cancellation
- Separate debug/release application IDs

### Infrastructure
- HTTPS enforced in production
- Environment-based secrets (never in code)
- Docker multi-stage builds (no build tools in production image)
- GitHub Actions CI with security auditing (pip-audit)

## Dependencies

Security updates for dependencies should be monitored via:
- `pip-audit` for Python packages
- `flutter pub outdated` for Dart packages
- GitHub Dependabot alerts (enable in repository settings)
