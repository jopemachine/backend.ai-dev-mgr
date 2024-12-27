#!/bin/bash
# Copyright (c) 2019-2024 Jeongkyu Shin <jshin@lablup.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# =============================================================================
# Backend.AI Developer Environment Management Tool
# =============================================================================
#
# This script assists with the installation and management of Backend.AI.
# It provides the following primary functionalities:
#
# 1. clone: Clone the repository and switch to the specified branch.
# 2. install: Install Backend.AI service for the specified branch.
# 3. run: Run a Backend.AI component. Available components: agent, manager,
#    webserver, storage-proxy, all.
# 4. hs: Manage the halfstack environment. Available commands: up, stop, down,
#    status.
# 5. pants: Manage the pants environment. Available commands: reset.
#
# Repository Caching:
# This script clones the Backend.AI repository into ~/.local/backend.ai/repo
# and reuses this local copy as a cache to reduce network traffic and improve
# performance. By reusing the cached repository, subsequent operations like
# switching branches or pulling updates are faster and require less bandwidth.
#
# Resetting the Cache:
# If you encounter issues or need to reset the repository cache, you can remove
# the cached repository by deleting the directory ~/.local/backend.ai/repo.
# To do this, run the following command:
# rm -rf ~/.local/backend.ai/repo
# After deleting the cache, the script will clone a fresh copy of the repository
# on the next run.
#
# Usage examples:
#
# bndev.sh clone -b main
# Clone the repository and switch to the 'main' branch
#
# bndev.sh hs up -b main
# Start the halfstack environment using the 'main' branch
#
# bndev.sh install -b main
# Install Backend.AI service for the 'main' branch
#
# bndev.sh run all -b main
# Run all Backend.AI components for the 'main' branch
#
# bndev.sh hs status -b main
# Check the status of the halfstack environment for the 'main' branch

# ANSI color codes
RED="\033[0;91m"
GREEN="\033[0;92m"
YELLOW="\033[0;93m"
BLUE="\033[0;94m"
CYAN="\033[0;96m"
WHITE="\033[0;97m"
LRED="\033[1;31m"
LGREEN="\033[1;32m"
LYELLOW="\033[1;33m"
LBLUE="\033[1;34m"
LCYAN="\033[1;36m"
LWHITE="\033[1;37m"
LG="\033[0;37m"
BOLD="\033[1m"
UNDL="\033[4m"
RVRS="\033[7m"
NC="\033[0m"
REWRITELN="\033[A\r\033[K"

# Message functions
show_error() {
  echo " "
  echo -e "${RED}[ERROR]${NC} ${LRED}$1${NC}"
}

show_warning() {
  echo " "
  echo -e "${LRED}[WARN]${NC} ${LYELLOW}$1${NC}"
}

show_info() {
  echo " "
  echo -e "${BLUE}[INFO]${NC} ${GREEN}$1${NC}"
}

show_note() {
  echo " "
  echo -e "${BLUE}[NOTE]${NC} $1"
}

show_important_note() {
  echo " "
  echo -e "${LRED}[NOTE]${NC} ${LYELLOW}$1${NC}"
}

show_with_color() {
  local message=$1
  local color_name=$2

  case $color_name in
    RED) color=$RED ;;
    GREEN) color=$GREEN ;;
    YELLOW) color=$YELLOW ;;
    BLUE) color=$BLUE ;;
    CYAN) color=$CYAN ;;
    WHITE) color=$WHITE ;;
    LRED) color=$LRED ;;
    LGREEN) color=$LGREEN ;;
    LYELLOW) color=$LYELLOW ;;
    LBLUE) color=$LBLUE ;;
    LCYAN) color=$LCYAN ;;
    LWHITE) color=$LWHITE ;;
    LG) color=$LG ;;
    BOLD) color=$BOLD ;;
    UNDL) color=$UNDL ;;
    RVRS) color=$RVRS ;;
    *) color=$NC ;; # Default to no color
  esac

  echo -e "${color}${message}${NC}"
}

