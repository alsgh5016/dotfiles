# ─── cps (claude-profile-switch) nushell integration ──────────────────────────
# bash/zsh 의 `eval "$(cps shell-init)"` 대체판.
# 원본: https://github.com/guibes/claude-profile-switch (lib/shell.sh)
# config.nu 에서 `source ~/.config/nushell/cps.nu` 로 로드됨.

# 0) cps 본체에 셸 통합이 살아있음을 알림 (이게 없으면 `cps use` 가 경고를 띄운다)
$env.CPS_SHELL_INIT_SOURCED = "1"

# 1) 데이터 디렉터리 (원본 lib/utils.sh 와 동일 규칙)
$env.CPS_DATA_DIR = ($env.CPS_DATA_DIR? | default (
    ($env.XDG_DATA_HOME? | default ($nu.home-path | path join ".local" "share"))
    | path join "cps"
))

# 2) active 파일을 읽어 CLAUDE_CONFIG_DIR 를 현재 셸에 export
def --env cps-activate [] {
    let active_file = ($env.CPS_DATA_DIR | path join "active")
    if ($active_file | path exists) {
        let name = (open --raw $active_file | str trim)
        let dir = ($env.CPS_DATA_DIR | path join "profiles" $name "claude")
        if ($name | is-not-empty) and ($dir | path exists) {
            $env.CLAUDE_CONFIG_DIR = $dir
        }
    }
}

# 3) cps 래퍼 — `cps use` 후 현재 셸의 환경변수를 갱신
#    ^cps 로 외부 바이너리를 호출해야 무한 재귀가 안 난다.
#    try {} 는 nushell 이 외부 명령 비정상 종료를 에러로 올리는 것을 막기 위함.
def --env --wrapped cps [...args] {
    try { ^cps ...$args }
    cps-activate
}

# 4) 셸 시작 시 1회 활성화
cps-activate


# ─── (선택) sync 사용 시 셸 시작할 때 백그라운드 pull ──────────────────────────
# `cps sync enable` 을 쓸 때만 아래 주석을 해제할 것.
# `job spawn` 은 nushell 0.104+ 필요 — 구버전이면 bash 폴백 줄을 대신 쓸 것.
#
# def cps-bg-sync [] {
#     let conf = ($env.CPS_DATA_DIR | path join "cps.conf")
#     if not ($conf | path exists) { return }
#     if not (open --raw $conf | lines | any {|l| $l | str starts-with "sync_enabled=1"}) { return }
#
#     job spawn { try { ^cps pull } } | ignore
#     # 0.104 미만 폴백:
#     # ^bash -c "cps pull >/dev/null 2>&1 &"
# }
# cps-bg-sync


# ─── 완성 + 별칭 ───────────────────────────────────────────────────────────────
def "nu-complete cps-profiles" [] {
    let dir = ($env.CPS_DATA_DIR | path join "profiles")
    if ($dir | path exists) {
        ls $dir | where type == dir | get name | path basename
    } else { [] }
}

def --env cpsu [profile: string@"nu-complete cps-profiles"] { cps use $profile }
alias cpsl = cps list
alias cpsc = cps current
alias cpss = cps save

# 프롬프트용: 현재 프로필 이름
def cps-current [] {
    let f = ($env.CPS_DATA_DIR | path join "active")
    if ($f | path exists) { open --raw $f | str trim } else { "" }
}
