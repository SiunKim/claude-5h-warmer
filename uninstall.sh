#!/bin/zsh
# claude-morning 제거 (macOS / launchd)
set -u
LABEL="com.claude-morning"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null && echo "언로드됨" || echo "(로드돼 있지 않음)"
rm -f "$PLIST" && echo "plist 삭제됨: $PLIST"
echo "참고: 로그/상태 파일(data/)은 그대로 둡니다. 지우려면 직접 rm 하세요."