usage_header() {
  echo -e "\n${BLUE}Backend.AI Developer Environment Management Tool${NC}\n"
  echo -e "${WHITE}This tool helps you manage the Backend.AI development environment.${NC}\n"
}

usage_footer() {
  echo -e "${BLUE}Options:${NC}"
  echo -e "${GREEN}  -b branch_name${NC}   Specify the branch name to use"
  echo -e "${GREEN}  -p pr_number${NC}     Specify the PR number to use"
  echo -e "${GREEN}  -g graphite${NC}      Use graphite when cloning repository"
  echo -e "${GREEN}  help, -help, --help${NC}   Show this help message"
}

# Display usage
usage() {
  usage_header
  show_with_color "Usage: $0 <argument> [-b branch_name] [component]${NC}\n" YELLOW
  echo -e "${BLUE}Commands:${NC}"
  echo -e "${GREEN}  clone${NC}               Clone the repository and switch to the specified branch"
  echo -e "${GREEN}  clone_and_install${NC}   Clone and Install Backend.AI service for the specified branch"
  echo -e "${GREEN}  install${NC}             Install Backend.AI service for the specified branch"
  echo -e "${GREEN}  run${NC}                 Run a Backend.AI component. Available components: agent, manager, webserver, storage-proxy, app-proxy, all"
  echo -e "${GREEN}  hs${NC}                  Manage the halfstack environment. Available commands: up, stop, down"
  echo -e "${GREEN}  pants${NC}               Manage pants environment. Available commands: reset"
  usage_footer
  exit 1
}

# Display halfstack usage
hs_usage() {
  usage_header
  show_with_color "Usage: $0 hs {up|stop|down} [-b branch_name]\n" YELLOW
  echo -e "${BLUE}Commands for hs:${NC}"
  echo -e "${GREEN}  up${NC}          Start the halfstack environment"
  echo -e "${GREEN}  stop${NC}        Stop the halfstack environment"
  echo -e "${GREEN}  down${NC}        Remove the halfstack environment"
  echo -e "${GREEN}  status${NC}      Show current halfstack environment status"
  usage_footer
  exit 1
}

# Display run usage
run_usage() {
  usage_header
  show_with_color "Usage: $0 run {agent|manager|webserver|storage-proxy|app-proxy|all} [-b branch_name]\n" YELLOW
  echo -e "${BLUE}Commands for run:${NC}"
  echo -e "${GREEN}  agent${NC}          Run the agent component"
  echo -e "${GREEN}  manager${NC}        Run the manager component"
  echo -e "${GREEN}  webserver${NC}      Run the webserver component"
  echo -e "${GREEN}  storage-proxy${NC}  Run the storage proxy component"
  echo -e "${GREEN}  app-proxy${NC}      Run the app proxy component"
  echo -e "${GREEN}  all${NC}            Run all components"
  usage_footer
  exit 1
}

# Check the status of the halfstack environment
hs_status() {
  show_info "Checking halfstack status..."
  docker compose -p ${SANITIZED_BRANCH} -f docker-compose.halfstack.current.yml ps
}

# Display pants usage
pants_usage() {
  usage_header
  show_with_color "Usage: $0 pants {reset} [-b branch_name]\n" YELLOW
  echo -e "${BLUE}Commands for pants:${NC}"
  echo -e "${GREEN}  reset${NC}       Reset the pants environment"
  echo -e "${BLUE}Options:${NC}"
  echo -e "${GREEN}  -b branch_name${NC}   Specify the branch name to use"
  exit 1
}

clone_or_update_repo() {
  LOCAL_REPO="$HOME/.local/backend.ai/repos/${SANITIZED_BRANCH}"
  if [ -d "$LOCAL_REPO" ]; then
    show_info "Updating existing repository for branch ${BRANCH}..."
    pushd "$LOCAL_REPO" > /dev/null
    git checkout "$BRANCH" || ( show_error "Branch '$BRANCH' does not exist." && exit 1 )
    git pull
    popd > /dev/null
  else
    show_info "Cloning repository for branch ${BRANCH}..."
    mkdir -p "$HOME/.local/backend.ai/repos"
    git clone git@github.com:lablup/backend.ai.git "$LOCAL_REPO"

    if [[ "$USE_GRAPHITE" == true ]]; then
      cd "$LOCAL_REPO"
      gt get "${BRANCH}"
    else
      git checkout "$BRANCH" || ( show_error "Branch '$BRANCH' does not exist." && exit 1 )
    fi
  fi
}

