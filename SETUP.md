# 설치하기 — 각자의 Claude Code로 (추천)

이 폴더(`claude-5h-warmer`)를 받은 뒤, **본인 Claude Code를 이 폴더에서 열고**
아래 프롬프트를 그대로 복사해 붙여넣으세요.
Claude Code가 여러분의 OS를 감지해 알아서 설치하고, 창이 실제로 열렸는지까지 확인해 줍니다.
(사람마다 OS·근무 시작 시간이 달라도 Claude Code가 맞춰 줍니다.)

> 사전 조건: `claude` (Claude Code)가 설치돼 있고 **구독 계정으로 로그인**돼 있을 것.

---

## 붙여넣을 프롬프트

```text
이 폴더(claude-5h-warmer)의 스크립트를 사용해, 내 컴퓨터에 "Claude 구독의 5시간
사용 창을 아침부터 열어두는" 예약 작업을 설정해줘.

[목적] 정해둔 시각마다 아주 짧은 핑을 Claude에 보내 5시간 사용 창을 미리 연다.
5시간 간격으로 두면 창이 하루 종일 끊기지 않고 이어진다.

[반드시 지킬 것]
1) 인증은 반드시 내 "Claude 구독 로그인"으로 나가야 한다. API 키(ANTHROPIC_API_KEY)로
   나가면 5시간 창이 안 열리므로 절대 쓰지 마. 먼저 claude 가 구독 계정으로 로그인돼
   있는지 확인하고, 아니면 로그인 방법을 알려줘.
2) 완전 비대화형으로 돌아야 한다(권한 프롬프트에서 멈추지 않게).

[해줄 일]
1) 내 OS를 감지해줘(uname 등).
2) 스케줄 시각을 나에게 물어봐(기본값: 평일 07:00 / 12:00 / 17:00). 내 답을
   config.sh 의 CM_TIMES 와 CM_WEEKDAYS_ONLY 에 반영해줘.
3) OS에 맞게 설치해줘:
   - macOS  : 이 폴더의 ./install.sh 실행(launchd 자동 등록)
   - Linux  : morning-run.sh 를 systemd user timer(Persistent=true) 또는 cron 으로
              같은 시각에 등록
   - Windows: 작업 스케줄러로 같은 시각에 등록("놓친 작업은 가능한 한 빨리 실행" 켜기)
4) 노트북이 트리거 시각에 절전이어도, 깨어날 때 놓친 작업이 실행되게 설정해줘.
5) 설치 후 한 번 실제로 실행해서 data/window-status.txt 에 status=allowed 가
   찍히는지(= 5시간 창이 실제로 열렸는지) 확인해서 알려줘.
6) 나중에 끄거나 지우는 방법도 알려줘(macOS면 ./uninstall.sh).
```

---

## 수동으로 하고 싶으면
- **macOS**: `config.sh` 에서 시각만 고치고 `./install.sh` 실행. (자세한 내용은 `README.md`)
- **Linux/Windows**: `README.md` 의 스케줄러 안내 참고.
