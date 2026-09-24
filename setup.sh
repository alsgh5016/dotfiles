#!/usr/bin/env bash
#
# dotfiles 부트스트랩 (macOS)
#
#   ./setup.sh              전체 실행
#   ./setup.sh --no-brew    brew / Brewfile 단계 건너뛰기
#   ./setup.sh --dry-run    무엇을 할지만 출력하고 아무것도 바꾸지 않음
#
# 여러 번 실행해도 안전하도록(멱등) 만들었습니다.
# 기존 실파일은 절대 지우지 않고 ~/.config-backup-<타임스탬프>/ 로 옮깁니다.
# 사용자명·홈 경로를 하드코딩하지 않으므로 다른 계정의 맥에서도 그대로 동작합니다.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d%H%M%S)"
DO_BREW=1
DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --no-brew) DO_BREW=0 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "알 수 없는 옵션: $arg" >&2; exit 2 ;;
  esac
done

info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m[v]\033[0m %s\n' "$*"; }
run()   { if [ "$DRY_RUN" -eq 1 ]; then printf '    (dry-run) %s\n' "$*"; else "$@"; fi; }

[ "$(uname -s)" = "Darwin" ] || { echo "이 스크립트는 macOS 전용입니다." >&2; exit 1; }

# ─────────────────────────────────────────────────────────────────────────────
# 1. Homebrew
# ─────────────────────────────────────────────────────────────────────────────
if [ "$DO_BREW" -eq 1 ]; then
  if ! command -v brew >/dev/null 2>&1; then
    info "Homebrew 설치"
    run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  # Apple Silicon / Intel 모두 대응
  BREW_PREFIX="/usr/local"
  [ -x /opt/homebrew/bin/brew ] && BREW_PREFIX="/opt/homebrew"
  if [ -x "$BREW_PREFIX/bin/brew" ]; then
    eval "$("$BREW_PREFIX/bin/brew" shellenv)"
  fi

  info "Brewfile 설치 (CLI 도구)"
  run brew bundle --file="$DOTFILES/Brewfile"
  ok "brew 단계 완료"
else
  info "brew 단계 건너뜀 (--no-brew)"
fi

command -v stow >/dev/null 2>&1 || { echo "stow 가 없습니다. 'brew install stow' 후 다시 실행하세요." >&2; exit 1; }

# ─────────────────────────────────────────────────────────────────────────────
# 2. stow 충돌 대상 백업
#    ~/.config 안에 '실파일'이 있으면 stow 가 심링크를 못 겁니다.
#    지우지 않고 백업 디렉터리로 옮깁니다.
# ─────────────────────────────────────────────────────────────────────────────
info "stow 충돌 검사"
moved=0
while IFS= read -r rel; do
  target="$CONFIG_HOME/$rel"
  # 이미 심링크면 stow 가 알아서 갱신하므로 건드리지 않는다
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    warn "실파일 발견 → 백업: ~/.config/$rel"
    run mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    run mv "$target" "$BACKUP_DIR/$rel"
    moved=1
  fi
done < <(cd "$DOTFILES" && find . \
          -path ./.git -prune -o \
          -type f -print \
        | sed 's|^\./||' \
        | grep -vE '^(setup\.sh|Brewfile|README\.md|\.gitignore|\.stowrc)$' \
        | grep -vE '^(atuin)/')

if [ "$moved" -eq 1 ]; then
  ok "백업 위치: $BACKUP_DIR"
else
  ok "충돌 없음"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 3. stow
# ─────────────────────────────────────────────────────────────────────────────
info "stow 로 ~/.config 에 심링크 생성"
run mkdir -p "$CONFIG_HOME"

# ~/.config/nushell 은 '실디렉터리'여야 합니다.
# stow 는 자기가 만든 디렉터리만 통째 심링크(tree folding)로 접는데,
# 새 맥에서 이 디렉터리가 없으면 접혀버려서 nushell 이 만드는 런타임 파일
# (history.txt, plugin.msgpackz, vendor/)이 레포 안에 쌓입니다.
# 미리 실디렉터리 + 레포에 없는 파일 하나를 만들어 두면 항상 파일 단위로 링크됩니다.
run mkdir -p "$CONFIG_HOME/nushell"
[ -e "$CONFIG_HOME/nushell/history.txt" ] || run touch "$CONFIG_HOME/nushell/history.txt"

if [ "$DRY_RUN" -eq 1 ]; then
  warn "dry-run 에서는 백업 이동을 실제로 하지 않아, 아래 stow 시뮬레이션이"
  warn "이미 있는 실파일을 '충돌'로 보고할 수 있습니다. 실제 실행 시에는 먼저 백업됩니다."
  (cd "$DOTFILES" && stow --simulate --verbose --restow .) || true
else
  (cd "$DOTFILES" && stow --restow .)
  ok "stow 완료"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 4. nushell 설정 디렉터리 연결
#    macOS 의 nushell 은 ~/Library/Application Support/nushell 을 봅니다.
#    XDG_CONFIG_HOME 이 설정돼 있으면 그쪽이 우선이지만, 로그인 셸 환경에
#    그걸 심는 것보다 심링크 한 번이 단순합니다.
# ─────────────────────────────────────────────────────────────────────────────
NU_APP_SUPPORT="$HOME/Library/Application Support/nushell"
info "nushell 설정 경로 연결"
if [ -L "$NU_APP_SUPPORT" ]; then
  ok "이미 심링크: $(readlink "$NU_APP_SUPPORT")"
elif [ -e "$NU_APP_SUPPORT" ]; then
  warn "실디렉터리가 있어 백업 후 교체합니다"
  run mkdir -p "$BACKUP_DIR"
  run mv "$NU_APP_SUPPORT" "$BACKUP_DIR/nushell-AppSupport"
  run ln -s "$CONFIG_HOME/nushell" "$NU_APP_SUPPORT"
else
  run mkdir -p "$HOME/Library/Application Support"
  run ln -s "$CONFIG_HOME/nushell" "$NU_APP_SUPPORT"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 5. tmux 플러그인 매니저
# ─────────────────────────────────────────────────────────────────────────────
TPM_DIR="$DOTFILES/tmux/plugins/tpm"
if [ -d "$TPM_DIR" ]; then
  ok "tpm 이미 있음"
else
  info "tpm 클론"
  run mkdir -p "$DOTFILES/tmux/plugins"
  run git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 6. 기본 셸 등록 (실제 변경은 물어봅니다)
# ─────────────────────────────────────────────────────────────────────────────
NU_BIN="$(command -v nu || true)"
if [ -n "$NU_BIN" ]; then
  if ! grep -qxF "$NU_BIN" /etc/shells 2>/dev/null; then
    warn "nu 가 /etc/shells 에 없습니다. 기본 셸로 쓰려면:"
    echo "    echo '$NU_BIN' | sudo tee -a /etc/shells"
    echo "    chsh -s '$NU_BIN'"
  elif [ "${SHELL:-}" != "$NU_BIN" ]; then
    warn "기본 셸을 바꾸려면:  chsh -s '$NU_BIN'"
  else
    ok "기본 셸이 이미 nu 입니다"
  fi
else
  warn "nu 를 찾지 못했습니다 (brew 단계를 건너뛰었나요?)"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 7. 마무리 안내
# ─────────────────────────────────────────────────────────────────────────────
cat <<'EOS'

─────────────────────────────────────────────────────────────
남은 수동 단계
─────────────────────────────────────────────────────────────
  1. 새 터미널을 열고  nu  실행 → 에러 없이 뜨는지 확인
  2. tmux 실행 후  prefix + I  (Ctrl+A, Shift+I) 로 플러그인 설치
  3. atuin 동기화를 쓴다면:  atuin login
  4. cps 프로필은 기기마다 로그인이 필요합니다:  cps use <name> → claude → /login
  5. GUI 앱(Ghostty / AeroSpace / Karabiner / Hammerspoon 등)은 Brewfile 하단
     주석을 풀거나 직접 설치하세요.
  6. 예전에 stow 가 만들어 둔 잔여 심링크가 있으면 정리:
       rm -f ~/.config/README.md ~/.config/setup.sh ~/.config/Brewfile

문제가 생기면 백업 디렉터리에서 되돌릴 수 있습니다: ~/.config-backup-*
EOS
ok "완료"