# Parse arguments
BRANCH=""
PR_NUMBER=""
USE_GRAPHITE=false
COMMAND=""
SUBCOMMAND=""
COMPONENT=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -b)
      if [ -n "$PR_NUMBER" ]; then
        show_error "You cannot specify both branch(-b) and PR(-p) at the same time."
        exit 1
      fi
      BRANCH=$2
      SANITIZED_BRANCH=${BRANCH//\//_}
      shift
      shift
      ;;
    -p|--pr)
      if [ -n "$BRANCH" ]; then
        show_error "You cannot specify both branch(-b) and PR(-p) at the same time."
        exit 1
      fi
      PR_NUMBER=$2
      shift
      shift
      ;;
    -g|--graphite)
      USE_GRAPHITE=true
      shift
      ;;
    clone|clone_and_install|install|run|hs|pants|help)
      COMMAND=$1
      if [[ $# -gt 1 && ! $2 =~ ^- ]]; then
        SUBCOMMAND=$2
        shift
      fi
      shift
      ;;
    *)
      COMPONENT=$1
      shift
      ;;
  esac
done

get_branch_from_pr() {
  local pr_number=$1
  local api_url="https://api.github.com/repos/lablup/backend.ai/pulls/${pr_number}"

  # Check if GITHUB_TOKEN is set for authenticated requests
  if [ -z "$GITHUB_TOKEN" ]; then
    show_warning "GITHUB_TOKEN is not set. Proceeding with unauthenticated requests (may be rate limited)."
    RESPONSE=$(curl -s "$api_url")
  else
    RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$api_url")
  fi

  # Check if the PR exists
  if echo "$RESPONSE" | grep -q '"message": "Not Found"'; then
    show_error "PR #${pr_number} not found."
    exit 1
  fi

  # Extract the head branch name using jq
  BRANCH=$(echo "$RESPONSE" | jq -r '.head.ref')

  if [ "$BRANCH" == "null" ] || [ -z "$BRANCH" ]; then
    show_error "Failed to retrieve branch name for PR #${pr_number}."
    exit 1
  fi

  SANITIZED_BRANCH=${BRANCH//\//_}
  LOCAL_REPO="$HOME/.local/backend.ai/repos/${SANITIZED_BRANCH}"
  show_info "Resolved branch name: ${SANITIZED_BRANCH}"
}

get_branch() {
  if [ -n "$PR_NUMBER" ]; then
    get_branch_from_pr "$PR_NUMBER"
    if [ -z "$BRANCH" ]; then
      show_error "Failed to retrieve branch name from PR #${PR_NUMBER}."
      exit 1
    fi
  elif [ -z "$BRANCH" ]; then
    if [ -f "BRANCH" ]; then
      BRANCH=$(cat BRANCH)
      SANITIZED_BRANCH=${BRANCH//\//_}
      LOCAL_REPO="$HOME/.local/backend.ai/repos/${SANITIZED_BRANCH}"
    else
      show_error "Branch name is required. Specify with -b or -p."
      usage
    fi
  else
    SANITIZED_BRANCH=${BRANCH//\//_}
    LOCAL_REPO="$HOME/.local/backend.ai/repos/${SANITIZED_BRANCH}"
  fi
}

reset_pants() {
  LOCAL_REPO="$HOME/.local/backend.ai/repos/${SANITIZED_BRANCH}"
  cd "$LOCAL_REPO"
  killall pantsd
  rm -rf .tmp .pants.d .pants.env pants-local ~/.cache/pants
  show_info "Pants environment reset successfully."
}

run_all_components() {
  # Manager
  tmux new-window
  tmux rename-window manager

  # Agent
  tmux new-window
  tmux rename-window agent

  # Storage
  tmux new-window
  tmux rename-window storage

  # Web UI
  tmux new-window
  tmux rename-window webui

  # WSProxy
  tmux new-window
  tmux rename-window wsproxy

  sleep 2
  tmux send-keys -t manager 'OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES ./backend.ai mgr start-server --debug' Enter
  tmux send-keys -t agent './backend.ai ag start-server --debug' Enter
  tmux send-keys -t storage './py -m ai.backend.storage.server' Enter
  tmux send-keys -t web 'export BACKEND_ENDPOINT_TYPE=api && ./py -m ai.backend.web.server --debug' Enter
  tmux send-keys -t wsproxy './backend.ai wsproxy start-server' Enter
}

# Check for help commands
if [[ "$COMMAND" == "help" || "$COMMAND" == "-help" || "$COMMAND" == "--help" ]]; then
  usage
fi

# Execute commands
case "$COMMAND" in
  clone)
    get_branch
    clone_or_update_repo
    cd "$LOCAL_REPO"
    ;;

  install)
    get_branch
    cd "$LOCAL_REPO"
    show_info "Installing dependencies..."
    bash ./scripts/install-dev.sh
    show_info "Building pex..."
    pants export --resolve=python-default --resolve=mypy --resolve=ruff --resolve=towncrier --resolve=pytest
    ;;

  clone_and_install)
    get_branch
    clone_or_update_repo
    cd "$LOCAL_REPO"
    show_info "Installing dependencies..."
    bash ./scripts/install-dev.sh
    show_info "Building pex..."
    pants export --resolve=python-default --resolve=mypy --resolve=ruff --resolve=towncrier --resolve=pytest
    ;;

  run)
    get_branch
    show_info "Local repo path: ${LOCAL_REPO}"
    cd "$LOCAL_REPO"
    case "$SUBCOMMAND" in
      agent)
        export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
        show_info "Running agent..."
        ./backend.ai ag start-server --debug
        ;;
      manager)
        export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
        show_info "Running manager..."
        ./backend.ai mgr start-server --debug
        ;;
      webserver)
        export BACKEND_ENDPOINT_TYPE=api
        show_info "Running webserver..."
        ./py -m ai.backend.web.server --debug
        ;;
      storage-proxy)
        show_info "Running storage proxy..."
        ./py -m ai.backend.storage.server
        ;;
      app-proxy)
        show_info "Running app proxy..."
        ./backend.ai wsproxy start-server
        ;;
      all)
        run_all_components
        ;;
      webui)
        # TODO: Implement this.
        ;;
      *)
        run_usage
        ;;
    esac
    ;;

  hs)
    if [ -z "$SUBCOMMAND" ]; then
      hs_usage
    fi
    get_branch
    cd "$LOCAL_REPO"
    case "$SUBCOMMAND" in
      up)
        show_info "Starting halfstack..."
        docker compose -p ${SANITIZED_BRANCH} -f docker-compose.halfstack.current.yml up -d
        ;;
      stop)
        show_info "Stopping halfstack..."
        docker compose -p ${SANITIZED_BRANCH} -f docker-compose.halfstack.current.yml stop
        ;;
      down)
        show_info "Removing halfstack..."
        docker compose -p ${SANITIZED_BRANCH} -f docker-compose.halfstack.current.yml down
        ;;
      status)
        hs_status
        ;;
      *)
        show_error "Invalid hs command. Use: up, stop, down"
        hs_usage
        ;;
    esac
    ;;

  pants)
    if [ -z "$SUBCOMMAND" ]; then
      pants_usage
    fi
    get_branch
    cd "$LOCAL_REPO"
    case "$SUBCOMMAND" in
      reset)
        reset_pants
        ;;
      *)
        show_error "Invalid pants command. Use: reset"
        pants_usage
        ;;
    esac
    ;;

  *)
    usage
    ;;
esac

