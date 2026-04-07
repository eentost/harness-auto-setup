# Harness Auto Setup

하네스 (Harness) 환경을 자동으로 구성하고 배포하는 Bash 스크립트 모음입니다.

## 개요

이 저장소는 하네스 프로젝트의 초기화, 환경 설정, Docker 컨테이너 배포를 자동화하는 스크립트를 제공합니다.

## 파일 구조

| 파일 | 설명 |
|------|------|
| `bootstrap.sh` | 프로젝트 디렉터리 구조, 가상환경, 설정 파일 템플릿 생성 |
| `setup_harness.sh` | 시스템 패키지, Python 의존성, Docker, 보안 설정 자동화 |
| `README.md` | 이 문서 |
| `.gitignore` | Git 추적 제외 파일 |

## 빠른 시작

### 1. 저장소 클론

```bash
git clone https://github.com/eentost/harness-auto-setup.git
cd harness-auto-setup
```

### 2. 부트스트랩 실행

```bash
chmod +x bootstrap.sh
./bootstrap.sh my-harness-project
```

### 3. 환경 설정

```bash
cd my-harness-project
cp .env.template .env
# .env 파일에서 API_KEY, SECRET_KEY 값 설정

chmod +x ../setup_harness.sh
../setup_harness.sh --env production --port 8080
```

### 4. Docker 배포 (선택)

```bash
docker-compose up -d
```

## 사용법

### bootstrap.sh 옵션

```bash
./bootstrap.sh [project_name]
```

- `project_name`: 생성할 프로젝트 디렉터리 이름 (기본값: `harness-project`)

### setup_harness.sh 옵션

```bash
./setup_harness.sh [--env ENV] [--port PORT] [--skip-docker]
```

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `--env` | 환경 설정 (development/production) | `development` |
| `--port` | 서비스 포트 | `8080` |
| `--skip-docker` | Docker 설정 건너뜀 | `false` |
| `--help` | 도움말 표시 | - |

## 생성되는 파일

`setup_harness.sh` 실행 시 다음 파일들이 자동 생성됩니다:

- `Dockerfile` - Python 3.11 기반 컨테이너 이미지
- `docker-compose.yml` - 앱 + PostgreSQL 구성
- `requirements.txt` - Python 패키지 의존성
- `main.py` - 하네스 기본 애플리케이션 템플릿
- `certs/tls-config.yaml` - TLS 보안 설정 템플릿
- `scripts/healthcheck.sh` - 서비스 헬스체크 스크립트

## 요구사항

- Linux (Ubuntu/Debian 권장) 또는 macOS
- Bash 4.0+
- Python 3.8+
- Git
- Docker & Docker Compose (선택)

## 보안 주의사항

- `.env` 파일은 절대 커밋하지 마세요 (`.gitignore` 에 포함됨)
- TLS 인증서는 `openssl` 명령으로 직접 생성하세요
- 프로덕션 환경에서는 API 키와 시크릿을 안전한 저장소에서 관리하세요

## 라이선스

MIT License

## 기여

이슈와 PR 을 환영합니다!
