# CLI 도구만 관리합니다.
# GUI 앱(Ghostty, AeroSpace, Karabiner-Elements, Hammerspoon, WezTerm, SketchyBar, skhd 등)은
# 의도적으로 뺐습니다. 필요하면 아래 주석 블록을 풀어서 쓰세요.
#
#   brew bundle --file=Brewfile          설치
#   brew bundle check --file=Brewfile    빠진 것 확인
#   brew bundle cleanup --file=Brewfile  목록에 없는 것 정리(주의)

tap "guibes/tap", "https://github.com/guibes/claude-profile-switch"
tap "anomalyco/tap"

# ── 셸 · 프롬프트 · 히스토리 ──────────────────────────────────────────────────
brew "nushell"      # 기본 셸
brew "starship"     # 프롬프트
brew "carapace"     # 완성
brew "atuin"        # 히스토리
brew "zoxide"       # 디렉터리 점프
brew "direnv"       # config.nu 의 pre_prompt 훅이 사용

# ── 파일 · 검색 ───────────────────────────────────────────────────────────────
brew "eza"          # alias lt
brew "fzf"          # 함수 ff, tmux-fzf 플러그인
brew "ripgrep"      # LazyVim grep
brew "fd"           # LazyVim 파일 검색
brew "bat"
brew "jq"

# ── 에디터 · 멀티플렉서 ───────────────────────────────────────────────────────
brew "neovim"       # alias v / vim  (LazyVim 최신 + nvim-treesitter main 은 0.12 이상 필요)
brew "tree-sitter-cli"  # nvim-treesitter main 브랜치가 파서 컴파일에 사용 (0.26.1+). Intel 맥은 소스 빌드라 오래 걸림
brew "vim"
brew "tmux"

# ── git ───────────────────────────────────────────────────────────────────────
brew "git"
brew "gh"
brew "lazygit"
brew "git-delta"    # lazygit diff 렌더러 (lazygit/.config/lazygit/config.yml)

# ── dotfiles 관리 ─────────────────────────────────────────────────────────────
brew "stow"

# ── 언어 · 런타임 ─────────────────────────────────────────────────────────────
brew "go"           # nvim gopls/gofumpt
brew "node"         # copilot.lua, 각종 LSP
brew "node@22"
brew "ruby"         # env.nu 가 PATH 에 추가
brew "uv"           # Python 패키지 · 가상환경
brew "cmake"

# ── 포매터 · 기타 ─────────────────────────────────────────────────────────────
brew "yamlfmt"      # nvim conform
brew "kubernetes-cli"  # alias k, kg, kd ...
brew "openssl@3"
brew "curl"
brew "wget"
brew "poppler"      # PDF 텍스트 추출 (pdftotext 등)

# ── AI 코딩 에이전트 ──────────────────────────────────────────────────────────
brew "guibes/tap/cps"            # Claude Code 멀티 계정 전환
brew "anomalyco/tap/opencode"

# ── macOS 전용 ────────────────────────────────────────────────────────────────
if OS.mac?
  brew "docker"     # CLI. 엔진은 OrbStack 이 제공 (Linux 는 배포판 docker 사용)
  brew "mactop"     # Apple Silicon 모니터
  brew "mole"       # Mac 정리 도구
  cask "orbstack"
end

# ── 선택: 설치돼 있으면 env.nu 가 알아서 PATH/LDFLAGS 를 잡습니다 ─────────────
# brew "openjdk@21"
# brew "llvm"

# ── GUI 앱이 필요하면 아래 주석 해제 ──────────────────────────────────────────
# cask "ghostty"
# cask "wezterm"
# cask "nikitabobko/tap/aerospace"
# cask "karabiner-elements"
# cask "hammerspoon"
# brew "FelixKratz/formulae/sketchybar"
# brew "koekeishiya/formulae/skhd"
