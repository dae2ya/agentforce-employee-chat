#!/usr/bin/env bash
# =============================================================================
# Agentforce Employee Chat — Deployment Script (macOS / Linux)
# =============================================================================
# Usage:
#   chmod +x install.sh
#   ./install.sh                       # 기본: 현재 default org에 배포
#   ./install.sh --target-org MY_ALIAS # 특정 org에 배포
#   ./install.sh --dry-run             # 실제 배포 없이 검증만
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${SCRIPT_DIR}"
TARGET_ORG=""
DRY_RUN=false

# ── 인수 파싱 ─────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-org|-o)
      TARGET_ORG="$2"; shift 2;;
    --dry-run)
      DRY_RUN=true; shift;;
    *)
      echo "Unknown option: $1" >&2; exit 1;;
  esac
done

ORG_FLAGS=""
[[ -n "${TARGET_ORG}" ]] && ORG_FLAGS="--target-org ${TARGET_ORG}"

# ── 전제 조건 확인 ────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Agentforce Employee Chat — Installation"
echo "═══════════════════════════════════════════════════════"
echo ""

if ! command -v sf &>/dev/null; then
  echo "❌  Salesforce CLI(sf) 가 설치되어 있지 않습니다."
  echo "    https://developer.salesforce.com/tools/salesforcecli 에서 설치하세요."
  exit 1
fi

SF_VERSION=$(sf version --json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('sfdxCli','?'))" 2>/dev/null || echo "unknown")
echo "✔  Salesforce CLI  : ${SF_VERSION}"

# 연결된 org 확인
CURRENT_ORG=$(sf config get target-org --json 2>/dev/null \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('result',[{}])[0].get('value',''))" 2>/dev/null || echo "")
DEPLOY_TARGET="${TARGET_ORG:-${CURRENT_ORG}}"
echo "✔  배포 대상 org   : ${DEPLOY_TARGET:-'(default)'}"
echo ""

if [[ "${DRY_RUN}" == "true" ]]; then
  echo "ℹ️  Dry-run 모드: 실제 배포는 수행하지 않고 검증만 합니다."
  echo ""
fi

# ── 배포 ──────────────────────────────────────────────────────────────────────
DEPLOY_CMD="sf project deploy start \
  --manifest \"${SOURCE_DIR}/package.xml\" \
  --source-dir \"${SOURCE_DIR}/main\" \
  ${ORG_FLAGS} \
  --ignore-conflicts"

[[ "${DRY_RUN}" == "true" ]] && DEPLOY_CMD="${DEPLOY_CMD} --dry-run"

echo "📦  배포 시작..."
echo ""

eval "${DEPLOY_CMD}" || {
  echo ""
  echo "❌  배포 실패. 위의 오류 메시지를 확인하세요."
  exit 1
}

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  ✅  배포 완료!"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "다음 단계:"
echo "  1. Setup → Custom Labels → 'Agentforce_Employee_Agent_ApiName'"
echo "     값을 실제 Agent API 이름으로 변경하세요."
echo "  2. Lightning App Builder에서 다음 컴포넌트를 레코드/앱 페이지에 배치하세요:"
echo "       • Employee Agent Chat Card"
echo "       • Employee Agent Chat Injector"
echo "       • Agentforce Test Console"
echo "       • Closing Progress Dashboard"
echo "  3. Account 레코드 페이지 Quick Action에 다음을 추가하세요:"
echo "       • Ask Employee Agent (Flow)"
echo "       • Launch Employee Agent (Headless LWC)"
echo ""
