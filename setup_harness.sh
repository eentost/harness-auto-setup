#!/bin/bash
# ============================================================
# setup_harness.sh - Harness 환경 자동 설정 스크립트
# ============================================================
# 설명: 하네스의 주요 컴포넌트를 자동으로 설치하고 설정합니다.
# 사용법: ./setup_harness.sh [--env ENV] [--port PORT] [--skip-docker]
# ============================================================

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# 기본값
ENV="development"
PORT="8080"
SKIP_DOCKER=false

# 로깅
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${PURPLE}[STEP]${NC} $1"; }

# 파라미터 파싱
while [[ $# -gt 0 ]]; do
    case $1 in
        --env) ENV="$2"; shift 2 ;;
        --port) PORT="$2"; shift 2 ;;
        --skip-docker) SKIP_DOCKER=true; shift ;;
        --help) 
            echo "사용법: $0 [--env ENV] [--port PORT] [--skip-docker]"
            exit 0 ;;
        *) log_error "알 수 없는 옵션: $1"; exit 1 ;;
    esac
done

# 환경 변수 로드
load_env() {
    if [ -f ".env" ]; then
        log_info ".env 파일을 로드합니다."
        set -a
        source .env
        set +a
    elif [ -f ".env.template" ]; then
        log_warning ".env 파일이 없습니다. .env.template 을 복사합니다."
        cp .env.template .env
    fi
}

# 시스템 패키지 설치 (Ubuntu/Debian 기준)
install_system_packages() {
    log_step "시스템 패키지 설치 중..."
    
    if [ -f /etc/debian_version ]; then
        sudo apt-get update
        sudo apt-get install -y curl wget jq git
    elif [ -f /etc/redhat-release ]; then
        sudo yum install -y curl wget jq git
    else
        log_warning "알 수 없는 Linux 배포판입니다. 수동으로 패키지를 설치하세요."
    fi
    
    log_success "시스템 패키지 설치 완료"
}

# Python 의존성 설치
install_python_deps() {
    log_step "Python 의존성 설치 중..."
    
    if [ -d ".venv" ]; then
        source .venv/bin/activate
        pip install --upgrade pip
        pip install -r requirements.txt 2>/dev/null || \
            pip install requests pyyaml python-dotenv flask
        log_success "Python 의존성 설치 완료"
    else
        log_warning ".venv 디렉터리가 없습니다."
    fi
}

# Docker 환경 설정
setup_docker() {
    if [ "$SKIP_DOCKER" = true ]; then
        log_info "Docker 설정을 건너뜁니다."
        return
    fi
    
    log_step "Docker 환경 설정 중..."
    
    if ! command -v docker &> /dev/null; then
        log_warning "Docker가 설치되어 있지 않습니다. Docker Compose 설정을 건너뜁니다."
        return
    fi
    
    # docker-compose.yml 생성
    cat > docker-compose.yml << 'COMPOSE'
version: "3.8"
services:
  harness-app:
    build: .
    ports:
      - "${HARNESS_PORT:-8080}:8080"
    environment:
      - HARNESS_ENV=${HARNESS_ENV:-development}
      - API_KEY=${API_KEY}
    volumes:
      - ./data:/app/data
      - ./logs:/app/logs
    restart: unless-stopped
  
  harness-db:
    image: postgres:15
    environment:
      - POSTGRES_DB=harness
      - POSTGRES_USER=harness
      - POSTGRES_PASSWORD=${DB_PASSWORD:-harness123}
    volumes:
      - db-data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  db-data:
COMPOSE

    log_success "Docker Compose 설정 완료"
}

# Dockerfile 생성
create_dockerfile() {
    log_step "Dockerfile 생성 중..."
    
    cat > Dockerfile << 'DOCKER'
FROM python:3.11-slim

WORKDIR /app

# 시스템 패키지
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl jq && \
    rm -rf /var/lib/apt/lists/*

# Python 의존성
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 애플리케이션 복사
COPY . .

# 포트 노출
EXPOSE 8080

# 진입점
CMD ["python", "main.py"]
DOCKER

    log_success "Dockerfile 생성 완료"
}

# requirements.txt 생성
create_requirements() {
    log_step "requirements.txt 생성 중..."
    
    cat > requirements.txt << 'REQ'
requests>=2.28.0
PyYAML>=6.0
python-dotenv>=1.0.0
flask>=2.3.0
gunicorn>=21.0.0
pytest>=7.3.0
REQ

    log_success "requirements.txt 생성 완료"
}

# main.py 템플릿 생성
create_main_app() {
    log_step "main.py 템플릿 생성 중..."
    
    cat > main.py << 'PYTHON'
import os
import yaml
from dotenv import load_dotenv

load_dotenv()

class Harness:
    def __init__(self):
        self.env = os.getenv('HARNESS_ENV', 'development')
        self.port = int(os.getenv('HARNESS_PORT', 8080))
        self.debug = os.getenv('HARNESS_DEBUG', 'false').lower() == 'true'
        
    def load_config(self, config_path='config/config.yaml'):
        with open(config_path, 'r') as f:
            return yaml.safe_load(f)
    
    def run(self):
        print(f"Harness v1.0.0 - Environment: {self.env}")
        print(f"Server running on port {self.port}")

if __name__ == '__main__':
    app = Harness()
    config = app.load_config()
    app.run()
PYTHON

    log_success "main.py 템플릿 생성 완료"
}

# 보안 설정
setup_security() {
    log_step "보안 설정 생성 중..."
    
    mkdir -p certs
    
    # TLS 설정 템플릿
    cat > certs/tls-config.yaml << 'TLS'
# TLS 설정 템플릿
# 실제 인증서는 openssl 로 생성하세요:
# openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
#   -keyout server.key -out server.crt
tls:
  enabled: true
  cert_path: "./certs/server.crt"
  key_path: "./certs/server.key"
  min_version: "TLS1.2"
  cipher_suites:
    - "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
    - "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
TLS

    log_success "보안 설정 생성 완료"
}

# 헬스체크 스크립트
create_healthcheck() {
    log_step "헬스체크 스크립트 생성 중..."
    
    cat > scripts/healthcheck.sh << 'HEALTH'
#!/bin/bash
set -e

PORT=${1:-8080}
ENDPOINT="http://localhost:$PORT/health"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

log "헬스체크 시작 - 엔드포인트: $ENDPOINT"

if curl -sf "$ENDPOINT" > /dev/null; then
    log "HEALTHY - 서비스 정상"
    exit 0
else
    log "UNHEALTHY - 서비스 응답 없음"
    exit 1
fi
HEALTH

    chmod +x scripts/healthcheck.sh
    log_success "헬스체크 스크립트 생성 완료"
}

# 메인 실행
main() {
    echo "============================================"
    echo "  Harness Auto Setup - Environment Setup"
    echo "============================================"
    echo ""
    echo "환경: $ENV"
    echo "포트: $PORT"
    echo "Docker: $( [ "$SKIP_DOCKER" = true ] && echo '건너뜀' || echo '설정' )"
    echo ""
    
    load_env
    install_system_packages
    install_python_deps
    create_requirements
    create_dockerfile
    create_main_app
    setup_docker
    setup_security
    create_healthcheck
    
    echo ""
    echo "============================================"
    log_success "Harness 환경 설정이 완료되었습니다!"
    echo "============================================"
    echo ""
    echo "다음 단계:"
    echo "  1. Docker 사용 시: docker-compose up -d"
    echo "  2. 직접 실행 시: python main.py"
    echo "  3. 헬스체크: ./scripts/healthcheck.sh $PORT"
    echo ""
}

main
