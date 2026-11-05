#!/usr/bin/env bash
#
# dotfiles 부트스트랩 (macOS / Linux)
#
#   ./setup.sh              전체 실행
#   ./setup.sh --no-brew    brew / Brewfile 단계 건너뛰기
#   ./setup.sh --dry-run    무엇을 할지만 출력하고 아무것도 바꾸지 않음
#
# 여러 번 실행해도 안전하도록(멱등) 만들었습니다.
# 기존 실파일은 절대 지우지 않고 ~/.config-backup-<타임스탬프>/ 로 옮깁니다.
# 사용자명·홈 경로를 하드코딩하지 않으므로 다른 계정의 기기에서도 그대로 동작합니다.
# Linux 에서는 Homebrew on Linux(/home/linuxbrew/.linuxbrew)를 씁니다.
#
# 레이아웃: 각 패키지는 홈 기준 실제 경로를 그대로 담고(nvim/.config/nvim/...)
# `stow --target=~ <패키지>` 로 링크됩니다(.stowrc). 레포가 유일한 원본입니다.

set -euo pipefail

# 물리 경로: 링크 판별(아래 2단계)이 실제 경로끼리 비교하므로 심링크를 풀어 둔다.
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CONFIG_HOME="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d%H%M%S)"
DO_BREW=1
DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --no-brew) DO_BREW=0 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "알 수 없는 옵션: $arg" >&2; exit 2 ;;
  esac
done

info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m[v]\033[0m %s\n' "$*"; }
run()   { if [ "$DRY_RUN" -eq 1 ]; then printf '    (dry-run) %s\n' "$*"; else "$@"; fi; }

OS="$(uname -s)"
case "$OS" in
  Darwin|Linux) ;;
  *) echo "지원하지 않는 OS 입니다: $OS (macOS / Linux 만 지원)" >&2; exit 1 ;;
esac

# 링크할 패키지. GUI/데몬 설정(ghostty, karabiner, aerospace, sketchybar, skhd,
# wezterm, zellij, hammerspoon, nix, nix-darwin, kindavim)은 레포에 남아 있지만
# 아직 중첩 레이아웃으로 옮기지 않아 링크하지 않습니다. 옮기면 여기에 추가하세요.
# atuin 은 의도적으로 제외(.stowrc --ignore). macpro/ 는 Mac Pro 전용 수동 설치물.
STOW_PKGS=(nushell nvim tmux starship)
# ssh 설정은 Host 항목이 macOS 기기 기준이라 macOS 에서만 링크합니다.
if [ "$OS" = "Darwin" ]; then STOW_PKGS+=(ssh); fi

# ─────────────────────────────────────────────────────────────────────────────
# 1. Homebrew
# ─────────────────────────────────────────────────────────────────────────────
if [ "$DO_BREW" -eq 1 ]; then
  if ! command -v brew >/dev/null 2>&1; then
    info "Homebrew 설치"
    run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  # Apple Silicon / Intel / Linux 모두 대응
  BREW_PREFIX="/usr/local"
  [ -x /opt/homebrew/bin/brew ] && BREW_PREFIX="/opt/homebrew"
  [ -x /home/linuxbrew/.linuxbrew/bin/brew ] && BREW_PREFIX="/home/linuxbrew/.linuxbrew"
  if [ -x "$BREW_PREFIX/bin/brew" ]; then
    eval "$("$BREW_PREFIX/bin/brew" shellenv)"
  fi

  # 기본 셸(macOS: zsh, Linux: bash)에서도 brew 도구가 PATH 에 잡히게 한다.
  # 이 레포는 zshrc / bashrc 를 관리하지 않으므로, 새 기기에서 이게 없으면 ssh 접속했을 때
  # nu / nvim / tmux 등을 못 찾는다. 이 파일들은 기기별 파일이라 경로를 그대로 적어도 된다.
  # Linux 는 로그인 셸(~/.profile)과 비로그인 셸(~/.bashrc, tmux 새 창 등) 모두에 넣는다.
  if [ "$OS" = "Darwin" ]; then
    SHELL_RCS=("$HOME/.zprofile")
  else
    SHELL_RCS=("$HOME/.profile" "$HOME/.bashrc")
  fi
  for rc in "${SHELL_RCS[@]}"; do
    if ! grep -qsF "brew shellenv" "$rc"; then
      info "$rc 에 brew shellenv 추가"
      if [ "$DRY_RUN" -eq 1 ]; then
        printf '    (dry-run) %s 에 추가: eval "$(%s/bin/brew shellenv)"\n' "$rc" "$BREW_PREFIX"
      else
        printf '\neval "$(%s/bin/brew shellenv)"\n' "$BREW_PREFIX" >> "$rc"
      fi
    fi
  done

  info "Brewfile 설치 (CLI 도구)"
  run brew bundle --file="$DOTFILES/Brewfile"
  ok "brew 단계 완료"
