# python commands

## globally installing the package

```bash
python -m pip install --upgrade pip
python -m pip install -e .
python -m pytest .\tests\test_zmx_semi_diameter.py
```

## using uv and venv

### Install uv globally

```bash
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
```

### Create venv

```bash
uv venv
```

### Activate venv

```bash
.venv\Scripts\activate
```

### install all requirements

```bash
uv pip install -e .
```

### run tests

```bash
uv run pytest .\tests\test_zmx_semi_diameter.py
```
