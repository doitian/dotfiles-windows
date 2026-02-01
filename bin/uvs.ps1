#!/usr/bin/env pwsh

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ($args.Count -eq 0) {
  $args = @('x.py')
}

if ((Test-Path pyproject.toml) -or (Test-Path uv.lock)) {
  & uv run @args
} else {
  & uv run --script @args
}
