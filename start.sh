#!/bin/sh
set -e

### 1. 기본 패키지 업데이트 및 설치
apk update
apk add --no-cache nodejs npm postgresql postgresql-contrib postgresql-client bash curl git

### 2. PostgreSQL 초기화 및 실행
su postgres -c "initdb -D /var/lib/postgresql/data"
rc-update add postgresql
rc-service postgresql start

### 3. DB 및 사용자 생성
su postgres -c "psql -c \"CREATE USER edenuser WITH PASSWORD 'edenpass';\""
su postgres -c "psql -c \"CREATE DATABASE edenyugwa OWNER edenuser;\""

### 4. 프로젝트 클론
mkdir -p /var/www
cd /var/www
if [ ! -d "EdenYugwa" ]; then
  git clone https://github.com/galaxysj/EdenYugwa.git
fi
cd EdenYugwa

### 5. 환경변수 설정
cat <<EOF > .env
DATABASE_URL=postgres://edenuser:edenpass@localhost:5432/edenyugwa
SESSION_SECRET=$(head -c 32 /dev/urandom | base64)
EOF

### 6. 의존성 설치 및 빌드
npm install
npm run build

### 7. pm2 설치 및 앱 실행 (재부팅 시 자동 시작)
npm install -g pm2
pm2 start server/index.ts --interpreter ./node_modules/.bin/ts-node --name edenyugwa
pm2 startup
pm2 save

echo "✅ EdenYugwa 설치 및 실행이 완료되었습니다!"
echo "🌐 서버 실행 확인: pm2 status"
echo "🔑 기본 관리자/매니저 계정은 코드에 하드코딩되어 자동 생성됩니다."
