# Pinned Runtime Patch Provenance

`openclaw-2026.4.12-telegram-outbox.patch` reproduces the existing local Telegram
text-recovery customization, including the generic-failure exclusion, from the
official `openclaw@2026.4.12` npm package. It contains no local configuration,
credentials, conversation data or account identifiers.

- Upstream: <https://github.com/openclaw/openclaw>
- Package: <https://registry.npmjs.org/openclaw/-/openclaw-2026.4.12.tgz>
- npm integrity: `sha512-0siWIzT0OI8R+QWRJzTbDOcxAQnNXvQxFVXbF6CJMstsTyiG7hyW9HLRbTkv6SrxJEhuEMK91Ak2TLQjFjYZ5A==`
- File: `dist/bot-BJJHvk3V.js`
- Stock SHA-256: `63286458369fb7291b86dfa4e80522ff008572772566a1006a3ba89e9d878afd`
- Managed SHA-256: `c5c573f6467430ca63e5cc93782f074b59e977c4460e142b4b0a070d39fb4987`

The helper checks both hashes, version, exact hunk positions and syntax before
writing. An already managed file is not rewritten. Unknown local changes require
review, not fuzzy patching. Clean-install CI must test the official package, not
only a previously modified host. See the delivery runbook for behavioral scope.

## Upstream License

MIT License

Copyright (c) 2025 Peter Steinberger

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
