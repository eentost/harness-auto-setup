#!/bin/bash
# ============================================================
# bootstrap.sh - Harness Auto Setup 초기화 스크립트
# ============================================================
# 설명: 하네스 환경의 디렉터리 구조, 가상환경, 기본 설정 파일을
#       자동으로 생성하는 초기화 스크립트입니다.
# 사용법: ./bootstrap.sh [project_name]
# ============================================================

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로깅 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 프로젝트 이름 확인
PROJECT_NAME=${1:-"harness-project"}
log_info "프로젝트 이름: $PROJECT_NAME"

# 필수 도구 확인
check_prerequisites() {
    log_info "필수 도구 확인 중..."
    
    if ! command -v git &> /dev/null; then
        log_error "Git이 설치되어 있지 않습니다."
        exit 1
    fi
    
    if ! command -v python3 &> /dev/null; then
        log_warning "Python3가 설치되어 있지 않을 수 있습니다."
    fi
    
    if ! command -v docker &> /dev/null; then
        log_warning "Docker가 설치되어 있지 않습니다 (선택사항)."
    fi
    
    log_success "필수 도구 확인 완료"
}

# 디렉터리 구조 생성
create_directory_structure() {
    log_info "디렉터리 구조 생성 중..."
    
    mkdir -p "$PROJECT_NAME"/{config,scripts,data,logs,bin,templates}
    mkdir -p "$PROJECT_NAME"/tests/{unit,integration}
    mkdir -p "$PROJECT_NAME"/docs
    
    log_success "디렉터리 구조 생성 완료"
}

# 가상환경 생성
setup_venv() {
    log_info "Python 가상환경 설정 중..."
    
    if command -v python3 &> /dev/null; then
        cd "$PROJECT_NAME"
        python3 -m venv .venv
        source .venv/bin/activate
        
        # 기본 패키지 설치
        pip install --upgrade pip
        pip install requests pyyaml python-dotenv
        
        log_success "가상환경 설정 완료"
        cd ..
    else
        log_warning "Python3가 없으므로 가상환경 생성을 건너뜁니다."
    fi
}

# 설정 파일 템플릿 생성
create_config_files() {
    log_info "설정 파일 템플릿 생성 중..."
    
    cat > "$PROJECT_NAME/config/config.yaml" << 'YAML'
# Harness 기본 설정
harness:
  version: "1.0.0"
  environment: "development"
  log_level: "INFO"

paths:
  data: "./data"
  logs: "./logs"
  templates: "./templates"

security:
  enable_tls: true
  cert_path: "./certs/server.crt"
  key_path: "./certs/server.key"
YAML

    cat > "$PROJECT_NAME/.env.template" << 'ENV'
# 환경 변수 템플릿 - 실제 값은 .env 에 복사하여 설정하세요
HARNESS_ENV=development
HARNESS_PORT=8080
HARNESS_DEBUG=true
API_KEY=your_api_key_here
SECRET_KEY=your_secret_key_here
ENV

    log_success "설정 파일 템플릿 생성 완료"
}

# 스크립트 권한 부여
setup_scripts() {
    log_info "스크립트 권한 부여 중..."
    
    chmod +x "$PROJECT_NAME/scripts/"*.sh 2>/dev/null || true
    chmod +x "$PROJECT_NAME/bin/"* 2>/dev/null || true
    
    log_success "스크립트 권한 부여 완료"
}

# Git 초기화
init_git() {
    log_info "Git 저장소 초기화 중..."
    
    cd "$PROJECT_NAME"
    if [ ! -d ".git" ]; then
        git init
        echo "*.pyc\n__pycache__/\n*.pyo\n.venv/\n.env\n*.log\n*.tmp\n.DS_Store\n" > .gitignore
        log_success "Git 저장소 초기화 완료"
    else
        log_warning "이미 Git 저장소가 존재합니다."
    fi
    cd ..
}

# 메인 실행
main() {
    echo "============================================"
    echo "  Harness Auto Setup - Bootstrap"
    echo "============================================"
    echo ""
    
    check_prerequisites
    create_directory_structure
    setup_venv
    create_config_files
    setup_scripts
    init_git
    
    echo ""
    echo "============================================"
    log_success "부트스트랩이 완료되었습니다!"
    echo "============================================"
    echo ""
    echo "다음 단계:"
    echo "  1. cd $PROJECT_NAME"
    echo "  2. source .venv/bin/activate  (Python 사용 시)"
    echo "  3. .env.template 을 .env 로 복사하고 값 설정"
    echo "  4. ./scripts/setup_harness.sh 실행"
    echo ""
}

main
