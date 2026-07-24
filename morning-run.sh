#!/bin/zsh
# claude-morning — 설정된 시각마다 "아주 짧은 핑"을 한 번 보내
# Claude *구독* 5시간 사용 창을 열어둔다. (스케줄/모델 등은 config.sh 참고)
#
# ⚠️  반드시 "구독 로그인"으로 나가야 5시간 창이 열린다.
#     API 키(ANTHROPIC_API_KEY)로 나가면 과금/세션이 구독과 분리돼 창이 안 열림.
#     → 이 스크립트는 API 키 환경변수를 강제로 제거한다.

set -u

# ── 이 스크립트가 놓인 위치 (어디에 두든 동작) ──
SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/config.sh"

# ── launchd/cron 은 최소 환경으로 실행되므로 HOME/PATH 를 보완 ──
: "${HOME:="$(eval echo ~)"}"
export HOME
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# ── 안전장치: API 키 제거 (구독 인증 강제) ──
unset ANTHROPIC_API_KEY
unset ANTHROPIC_AUTH_TOKEN

# ── 산출물 디렉토리 ──
OUTDIR="${CM_DATADIR:-$SCRIPT_DIR/data}"
mkdir -p "$OUTDIR"
LOG="$OUTDIR/run.log"
STATUS="$OUTDIR/window-status.txt"
TS="$(date '+%Y-%m-%d %H:%M:%S %Z')"
SLOT="$(date '+%H:%M')"

# ── claude 바이너리 탐색 (standalone 우선, 없으면 VSCode 확장 번들 최신 버전) ──
resolve_claude() {
  if command -v claude >/dev/null 2>&1; then command -v claude; return; fi
  if [ -x "$HOME/.local/bin/claude" ]; then echo "$HOME/.local/bin/claude"; return; fi
  find "$HOME/.vscode/extensions" -maxdepth 4 \
       -path "*anthropic.claude-code-*/resources/native-binary/claude" -type f 2>/dev/null \
       | sort -V | tail -1
}
CLAUDE="$(resolve_claude)"
if [ -z "$CLAUDE" ] || [ ! -x "$CLAUDE" ]; then
  echo "$TS  [slot $SLOT]  ERROR  claude binary not found" >> "$LOG"; exit 1
fi

# ── 짧은 핑 + ANTHROPIC_LOG=debug 응답 헤더로 5시간 창 상태를 실측 ──
TMP="$(mktemp -t claude-morning)"
ANTHROPIC_LOG=debug "$CLAUDE" -p "$CM_PROMPT" --model "$CM_MODEL" > "$TMP" 2>&1
RC=$?

RESET_TS="$(grep 'unified-5h-reset' "$TMP" | grep -oE '"[0-9]+"' | tr -d '"' | tail -1)"
UTIL="$(grep 'unified-5h-utilization' "$TMP" | grep -oE '"[0-9.]+"' | tr -d '"' | tail -1)"
STAT="$(grep 'unified-5h-status' "$TMP" | grep -oE '"[a-z_]+"' | tr -d '"' | tail -1)"

# 리셋 시각 사람이 읽게 변환 (macOS: date -r / Linux: date -d @)
human_ts() { date -r "$1" '+%Y-%m-%d %H:%M %Z' 2>/dev/null || date -d "@$1" '+%Y-%m-%d %H:%M %Z'; }

if [ -n "$RESET_TS" ]; then
  RESET_HUMAN="$(human_ts "$RESET_TS")"
  UTIL_PCT="$(awk "BEGIN{printf \"%.0f\", ${UTIL:-0}*100}")"
  MINS_LEFT="$(( (RESET_TS - $(date +%s)) / 60 ))"
  LINE="$TS  [slot $SLOT]  OK  5h window: status=${STAT:-?} used=${UTIL_PCT}% resets=${RESET_HUMAN} (${MINS_LEFT}m left)"
elif [ $RC -eq 0 ]; then
  LINE="$TS  [slot $SLOT]  OK  request ok (window opened) — no rate-limit header seen"
else
  LINE="$TS  [slot $SLOT]  FAIL  exit=$RC — check subscription login (must NOT be API key)"
fi

echo "$LINE" >> "$LOG"
{ echo "== claude-morning : 5-hour window status =="; echo "$LINE"; echo "(claude: $CLAUDE)"; } > "$STATUS"

rm -f "$TMP"
[ $RC -eq 0 ] && exit 0 || exit $RC
