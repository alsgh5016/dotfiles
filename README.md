# dotfiles

macOS 설정 모음. GNU stow 로 `~/.config` 에 심링크합니다.
**사용자명과 홈 경로를 하드코딩하지 않으므로** 다른 계정의 맥에서도 그대로 씁니다.

## 새 맥에 설치

```bash
git clone git@github.com:alsgh5016/dotfiles.git ~/util/dotfiles2
cd ~/util/dotfiles2
./setup.sh
```

`setup.sh` 가 하는 일:

1. Homebrew 설치(없으면) → `Brewfile` 로 CLI 도구 설치
2. `~/.config` 안의 충돌하는 **실파일을 지우지 않고** `~/.config-backup-<타임스탬프>/` 로 이동
3. `stow --restow .` 로 심링크 생성
4. `~/Library/Application Support/nushell` → `~/.config/nushell` 심링크
5. tpm(tmux 플러그인 매니저) 클론
6. 기본 셸 변경 명령 안내 (직접 실행)

무엇이 바뀔지 먼저 보고 싶으면:

```bash
./setup.sh --dry-run
```

## nushell 경로가 특이한 이유

macOS 의 nushell 은 `~/Library/Application Support/nushell` 을 봅니다
(`XDG_CONFIG_HOME` 이 설정돼 있으면 그쪽이 우선). 그래서 그 경로를
`~/.config/nushell` 로 심링크해 두고, `~/.config/nushell` 안의
`config.nu` / `env.nu` / `cps.nu` 를 stow 가 이 레포로 연결합니다.

`history.txt`, `plugin.msgpackz`, `vendor/` 같은 런타임 파일은
`~/.config/nushell` 에 실파일로 남고 레포에는 들어오지 않습니다
(stow 가 디렉터리째가 아니라 파일 단위로 링크하기 때문).

확인:

```bash
ls -l ~/.config/nushell/
readlink "$HOME/Library/Application Support/nushell"
```

## 구성

| 디렉터리 | 대상 |
| --- | --- |
| `nushell/` | 기본 셸. `config.nu`, `env.nu`, `cps.nu` |
| `nvim/` | LazyVim |
| `tmux/` | prefix `Ctrl+A`, tpm 플러그인 |
| `ghostty/` `wezterm/` `zellij/` | 터미널 |
| `aerospace/` `skhd/` `karabiner/` `hammerspoon/` `sketchybar/` | 창 관리 · 키 · 바 |
| `starship/` `atuin/` | 프롬프트 · 히스토리 |
| `ssh/` | `ssh-config` (심링크 대상 아님, 참고용) |
| `nix/` `nix-darwin/` | **현재 미사용.** 원본 저자 설정이 남아 있음 |

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
