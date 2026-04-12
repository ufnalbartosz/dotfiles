# Test Navigation in Cursor

A custom extension (`test-navigator`) lives in `cursor/extensions/test-navigator/` and is
symlinked into `~/.cursor/extensions/` by `scripts/setup.sh`.

## Keybindings

| Key | Command | Description |
|-----|---------|-------------|
| `ctrl+c p` | `test-navigator.jumpTest` | Jump between source file and its test counterpart |
| `ctrl+c shift+p` | `test-navigator.createTest` | Create a pytest stub for the current source file |

### Jump (`ctrl+c p`)

- From a source file → finds the corresponding test file and opens it
- From a test file → finds the corresponding source file and opens it
- Shows an error notification if no counterpart exists

### Create test stub (`ctrl+c shift+p`)

- Only works on source files (shows error if already a test file)
- Creates the test file directory if needed
- Writes a minimal pytest stub:
  ```python
  import pytest


  def test_placeholder():
      pass
  ```
- Opens the newly created file immediately

## File naming convention

The extension maps between source and test paths using this pattern:

```
src/foo/bar.py  ↔  tests/foo/test_bar.py   (mirrored, preferred)
src/foo/bar.py  ↔  tests/test_bar.py        (flat fallback, jumpTest only)
```

A leading `src/` segment is stripped when building the mirrored path.
`createTest` always uses the mirrored layout.

## Installation

Run `scripts/setup.sh` (or manually symlink):

```bash
ln -sf ~/dotfiles/cursor/extensions/test-navigator ~/.cursor/extensions/test-navigator
```

Then restart Cursor. The commands appear in the command palette as:
- **Test Navigator: Jump to/from Test**
- **Test Navigator: Create Test File**

## Test Discovery

pytest is enabled via `settings.json`:
```json
"python.testing.pytestEnabled": true,
"python.testing.unittestEnabled": false
```

Cursor auto-discovers tests in `test_*.py` files. The Testing sidebar
(`ctrl+shift+t`) shows discovered tests and lets you run/debug individual cases.

## Edge Case Discovery

### hypothesis — property-based testing

Automatically generates edge-case inputs instead of writing them by hand:

```bash
uv add --dev hypothesis
```

```python
from hypothesis import given, strategies as st

@given(st.integers(), st.integers())
def test_add_commutative(a, b):
    assert add(a, b) == add(b, a)
```

hypothesis shrinks failing inputs to the minimal reproducing case.

### pytest-cov — coverage gaps

Identifies untested code paths:

```bash
uv add --dev pytest-cov
pytest --cov=src --cov-report=term-missing
```

Lines marked as missing are untested. Focus new tests there.

### pytest-randomly — order-dependent bugs

Randomizes test execution order to catch tests that implicitly depend on shared state:

```bash
uv add --dev pytest-randomly
pytest  # order is randomized automatically
```

Use `pytest -p no:randomly` to disable for a single run.
