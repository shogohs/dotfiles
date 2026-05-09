#!/bin/bash
set -euo pipefail

# このスクリプトのディレクトリを基準パスとして取得
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

DOTFILES=(
  .vimrc
  .zshrc
)

section() { printf '\n=== %s ===\n' "$1"; }

# dotfiles を ~/ にシンボリックリンクとして配置する (既存ファイルはタイムスタンプ付きでバックアップ)
section "dotfiles setup"

for file in "${DOTFILES[@]}"; do
  src="${DOTFILES_DIR}/${file}"
  dest="${HOME}/${file}"

  if [ ! -e "$src" ]; then
    echo "SKIP: ${file} not found in dotfiles"
    continue
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$dest" "$backup"
    echo "BACKUP: ${dest} -> ${backup}"
  fi

  ln -s "$src" "$dest"
  echo "LINK: ${file} -> ${dest}"
done

# .claude/ ディレクトリを ~/ にコピーする (既存があればバックアップ)
section ".claude directory"

claude_src="${DOTFILES_DIR}/.claude"
claude_dest="${HOME}/.claude"

if [ -d "$claude_dest" ] || [ -L "$claude_dest" ]; then
  backup="${claude_dest}.bak.$(date +%Y%m%d%H%M%S)"
  mv "$claude_dest" "$backup"
  echo "BACKUP: ${claude_dest} -> ${backup}"
fi

mkdir -p "$claude_dest"
while IFS= read -r -d '' file; do
  rel="${file#"${claude_src}/"}"
  dest_file="${claude_dest}/${rel}"
  mkdir -p "$(dirname "$dest_file")"
  cp "$file" "$dest_file"
  echo "COPY: .claude/${rel}"
done < <(git -C "$DOTFILES_DIR" ls-files -z --full-name -- .claude/ | xargs -0 -I{} printf '%s\0' "${DOTFILES_DIR}/{}")

echo "Done"

# Xcode Command Line Tools をインストールする (最大300秒待機)
section "Xcode Command Line Tools"

if xcode-select -p &>/dev/null; then
  echo "SKIP: Xcode CLT already installed"
else
  echo "Installing Xcode Command Line Tools..."
  xcode-select --install || true
  timeout=300
  elapsed=0
  until xcode-select -p &>/dev/null; do
    if [ "$elapsed" -ge "$timeout" ]; then
      echo "ERROR: Xcode CLT installation timed out"
      exit 1
    fi
    sleep 5
    elapsed=$((elapsed + 5))
  done
  echo "Done"
fi

# Homebrew をインストールし、シェル環境を設定する (Apple Silicon / Intel 両対応)
section "Homebrew"

if command -v brew &>/dev/null; then
  echo "SKIP: Homebrew already installed"
else
  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$brew_path" ]; then
      eval "$("$brew_path" shellenv)"
      break
    fi
  done
  echo "Done"
fi

# Brewfile に定義されたパッケージを一括インストールする
section "brew bundle"

brew bundle --file="${DOTFILES_DIR}/Brewfile"
echo "Done"

section "Setup complete"
