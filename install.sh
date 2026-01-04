#!/bin/bash

# Cralph (Codex) - Global Installation Script
set -e

# Configuration
INSTALL_DIR="$HOME/.local/bin"
CRALPH_HOME="$HOME/.cralph"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    local level=$1
    local message=$2
    local color=""

    case $level in
        "INFO")  color=$BLUE ;;
        "WARN")  color=$YELLOW ;;
        "ERROR") color=$RED ;;
        "SUCCESS") color=$GREEN ;;
    esac

    echo -e "${color}[$(date '+%H:%M:%S')] [$level] $message${NC}"
}

# Check dependencies
check_dependencies() {
    log "INFO" "Checking dependencies..."

    local missing_deps=()

    if ! command -v codex &> /dev/null; then
        missing_deps+=("codex")
    fi

    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi

    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log "ERROR" "Missing required dependencies: ${missing_deps[*]}"
        echo "Install the missing dependencies and retry."
        echo "  - codex: install the Codex CLI and ensure 'codex' is in PATH"
        echo "  - jq:    https://jqlang.github.io/jq/download/"
        echo "  - git:   https://git-scm.com/downloads"
        exit 1
    fi

    # Optional dependency
    if ! command -v tmux &> /dev/null; then
        log "WARN" "tmux not found. Install it for integrated monitoring."
    fi

    log "SUCCESS" "Dependencies check completed"
}

# Create installation directory
create_install_dirs() {
    log "INFO" "Creating installation directories..."

    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CRALPH_HOME"
    mkdir -p "$CRALPH_HOME/templates"
    mkdir -p "$CRALPH_HOME/lib"

    log "SUCCESS" "Directories created: $INSTALL_DIR, $CRALPH_HOME"
}

# Install scripts and wrappers
install_scripts() {
    log "INFO" "Installing Cralph scripts..."

    # Copy templates and lib components
    cp -r "$SCRIPT_DIR/templates/"* "$CRALPH_HOME/templates/"
    cp -r "$SCRIPT_DIR/lib/"* "$CRALPH_HOME/lib/"

    # Create the main cralph command
    cat > "$INSTALL_DIR/cralph" << 'WRAPEOF'
#!/bin/bash
# Cralph - Main Command

CRALPH_HOME="$HOME/.cralph"
export CRALPH_HOME

exec "$CRALPH_HOME/cralph_loop.sh" "$@"
WRAPEOF

    # Create cralph-monitor command
    cat > "$INSTALL_DIR/cralph-monitor" << 'WRAPEOF'
#!/bin/bash
# Cralph Monitor - Global Command

CRALPH_HOME="$HOME/.cralph"
export CRALPH_HOME

exec "$CRALPH_HOME/cralph_monitor.sh" "$@"
WRAPEOF

    # Create cralph-setup command
    cat > "$INSTALL_DIR/cralph-setup" << 'WRAPEOF'
#!/bin/bash
# Cralph Project Setup - Global Command

CRALPH_HOME="$HOME/.cralph"
export CRALPH_HOME

exec "$CRALPH_HOME/setup.sh" "$@"
WRAPEOF

    # Create cralph-import command
    cat > "$INSTALL_DIR/cralph-import" << 'WRAPEOF'
#!/bin/bash
# Cralph PRD Import - Global Command

CRALPH_HOME="$HOME/.cralph"
export CRALPH_HOME

exec "$CRALPH_HOME/cralph_import.sh" "$@"
WRAPEOF

    # Copy actual script files to Cralph home
    cp "$SCRIPT_DIR/cralph_monitor.sh" "$CRALPH_HOME/"
    cp "$SCRIPT_DIR/cralph_import.sh" "$CRALPH_HOME/"

    # Make all commands executable
    chmod +x "$INSTALL_DIR/cralph"
    chmod +x "$INSTALL_DIR/cralph-monitor"
    chmod +x "$INSTALL_DIR/cralph-setup"
    chmod +x "$INSTALL_DIR/cralph-import"
    chmod +x "$CRALPH_HOME/cralph_monitor.sh"
    chmod +x "$CRALPH_HOME/cralph_import.sh"
    chmod +x "$CRALPH_HOME/lib/"*.sh

    log "SUCCESS" "Cralph scripts installed to $INSTALL_DIR"
}

