#!/usr/bin/env bash
set -euo pipefail

# Find repo root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"

if [[ -f "$ENV_FILE" ]]; then
  # Export variables from .env
  set -a
  source "$ENV_FILE"
  set +a
fi

APP="${1:-all}"
TMP_DIR="$REPO_ROOT/.build"
mkdir -p "$TMP_DIR"

check_tidbyt_env() {
  if [[ -z "${TIDBYT_DEVICE_ID:-}" ]] || [[ -z "${TIDBYT_API_TOKEN:-}" ]] || [[ "${TIDBYT_API_TOKEN:-}" == *"your_tidbyt_api_token"* ]]; then
    echo "❌ Error: TIDBYT_DEVICE_ID and TIDBYT_API_TOKEN must be set in $REPO_ROOT/.env"
    echo "💡 Copy .env.example to .env and fill in your Tidbyt credentials."
    exit 1
  fi
}

retry() {
  local max_attempts=3
  local delay=5
  local attempt=1
  while true; do
    if "$@"; then
      return 0
    fi
    if (( attempt >= max_attempts )); then
      return 1
    fi
    echo "⚠️  Attempt $attempt/$max_attempts failed; retrying in ${delay}s..." >&2
    sleep "$delay"
    ((attempt++))
    ((delay *= 2))
  done
}

push_app() {
  local app_name="$1"
  local star_file="$REPO_ROOT/apps/$app_name/$app_name.star"
  local output_webp="$TMP_DIR/$app_name.webp"
  local clean_name="$(echo "$app_name" | tr -cd '[:alnum:]')"
  local installation_id="custom${clean_name}"
  shift

  echo "🔨 Rendering $app_name..."
  retry pixlet render "$star_file" "$@" -o "$output_webp"

  echo "🚀 Pushing $app_name to Tidbyt device ($TIDBYT_DEVICE_ID)..."
  retry pixlet push "$TIDBYT_DEVICE_ID" "$output_webp" \
    --api-token "$TIDBYT_API_TOKEN" \
    --installation-id "$installation_id" \
    --background

  echo "✅ $app_name pushed successfully!"
}

case "$APP" in
  bitcoin|btc)
    check_tidbyt_env
    push_app "bitcoin"
    ;;
  stocks|stock)
    check_tidbyt_env
    TICKERS="${STOCK_TICKERS:-${STOCK_TICKER:-COMP,XYZ}}"
    push_app "stocks" "tickers=$TICKERS"
    ;;
  github|gh)
    check_tidbyt_env
    REPOS="${GITHUB_REPOS:-block/buzz,block/buzz-app}"
    ARGS=("repos=$REPOS" "github_user=${GITHUB_USER:-wesbillman}" "branch=${GITHUB_BRANCH:-main}" "workflow=${GITHUB_WORKFLOW:-CI}")
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
      ARGS+=("github_token=$GITHUB_TOKEN")
    fi
    push_app "github" "${ARGS[@]}"
    ;;
  buzz)
    check_tidbyt_env
    push_app "buzz" "theme=${BUZZ_THEME:-chartreuse}"
    ;;
  weather)
    check_tidbyt_env
    push_app "weather"
    ;;
  all)
    check_tidbyt_env
    echo "=== Pushing all apps to Tidbyt ==="
    apps=(bitcoin stocks github buzz weather)
    failed_apps=()
    for app in "${apps[@]}"; do
      if ! "$0" "$app"; then
        echo "::warning::Failed to render/push $app after retries"
        failed_apps+=("$app")
      fi
    done

    if (( ${#failed_apps[@]} == ${#apps[@]} )); then
      echo "❌ All apps failed to push!"
      exit 1
    elif (( ${#failed_apps[@]} > 0 )); then
      echo "⚠️  Completed with partial failures (${failed_apps[*]}); remaining apps updated."
    else
      echo "🎉 All apps pushed to device rotation!"
    fi
    ;;
  *)
    echo "Usage: $0 [bitcoin|stocks|github|buzz|weather|all]"
    exit 1
    ;;
esac