else
  info "brew 단계 건너뜀 (--no-brew)"
fi

command -v stow >/dev/null 2>&1 || { echo "stow 가 없습니다. 'brew install stow' 후 다시 실행하세요." >&2; exit 1; }

# ─────────────────────────────────────────────────────────────────────────────
# 2. stow 충돌 정리
#    대상 경로에 '실파일'이 있으면 stow 가 링크를 못 겁니다 → 백업으로 옮깁니다.
#    예전 레이아웃(~/.config 대상 stow)이 남긴 링크는 깨졌거나 레포의 다른 곳을
#    가리키므로 지웁니다. 레포 밖을 가리키는 링크는 남의 것이라 백업합니다.
# ─────────────────────────────────────────────────────────────────────────────
backup() {  # $1 = 홈 기준 상대 경로
  run mkdir -p "$BACKUP_DIR/$(dirname "$1")"
  run mv "$HOME/$1" "$BACKUP_DIR/$1"
  moved=1
}

info "stow 충돌 검사"
moved=0
for pkg in "${STOW_PKGS[@]}"; do
  # 디렉터리를 내용보다 먼저 보므로, 디렉터리 링크를 지우면 그 아래는 자연히 비게 된다.
  while IFS= read -r src; do
    rel="${src#"$DOTFILES/$pkg/"}"
    tgt="$HOME/$rel"
    # 상위 디렉터리가 이미 레포로 링크돼 있으면(stow 가 접어 둔 디렉터리) 그 아래에
    # 보이는 것은 레포 원본 자체다. 건드리면 레포 파일을 옮기게 되므로 건너뛴다.
    parent="$(cd "$(dirname "$tgt")" 2>/dev/null && pwd -P || true)"
    case "$parent/" in "$DOTFILES"/*) continue ;; esac
    if [ -L "$tgt" ]; then
      if [ ! -e "$tgt" ]; then
        warn "깨진 링크 제거: ~/$rel"
        run rm "$tgt"
      else
        dest="$(cd "$(dirname "$tgt")" && cd -P "$(dirname "$(readlink "$tgt")")" 2>/dev/null && pwd)/$(basename "$(readlink "$tgt")")"
        case "$dest" in
          "$src")
            # 올바른 대상이어도 절대경로 링크는 stow 가 자기 것으로 보지 않아 중단한다.
            case "$(readlink "$tgt")" in
              /*) warn "절대경로 링크 → stow 가 다시 만듦: ~/$rel"; run rm "$tgt" ;;
            esac ;;
          "$DOTFILES"/*) warn "예전 레이아웃 링크 제거: ~/$rel"; run rm "$tgt" ;;
          *) warn "레포 밖을 가리키는 링크 → 백업: ~/$rel"; backup "$rel" ;;
        esac
      fi
    elif [ -f "$tgt" ] && [ -f "$src" ]; then
      warn "실파일 발견 → 백업: ~/$rel"
      backup "$rel"
    fi
  done < <(find "$DOTFILES/$pkg" -mindepth 1 \( -name .DS_Store -o -path "$DOTFILES/tmux/.config/tmux/plugins" \) -prune -o -print)
done

if [ "$moved" -eq 1 ]; then
  ok "백업 위치: $BACKUP_DIR"
else
  ok "충돌 없음"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 3. stow
# ─────────────────────────────────────────────────────────────────────────────
info "stow ${STOW_PKGS[*]}"

# 아래 디렉터리는 '실디렉터리'여야 합니다. stow 는 자기가 만든 디렉터리를 통째
# 링크(tree folding)로 접는데, 그러면 프로그램이 만드는 런타임 파일
# (nushell 의 history.txt·plugin.msgpackz·vendor/, tmux 의 plugins/,
# ssh 의 known_hosts·키)이 레포 안에 쌓입니다. 미리 만들어 두면 항상 파일 단위로 링크됩니다.
REAL_DIRS=(.config/nushell .config/tmux)
if [ "$OS" = "Darwin" ]; then REAL_DIRS+=(.ssh); fi
for d in "${REAL_DIRS[@]}"; do
  if [ -L "$HOME/$d" ]; then
    warn "디렉터리 링크 제거: ~/$d"
    run rm "$HOME/$d"
  fi
  run mkdir -p "$HOME/$d"
done
if [ -d "$HOME/.ssh" ]; then run chmod 700 "$HOME/.ssh"; fi

if [ "$DRY_RUN" -eq 1 ]; then
  warn "dry-run 에서는 위 정리를 실제로 하지 않아, 아래 시뮬레이션이"
  warn "그 대상들을 '충돌'로 보고할 수 있습니다. 실제 실행 시에는 먼저 정리됩니다."
  (cd "$DOTFILES" && stow --simulate --verbose --restow "${STOW_PKGS[@]}") || true
else
  (cd "$DOTFILES" && stow --restow "${STOW_PKGS[@]}")
  ok "stow 완료"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 4. macOS 전용 설정 경로 연결
#    macOS 의 nushell 은 ~/.config 가 아니라
#    ~/Library/Application Support/<앱> 을 봅니다. 그 디렉터리에는 실행 중
#    생기는 파일(history.txt 등)도 쌓이므로 디렉터리가 아니라
#    설정 파일만 ~/.config 쪽으로 링크합니다.
#    Linux 는 ~/.config 를 그대로 읽으므로 이 단계가 필요 없습니다.
# ─────────────────────────────────────────────────────────────────────────────
link_file() {  # $1 = 링크 위치, $2 = 가리킬 파일
  local dst="$1" src="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    ok "이미 연결됨: $dst"
    return
  fi
  if [ -L "$dst" ]; then
    run rm "$dst"
  elif [ -e "$dst" ]; then
    warn "실파일이 있어 백업 후 교체: $dst"
    run mkdir -p "$BACKUP_DIR/AppSupport"
    run mv "$dst" "$BACKUP_DIR/AppSupport/$(basename "$(dirname "$dst")")-$(basename "$dst")"
  fi
  run mkdir -p "$(dirname "$dst")"
  run ln -s "$src" "$dst"
  ok "연결: $dst"
}

info "macOS 설정 경로 연결"
if [ "$OS" = "Linux" ]; then
  ok "Linux: ~/.config 를 그대로 사용 (연결 불필요)"
else
  APP_SUPPORT="$HOME/Library/Application Support"
  # config.nu 는 cps.nu 를 ~/.config/nushell 에서 source 하므로 그 파일은 연결하지 않아도 된다.
  for f in env.nu config.nu; do
    link_file "$APP_SUPPORT/nushell/$f" "$CONFIG_HOME/nushell/$f"
  done
fi

# ─────────────────────────────────────────────────────────────────────────────
# 5. ~/.dotfiles → 레포 위치
#    레포를 어디에 클론했든 설정 파일이 같은 경로로 레포를 찾게 합니다
#    (tmux-sessionx 의 @sessionx-custom-paths 등).
# ─────────────────────────────────────────────────────────────────────────────
info "~/.dotfiles 연결"
if [ "$DOTFILES" = "$HOME/.dotfiles" ]; then
  ok "레포가 이미 ~/.dotfiles 에 있음"
elif [ -L "$HOME/.dotfiles" ] || [ ! -e "$HOME/.dotfiles" ]; then
  run ln -sfn "$DOTFILES" "$HOME/.dotfiles"
  ok "~/.dotfiles -> $DOTFILES"
else
  warn "~/.dotfiles 가 실디렉터리라 건드리지 않습니다"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 6. tmux 플러그인 매니저
#    플러그인은 레포가 아니라 실디렉터리 ~/.config/tmux/plugins 에 설치됩니다.
# ─────────────────────────────────────────────────────────────────────────────
TPM_DIR="$CONFIG_HOME/tmux/plugins/tpm"
if [ -d "$TPM_DIR" ]; then
  ok "tpm 이미 있음"
else
  info "tpm 클론"
  run mkdir -p "$CONFIG_HOME/tmux/plugins"
  run git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 7. 기본 셸 등록 (실제 변경은 물어봅니다)
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
# 8. 마무리 안내
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
  6. git 커밋 정보(기기마다 따로):
       git config --global user.name  "..."
       git config --global user.email "..."

문제가 생기면 백업 디렉터리에서 되돌릴 수 있습니다: ~/.config-backup-*
EOS
ok "완료"
