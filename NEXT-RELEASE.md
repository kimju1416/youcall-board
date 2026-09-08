# 다음 릴리스 — 기본판 APK v1.1.9 (노트북에서 굽는다)

> 이 문서는 **정식본(기본판) APK 서명 키가 노트북에만 있어서** 집 PC에서 릴리스를 끝내지 못할 때
> 남기는 작업 지시서다. 소스 수정은 이미 끝나 있고(master에 push 완료), **빌드와 릴리스만 남았다.**

## 무엇이 바뀌었나 (2026-09-08)

**점심은 그 교시가 끝나는 즉시 시작한다.** 예전에는 4교시가 끝나면 쉬는시간 10분을 더한 뒤
점심을 시작해서, 점심 이후 교시가 통째로 10분씩 늦게 표시됐다. 설정 칸 이름이
「점심 시작교시(**이 교시 후 점심**)」이고 실제 학교도 4교시가 끝나면 바로 급식을 가므로 그에 맞췄다.

- 고친 파일: `www/js/app.js` 의 `buildSchedule()` — `t = e + cfg.breakLen` 뒤에 점심을 넣던 것을,
  점심 교시일 때는 `ls = e`(그 교시 종료 시각)부터 시작하도록 바꿨다.
- **같은 계산이 네 곳에 사본으로 있다** — 웹(GAS `index.html`)·기본판 APK·호환판 APK·EXE.
  나머지 셋은 이미 나갔다: GAS **v4.22**(@35), 호환판 **v1.2.2-compat**, EXE **v1.1.9**.
  **기본판만 남았고, 안 내면 그 교실만 시각이 10분 다르게 보인다.**

같은 날 서버도 함께 고쳤다(클라이언트와 무관, 참고용) — 설정 시트의 「1교시 시작시각」을
시트가 시간값(Date)으로 굳혀 저장하면 서버가 못 읽고 기본값 08:50으로 떨어지던 결함(GAS v4.21).

## 할 일

```bash
cd ~/Downloads/프로젝트/youcall-board
git pull                      # 소스 수정은 이미 올라와 있다
bash build-release.sh 1.1.9 --release
```

`build-release.sh`가 판 번호 올리기 → `cap sync` → 빌드 → 서명 → 릴리스 → 내려받기 대조까지 한다.
**키스토어가 없으면 빌드를 시작조차 하지 않는다**(잘못된 키로 굽는 사고 방지).

## 구운 뒤 반드시 확인할 것

1. **APK 안에 새 코드가 실렸는지** — gradle이 assets 변경을 놓치고 `up-to-date`로 옛 apk를
   재사용한 전례가 있다. 아래가 `True / False`로 나와야 한다.

   ```bash
   python -c "import zipfile;s=zipfile.ZipFile('android/app/build/outputs/apk/release/app-release.apk').read('assets/public/js/app.js').decode('utf-8');print('new:', 'var ls = e, le = e + cfg.lunchLen' in s);print('old:', 'if (n === cfg.lunchAfter) { var ls = t,' in s)"
   ```

2. **서명 지문이 기존과 같은지** — 다르면 덮어쓰기 설치가 안 된다.
   `apksigner verify --print-certs` 결과가 SHA-256 `de464c69…` 여야 한다.
   (호환판은 `eac5257e…`로 **다른 키가 맞다** — 둘은 appId가 달라 따로 깔린다.)

3. **내려받기 링크** — `https://github.com/kimju1416/youcall-board/releases/latest/download/YouCallBoard.apk`
   가 200으로 실제 바이트를 주는지. 두 판 연속 404를 낸 적이 있다.

## 릴리스 노트 (그대로 붙여 쓰면 된다)

```
점심 시간 표시를 고쳤습니다.

4교시가 끝나면 쉬는시간 10분이 지난 뒤에 점심이 시작되는 것으로 계산해, 점심 이후 교시가 실제보다 10분씩 늦게 표시되던 문제를 고쳤습니다. 이제 점심은 그 교시가 끝나는 즉시 시작합니다.

4교시가 끝나고 따로 쉬었다가 점심을 먹는 학교라면, 설정 시트의 점심시간(분)에 그 쉬는시간까지 포함해 적어주세요.

기존 판 위에 그대로 덮어쓰기 설치하면 됩니다. 서명은 이전과 같습니다.
```
