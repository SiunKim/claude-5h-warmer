#!/bin/zsh
# claude-morning 설치 (macOS / launchd 전용)
#   config.sh 를 읽어 LaunchAgent plist 를 생성하고 등록한다.
#   값을 바꾼 뒤 다시 실행하면 그대로 갱신된다.
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/config.sh"

if [ "$(uname)" != "Darwin" ]; then
  echo "이 install.sh 는 macOS(launchd) 전용입니다. Linux 는 README 의 cron 섹션을 참고하세요." >&2
  exit 1
fi

LABEL="com.claude-morning"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
RUN="$SCRIPT_DIR/morning-run.sh"
DATADIR="${CM_DATADIR:-$SCRIPT_DIR/data}"
ZSH="$(command -v zsh || echo /bin/zsh)"
PATHVAL="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

chmod +x "$RUN"
mkdir -p "$DATADIR" "$(dirname "$PLIST")"

# ── config.sh 의 시각/평일여부로 StartCalendarInterval 항목 생성 ──
build_intervals() {
  local days t hh mm d
  if [ "$CM_WEEKDAYS_ONLY" = "true" ]; then days=(1 2 3 4 5); else days=(-1); fi
  for t in ${(s: :)CM_TIMES}; do
    hh="${t%%:*}"
    if [[ "$t" == *:* ]]; then mm="${t#*:}"; else mm=0; fi
    hh=$((10#$hh)); mm=$((10#$mm))
    for d in $days; do
      if [ "$d" -lt 0 ]; then
        printf '        <dict><key>Hour</key><integer>%d</integer><key>Minute</key><integer>%d</integer></dict>\n' "$hh" "$mm"
      else
        printf '        <dict><key>Weekday</key><integer>%d</integer><key>Hour</key><integer>%d</integer><key>Minute</key><integer>%d</integer></dict>\n' "$d" "$hh" "$mm"
      fi
    done
  done
}
INTERVALS="$(build_intervals)"

# ── plist 생성 ──
cat > "$PLIST" <<PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$ZSH</string>
        <string>$RUN</string>
    </array>
    <key>StartCalendarInterval</key>
    <array>
$INTERVALS
    </array>
    <key>StandardOutPath</key><string>$DATADIR/launchd.out.log</string>
    <key>StandardErrorPath</key><string>$DATADIR/launchd.err.log</string>
    <!-- launchd 최소 환경 보완. ANTHROPIC_API_KEY 는 넣지 않음(구독 인증 강제). -->
    <key>EnvironmentVariables</key>
    <dict>
        <key>HOME</key><string>$HOME</string>
        <key>PATH</key><string>$PATHVAL</string>
    </dict>
    <key>ProcessType</key><string>Background</string>
</dict>
</plist>
PLIST_EOF

plutil -lint "$PLIST" >/dev/null
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"

echo "✅ 설치 완료"
echo "  스케줄 : $CM_TIMES   (평일만 = $CM_WEEKDAYS_ONLY)"
echo "  모델   : $CM_MODEL"
echo "  데이터 : $DATADIR"
echo
echo "지금 바로 테스트: launchctl kickstart -k gui/$(id -u)/$LABEL"
echo "상태 확인       : cat \"$DATADIR/window-status.txt\""
echo "제거            : ./uninstall.sh"
