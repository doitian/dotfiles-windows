#MISE dir="{{cwd}}"
#MISE depends=["preset:pre-commit"]

mise tasks add pre-commit:cargo-fmt -- cargo fmt --check
if (Get-Command -ErrorAction Ignore cargo-nextest) {
  mise tasks add test -- cargo nextest run --no-fail-fast --nocapture
} else {
  mise tasks add test -- cargo test --no-fail-fast -- --nocapture
}
