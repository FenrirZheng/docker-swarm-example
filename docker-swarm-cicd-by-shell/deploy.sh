#!/bin/bash
set -e

export "PROJECT_ROOT=$(pwd)"
export STACK_NAME=casino
export REGISTRY=reg.alliance.com
export TAG=latest
export APP_JAR=adapter-mng-0.0.1-SNAPSHOT.jar
export REPOSITORY='cms/casino-mng'

# Colors for output
#RED='\033[0;31m'
#GREEN='\033[0;32m'
#YELLOW='\033[1;33m'
#NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker Swarm is initialized
check_swarm() {
    if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
        log_error "Docker Swarm is not initialized. Run 'docker swarm init' first."
        exit 1
    fi
    log_info "Docker Swarm is active"
}


# Build the Docker image
build_image() {
    log_info "Building Docker image..."
    cd "$PROJECT_ROOT"

    if [ ! -f "${APP_JAR}" ]; then
        log_error "${APP_JAR} not found. Run './deploy.sh jar' first."
        exit 1
    fi

    docker build --build-arg APP_JAR="${APP_JAR}" -t "${REGISTRY}/${REPOSITORY}:${TAG}" .
    log_info "Image built: ${REGISTRY}/${REPOSITORY}:${TAG}"
}

# Push image to registry (if using remote registry)
push_image() {
        log_info "Pushing image to registry..."
        docker push "${REGISTRY}"/"${REPOSITORY}":"${TAG}"
        log_info "Image pushed successfully"
}

# Check required environment variables
check_env() {
    log_info "Environment variables validated"
}

# Deploy the stack
deploy_stack() {
    log_info "Deploying stack '${STACK_NAME}'..."
    cd "$PROJECT_ROOT"

    check_env
    docker pull "${REGISTRY}"/"${REPOSITORY}":latest
    docker stack deploy -c docker-compose.yml "${STACK_NAME}" --with-registry-auth
    log_info "Stack deployed successfully"
}

# Show stack status
show_status() {
    log_info "Stack services:"
    docker stack services "${STACK_NAME}"
    echo ""
    log_info "Stack tasks:"
    docker stack ps "${STACK_NAME}"
}

# Remove the stack
remove_stack() {
    log_warn "Removing stack '${STACK_NAME}'..."
    docker stack rm "${STACK_NAME}"
    log_info "Stack removed"
}

remove_service(){
  docker service rm casino_mng-web
}

# Scale service
scale_service() {
    local service=$1
    local replicas=$2
    log_info "Scaling ${service} to ${replicas} replicas..."
    docker service scale "${STACK_NAME}_${service}=${replicas}"
}

# Print usage
usage() {
    echo Usage: "$0 {jar|build|push|deploy|full|status|remove|scale|logs}"
    echo ""
    echo "Commands:"
    echo "  jar     - Build JAR with Gradle => ./gradlew :adapter-mng:bootJar"
    echo "  build   - Build Docker image => requires ${APP_JAR}"
    echo "  push    - Push image to registry"
    echo "  deploy  - Deploy stack to Swarm"
    echo "  full    - JAR + Build + Deploy <complete workflow>"
    echo "  status  - Show stack status"
    echo "  remove  - Remove stack"
    echo "  scale   - Scale a service <e.g., ./deploy.sh scale mng-web >"
    echo "  logs    - Follow service logs e.g., ./deploy.sh logs mng-web "
}

# Main
case ${1:-help} in
    build)
        build_image
        ;;
    push)
        push_image
        ;;
    deploy)
        check_swarm
        deploy_stack
        show_status
        ;;
    full)
        check_swarm
        build_image
        push_image
        deploy_stack
        show_status
        ;;
    status)
        show_status
        ;;
    remove|rm)
        remove_service
        ;;
    logs)
        service=${2:-mng-web}
        docker service logs -f "${STACK_NAME}_${service}"
        ;;
    update)
      docker service update --force --image "${REGISTRY}/${REPOSITORY}:${TAG}" casino_mng-web
      ;;
    *)
        usage
        exit 1
        ;;
esac
