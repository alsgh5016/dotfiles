# dotfiles

macOS · Linux(Ubuntu) 설정 모음. GNU stow 로 홈 디렉터리에 심링크합니다.
**사용자명과 홈 경로를 하드코딩하지 않으므로** 다른 계정의 기기에서도 그대로 씁니다.

## 새 기기에 설치

```bash
git clone git@github.com:alsgh5016/dotfiles.git ~/repo/dotfiles   # 위치는 자유
cd ~/repo/dotfiles
./setup.sh
```

`setup.sh` 가 하는 일:

1. Homebrew 설치(없으면) → `Brewfile` 로 CLI 도구 설치
2. 링크 대상에 있는 **실파일을 지우지 않고** `~/.config-backup-<타임스탬프>/` 로 이동,
   예전 레이아웃이 남긴 링크 정리
3. 패키지별 `stow --restow` 로 심링크 생성
4. (macOS) `~/Library/Application Support/nushell` 의 설정 파일을 `~/.config` 쪽으로 연결
5. `~/.dotfiles` → 이 레포 위치 링크 (tmux-sessionx 등이 사용)
6. tpm(tmux 플러그인 매니저) 클론
7. 기본 셸 변경 명령 안내 (직접 실행)

무엇이 바뀔지 먼저 보고 싶으면:

```bash
./setup.sh --dry-run
```

## 레이아웃

각 패키지는 **홈 기준 실제 경로를 그대로** 담습니다. `nvim/.config/nvim/init.lua` 는
`~/.config/nvim/init.lua` 로 링크됩니다(`.stowrc`: `--target=~`). 그래서 `~/.ssh/config`
처럼 `~/.config` 밖의 파일도 같은 방식으로 관리합니다.

링크하는 패키지는 `setup.sh` 의 `STOW_PKGS` 에 있습니다.

| 패키지 | 대상 | 비고 |
| --- | --- | --- |
| `nushell/` | `~/.config/nushell/` | 기본 셸. `config.nu`, `env.nu`, `cps.nu` |
| `nvim/` | `~/.config/nvim/` | LazyVim |
| `tmux/` | `~/.config/tmux/` | prefix `Ctrl+A`, tpm 플러그인 |
| `starship/` | `~/.config/starship/` | 프롬프트 |
| `ssh/` | `~/.ssh/config` | **macOS 에서만** 링크 (Host 항목이 macOS 기기 기준) |

아직 예전 레이아웃(`<앱>/설정파일`)이라 **링크하지 않는** 것: `ghostty/` `wezterm/` `zellij/`
`aerospace/` `skhd/` `karabiner/` `hammerspoon/` `sketchybar/` `kindavim/` `atuin/`
`nix/` `nix-darwin/`. 쓰려면 `<앱>/.config/<앱>/...` 로 옮긴 뒤 `STOW_PKGS` 에 추가하세요.

`macpro/` 는 Mac Pro 전용 수동 설치물(GPU 팬 제어 데몬)입니다. `macpro/README.md` 참고.

## macOS 에서 nushell 경로가 특이한 이유

macOS 의 nushell 은 `~/.config` 가 아니라 `~/Library/Application Support/<앱>` 을
봅니다. 그 디렉터리에는 실행 중 생기는 파일(`history.txt` 등)도 쌓이므로,
디렉터리째가 아니라 **설정 파일만** `~/.config/<앱>/` 쪽으로 링크합니다.

`~/.config/nushell`, `~/.config/tmux` 도 `setup.sh` 가 **실디렉터리**로
먼저 만들어 둡니다. stow 가 디렉터리째 링크(tree folding)하면 history·tmux 플러그인 같은
런타임 파일이 레포 안에 쌓이기 때문입니다.

확인:

```bash
ls -l ~/.config/nushell/
ls -l "$HOME/Library/Application Support/nushell/"
```

## 기기마다 따로 해야 하는 것

- `atuin login` — 히스토리 동기화
- `cps` 프로필별 `claude` `/login` — 자격증명은 Keychain 에 있어 git 으로 안 옮겨갑니다
- GUI 앱 설치 — `Brewfile` 하단 주석 참고
- tmux `prefix + I` — 플러그인 설치

## 원격 서버 접속 시 백스페이스가 깨질 때

Ghostty 가 `TERM=xterm-ghostty` 를 쓰는데 서버에 해당 terminfo 가 없으면
백스페이스가 지우는 대신 공백을 뱉습니다. `config.nu` 의 `ssh-terminfo` 함수로
서버당 한 번 설치하세요.

```nu
ssh-terminfo root@myhost
ssh-terminfo -p 2222 user@myhost
```

root 로 접속하면 `/etc/terminfo` 에 들어가 그 서버의 모든 계정에 적용됩니다.
