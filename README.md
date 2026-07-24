# claude-5h-warmer

Claude **구독**의 "5시간 사용 창"을 원하는 시각에 자동으로 열어두는 작은 도구.
정해진 시각마다 아주 짧은 핑을 보내 창을 열고, 실제 창 상태(리셋 시각·사용률)를 기록한다.

## 왜 쓰나
- Claude 구독은 첫 메시지부터 5시간 창이 열리고, 그 창 안에서 사용량이 관리된다.
- 하루 시작 전에 창을 미리 열어두면, 정작 일할 때 리셋 타이밍이 앞당겨져 유리하다.
- **5시간 간격**으로 핑을 두면 창이 끊기지 않고 이어진다.
  예) `07:00 → 12:00 → 17:00` = 오전 7시 ~ 밤 10시 연속 커버.

## 설치 방법

### A) 각자의 Claude Code로 (가장 쉬움, 추천)
👉 **[SETUP.md](SETUP.md)** 의 프롬프트를 본인 Claude Code에 붙여넣으면 끝.
OS 감지·시각 설정·설치·검증까지 Claude Code가 알아서 해준다. OS/시간이 사람마다 달라도 OK.

### B) 수동 (macOS)
```bash
$EDITOR config.sh        # 1) 시각/모델을 취향대로 수정
./install.sh             # 2) 설치 (launchd 등록)
# 3) (선택) 지금 바로 한 번 테스트
launchctl kickstart -k gui/$(id -u)/com.claude-morning
cat data/window-status.txt
```

## 요구사항
- Claude Code CLI + **구독 계정 로그인** 상태
  - `claude` 가 PATH 에 있거나 `~/.local/bin/claude`, 또는 VSCode 확장 번들 바이너리 중 하나면 자동 인식.
  - ⚠️ **API 키로 쓰면 안 된다.** API 키(`ANTHROPIC_API_KEY`)로 나가면 과금이 구독과 분리돼 5시간 창이 **안** 열린다. 스크립트가 API 키 환경변수를 자동으로 제거하지만, 애초에 `claude` 가 **구독으로 로그인**돼 있어야 한다.
- 수동 설치(B)의 `install.sh` 는 **macOS(launchd)** 전용. Linux/Windows 는 방법 A(Claude Code)를 쓰거나 아래 스케줄러 안내를 참고.

## 설정 — `config.sh`
| 변수 | 설명 | 예시 |
|---|---|---|
| `CM_TIMES` | 핑 보낼 시각들 (로컬시간, 공백 구분) | `"07:00 12:00 17:00"` |
| `CM_WEEKDAYS_ONLY` | 평일(월~금)만? | `true` / `false` |
| `CM_MODEL` | 사용할 모델 (가벼울수록 쿼터 절약) | `claude-haiku-4-5-20251001` |
| `CM_PROMPT` | 보낼 프롬프트 (짧게) | `"'ok'라고만 답해."` |
| `CM_DATADIR` | 로그/상태 저장 위치 (비우면 `./data`) | `""` |

값을 바꾼 뒤 **`./install.sh` 를 다시 실행**하면 스케줄이 갱신된다.
사람마다 근무 시작 시간이 다르면 `CM_TIMES` 만 고치면 된다.

## 동작 확인
- `data/window-status.txt` — 마지막 실행의 창 상태 한 줄
  예) `5h window: status=allowed used=50% resets=2026-07-25 09:00 KST`
  `status=allowed` = 창이 실제로 열려 있음 (**API 응답 헤더 실측치**)
- `data/run.log` — 실행 이력
- 인터랙티브 세션에서 `/usage` 로 교차 확인 가능

## 제거
```bash
./uninstall.sh
```

## 구성 파일
- `morning-run.sh` — 핑 1회 + 창 상태 기록. 상주 프로세스 없음(실행 시 몇 초만).
- `install.sh` — `config.sh` 를 읽어 LaunchAgent plist 생성 후 등록(macOS).
- `uninstall.sh` — 등록 해제 + plist 삭제 (로그는 보존).
- `SETUP.md` — 각자의 Claude Code로 설치하는 붙여넣기 프롬프트.

## 주의사항
- 트리거 시각에 **절전**이면 깨어날 때 실행된다. 하지만 **완전히 전원이 꺼져** 있으면 그 슬롯은 건너뛴다.
- 시각은 **머신의 로컬 시간대** 기준.
- 컴퓨터 부담은 무시 가능: 유휴 시 0(데몬 아님), 실행당 몇 초·CPU 1초 미만·메모리 순간 ~300MB 사용 후 즉시 회수. 진짜 비용은 하드웨어가 아니라 구독 쿼터를 조금 쓰는 것(= 의도된 동작).

## Linux (참고)
`install.sh` 는 macOS 전용이지만 `morning-run.sh` 자체는 Linux 에서도 동작한다(시간 변환 처리 포함).
cron 예시:
```cron
0 7,12,17 * * 1-5 /path/to/claude-5h-warmer/morning-run.sh
```
