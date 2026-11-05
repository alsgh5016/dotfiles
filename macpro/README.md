# macpro

Mac Pro 7,1(T2) + NVIDIA GPU 전용 시스템 설정. `~/.config` 가 아니라 시스템 경로에
설치하므로 stow 대상에서 제외한다.

## gpu-fan-control

t2fanrd 는 CPU 온도만 본다(NVIDIA 는 hwmon 을 노출하지 않고, SMC 에는 GPU 센서가
`-127°C` 로 보인다). 그래서 GPU 만 바쁜 LLM 추론 중에도 케이스 팬이 최저 속도에 머문다.
이 데몬은 `max(CPU 곡선, GPU 곡선)` 으로 모든 SMC 팬을 제어한다.

- CPU 55–75°C, GPU 50–80°C 구간에서 팬 min→max 선형
- 올릴 때는 즉시, 내릴 때는 2초마다 100 RPM 씩
- `nvidia-smi` 실패 시 GPU 를 80°C 로 간주(팬 최대)
- 종료 시 `fan_control=0` 으로 SMC 자동 제어에 반환

설치 (nu):

```nu
sudo install -m 755 macpro/gpu-fan-control /usr/local/sbin/gpu-fan-control
sudo install -m 644 macpro/gpu-fan-control.service /etc/systemd/system/gpu-fan-control.service
sudo systemctl disable --now t2fanrd
sudo systemctl daemon-reload
sudo systemctl enable --now gpu-fan-control
```

dry-run(sysfs 에 쓰지 않고 판단만 출력): `DRY_RUN=1 ./macpro/gpu-fan-control`

되돌리기: `sudo systemctl disable --now gpu-fan-control; sudo systemctl enable --now t2fanrd`