# Install global cralph_loop.sh
install_cralph_loop() {
    log "INFO" "Installing global cralph_loop.sh..."

    cp "$SCRIPT_DIR/cralph_loop.sh" "$CRALPH_HOME/cralph_loop.sh"
    chmod +x "$CRALPH_HOME/cralph_loop.sh"

    log "SUCCESS" "Global cralph_loop.sh installed"
}

# Install global setup.sh
install_setup() {
    log "INFO" "Installing global setup script..."

    cat > "$CRALPH_HOME/setup.sh" << 'SETUPEOF'
#!/bin/bash

# Cralph Project Setup Script - Global Version
set -e

PROJECT_NAME=${1:-"my-project"}
CRALPH_HOME="$HOME/.cralph"

echo "Setting up Cralph project: $PROJECT_NAME"

# Create project directory in current location
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Create structure
mkdir -p {specs/stdlib,src,examples,logs,docs/generated}

# Copy templates from Cralph home
cp "$CRALPH_HOME/templates/PROMPT.md" .
cp "$CRALPH_HOME/templates/fix_plan.md" @fix_plan.md
cp "$CRALPH_HOME/templates/AGENT.md" @AGENT.md
cp -r "$CRALPH_HOME/templates/specs/"* specs/ 2>/dev/null || true

# Initialize git
git init
echo "# $PROJECT_NAME" > README.md
git add .
git commit -m "Initial Cralph project setup"

echo "Project $PROJECT_NAME created."
echo "Next steps:"
echo "  1. Edit PROMPT.md with your project requirements"
echo "  2. Update specs/ with your project specifications"
echo "  3. Run: cralph --monitor"
echo "  4. Monitor: cralph-monitor (if running manually)"
SETUPEOF

    chmod +x "$CRALPH_HOME/setup.sh"

    log "SUCCESS" "Global setup script installed"
}

# Check PATH
check_path() {
    log "INFO" "Checking PATH configuration..."

    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        log "WARN" "$INSTALL_DIR is not in your PATH"
        echo ""
        echo "Add this to your shell profile (~/.bashrc, ~/.zshrc, or ~/.profile):"
        echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
        echo ""
        echo "Then run: source ~/.bashrc (or restart your terminal)"
        echo ""
    else
        log "SUCCESS" "$INSTALL_DIR is already in PATH"
    fi
}

# Main installation
main() {
    echo "Installing Cralph globally..."
    echo ""

    check_dependencies
    create_install_dirs
    install_scripts
    install_cralph_loop
    install_setup
    check_path

    echo ""
    log "SUCCESS" "Cralph installed successfully"
    echo ""
    echo "Global commands available:"
    echo "  cralph --monitor          # Start Cralph with integrated monitoring"
    echo "  cralph --help            # Show Cralph options"
    echo "  cralph-setup my-project  # Create new Cralph project"
    echo "  cralph-import prd.md     # Convert PRD to Cralph project"
    echo "  cralph-monitor           # Manual monitoring dashboard"
    echo ""
    echo "Quick start:"
    echo "  1. cralph-setup my-awesome-project"
    echo "  2. cd my-awesome-project"
    echo "  3. # Edit PROMPT.md with your requirements"
    echo "  4. cralph --monitor"
    echo ""

    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        echo "Don't forget to add $INSTALL_DIR to your PATH (see above)."
    fi
}

# Handle command line arguments
case "${1:-install}" in
    install)
        main
        ;;
    uninstall)
        log "INFO" "Uninstalling Cralph..."
        rm -f "$INSTALL_DIR/cralph" "$INSTALL_DIR/cralph-monitor" "$INSTALL_DIR/cralph-setup" "$INSTALL_DIR/cralph-import"
        rm -rf "$CRALPH_HOME"
        log "SUCCESS" "Cralph uninstalled"
        ;;
    --help|-h)
        echo "Cralph Installation"
        echo ""
        echo "Usage: $0 [install|uninstall]"
        echo ""
        echo "Commands:"
        echo "  install    Install Cralph globally (default)"
        echo "  uninstall  Remove Cralph installation"
        echo "  --help     Show this help"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac
