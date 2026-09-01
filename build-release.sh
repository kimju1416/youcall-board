#!/usr/bin/env bash
# 유콜 보드 정식본 APK 빌드·릴리스 — 서명 키가 있는 PC(학교)에서 실행한다.
#
#   bash build-release.sh 1.1.7            # 빌드만
#   bash build-release.sh 1.1.7 --release  # 빌드 + GitHub 릴리스까지
#
# 왜 스크립트인가: 손으로 gh를 치다 파일 이름을 흘려 내려받기 단추가 404가 된 적이 있다.
set -euo pipefail

VER="${1:-}"
DO_RELEASE="${2:-}"
[ -z "$VER" ] && { echo "판 번호를 주세요. 예) bash build-release.sh 1.1.7"; exit 1; }

cd "$(dirname "$0")"
ROOT="$(pwd)"
APK_OUT="$ROOT/android/app/build/outputs/apk/release/app-release.apk"
APK_NAME="YouCallBoard.apk"

echo "== 1. 서명 준비 확인 =="
[ -f keystore.properties ] || { echo "!! keystore.properties가 없습니다. 원래 서명 키가 있어야 기존 사용자가 덮어쓰기 설치를 할 수 있습니다."; exit 1; }
STORE=$(grep -E '^storeFile=' keystore.properties | cut -d= -f2-)
[ -f "$STORE" ] || { echo "!! 키스토어 파일이 없습니다: $STORE"; exit 1; }
echo "   키스토어 OK ($STORE)"

echo "== 2. android/local.properties =="
[ -f android/local.properties ] || { echo "sdk.dir=C:/Android" > android/local.properties; echo "   새로 만들었습니다(경로가 다르면 고치세요)"; }

echo "== 3. 판 번호 올리기 =="
CUR_CODE=$(grep -oE 'versionCode [0-9]+' android/app/build.gradle | grep -oE '[0-9]+')
NEW_CODE=$((CUR_CODE + 1))
sed -i "s/versionCode $CUR_CODE/versionCode $NEW_CODE/" android/app/build.gradle
sed -i "s/versionName \"[^\"]*\"/versionName \"$VER\"/" android/app/build.gradle
grep -E 'versionCode|versionName' android/app/build.gradle | head -2

echo "== 4. 웹 자산 동기화 =="
npm install --silent
npx cap sync android

echo "== 5. 빌드 =="
rm -rf android/app/build/outputs
( cd android && ./gradlew.bat assembleRelease --console=plain )
[ -f "$APK_OUT" ] || { echo "!! APK가 만들어지지 않았습니다"; exit 1; }

echo "== 6. 검증 =="
BT=$(ls -d "${ANDROID_HOME:-C:/Android}"/build-tools/* | sort | tail -1)
"$BT/apksigner.bat" verify --verbose --print-certs "$APK_OUT" | grep -E "^Verified using|SHA-256 digest" | head -4
echo "   ↑ 인증서 SHA-256이 지난 판과 같아야 덮어쓰기 설치가 됩니다"
unzip -p "$APK_OUT" assets/public/js/app.js | grep -c "normalizeWebAppUrl" | sed 's/^/   새 코드 반영(1이면 정상): /'

cp "$APK_OUT" "$ROOT/$APK_NAME"
echo "   => $ROOT/$APK_NAME"

if [ "$DO_RELEASE" = "--release" ]; then
  echo "== 7. 릴리스 =="
  gh release create "v$VER" "$ROOT/$APK_NAME" \
    -R kimju1416/youcall-board \
    -t "유콜 보드 v$VER ($(date +%Y-%m-%d))" \
    -F RELEASE_NOTES.md
  echo "   릴리스 완료"
  # 올라간 파일을 도로 받아 같은 것인지 확인한다
  curl -sL -o /tmp/_dl.apk "https://github.com/kimju1416/youcall-board/releases/latest/download/$APK_NAME"
  if [ "$(sha256sum /tmp/_dl.apk | cut -d' ' -f1)" = "$(sha256sum "$ROOT/$APK_NAME" | cut -d' ' -f1)" ]; then
    echo "   내려받기 확인 OK"
  else
    echo "   !! 올라간 파일이 다릅니다 — 확인 필요"
  fi
  rm -f /tmp/_dl.apk
else
  echo "(릴리스까지 하려면 뒤에 --release 를 붙이세요. RELEASE_NOTES.md를 먼저 확인하세요)"
fi
