#!/usr/bin/env bash
# FSD 5계층 + 빈 index.ts barrel 파일 자동 생성
# 사용법: bash fsd-scaffold.sh (프로젝트 루트에서 실행)
set -euo pipefail

for d in \
  shared/ui \
  shared/lib \
  shared/config \
  shared/api \
  shared/model \
  entities \
  features \
  widgets; do
  mkdir -p "src/$d"
  if [ ! -f "src/$d/index.ts" ]; then
    touch "src/$d/index.ts"
    echo "Created src/$d/index.ts"
  fi
done

# NOTE: pages/ 계층은 Next.js Pages Router 사용 시에만 추가
# mkdir -p src/pages && touch src/pages/index.ts

echo "FSD scaffold complete."
