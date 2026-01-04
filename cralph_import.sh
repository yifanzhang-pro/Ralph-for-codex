#!/bin/bash

# Cralph Import - Convert PRDs to Cralph format using Codex
set -e

# Configuration
CODEX_CMD="${CRALPH_CMD:-codex exec --full-auto --skip-git-repo-check}"
CODEX_BIN="${CODEX_CMD%% *}"

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

show_help() {
    cat << HELPEOF
Cralph Import - Convert PRDs to Cralph Format

Usage: $0 <source-file> [project-name]

Arguments:
    source-file     Path to your PRD/specification file (any format)
    project-name    Name for the new Cralph project (optional, defaults to filename)

Examples:
    $0 my-app-prd.md
    $0 requirements.txt my-awesome-app
    $0 project-spec.json
    $0 design-doc.docx webapp

Supported formats:
    - Markdown (.md)
    - Text files (.txt)
    - JSON (.json)
    - Word documents (.docx)
    - PDFs (.pdf)
    - Any text-based format

The command will:
1. Create a new Cralph project
2. Use Codex to intelligently convert your PRD into:
   - PROMPT.md (Cralph instructions)
   - @fix_plan.md (prioritized tasks)
   - specs/ (technical specifications)

Environment:
    CRALPH_CMD      Override Codex command (default: codex exec --full-auto --skip-git-repo-check)

HELPEOF
}

# Check dependencies
check_dependencies() {
    if ! command -v cralph-setup &> /dev/null; then
        log "ERROR" "Cralph not installed. Run ./install.sh first"
        exit 1
    fi
    
    if ! command -v "$CODEX_BIN" &> /dev/null; then
        log "ERROR" "Codex CLI not found (command: $CODEX_BIN). Install Codex or set CRALPH_CMD."
        exit 1
    fi
}

# Convert PRD using Codex
convert_prd() {
    local source_file=$1
    local project_name=$2
    
    log "INFO" "Converting PRD to Cralph format using Codex..."
    
    # Create conversion prompt
    cat > .cralph_conversion_prompt.md << 'PROMPTEOF'
# PRD to Cralph Conversion Task

You are tasked with converting a Product Requirements Document (PRD) or specification into Cralph for Codex format.

## Input Analysis
Analyze the provided specification file and extract:
- Project goals and objectives
- Core features and requirements  
- Technical constraints and preferences
- Priority levels and phases
- Success criteria

## Required Outputs

Create these files in the current directory:

### 1. PROMPT.md
Transform the PRD into Cralph development instructions:
```markdown
# Cralph Development Instructions

## Context
You are Cralph, an autonomous AI development agent working on a [PROJECT NAME] project.

## Current Objectives
[Extract and prioritize 4-6 main objectives from the PRD]

## Key Principles
- ONE task per loop - focus on the most important thing
- Search the codebase before assuming something isn't implemented
- Use subagents for expensive operations (file searching, analysis)
- Write comprehensive tests with clear documentation
- Update @fix_plan.md with your learnings
- Commit working changes with descriptive messages

## 🧪 Testing Guidelines (CRITICAL)
- LIMIT testing to ~20% of your total effort per loop
- PRIORITIZE: Implementation > Documentation > Tests
- Only write tests for NEW functionality you implement
- Do NOT refactor existing tests unless broken
- Focus on CORE functionality first, comprehensive testing later

## Project Requirements
[Convert PRD requirements into clear, actionable development requirements]

## Technical Constraints
[Extract any technical preferences, frameworks, languages mentioned]

## Success Criteria
[Define what "done" looks like based on the PRD]

## Current Task
Follow @fix_plan.md and choose the most important item to implement next.
```

### 2. @fix_plan.md  
Convert requirements into a prioritized task list:
```markdown
# Cralph Fix Plan

## High Priority
[Extract and convert critical features into actionable tasks]

## Medium Priority  
[Secondary features and enhancements]

## Low Priority
[Nice-to-have features and optimizations]

## Completed
- [x] Project initialization

## Notes
[Any important context from the original PRD]
```

### 3. specs/requirements.md
Create detailed technical specifications:
```markdown
# Technical Specifications

[Convert PRD into detailed technical requirements including:]
- System architecture requirements
- Data models and structures  
- API specifications
- User interface requirements
- Performance requirements
- Security considerations
- Integration requirements

[Preserve all technical details from the original PRD]
```

## Instructions
1. Read and analyze the attached specification file
2. Create the three files above with content derived from the PRD
3. Ensure all requirements are captured and properly prioritized
4. Make the PROMPT.md actionable for autonomous development
5. Structure @fix_plan.md with clear, implementable tasks

PROMPTEOF

    # Run Codex with the source file and prompt
    if $CODEX_CMD < .cralph_conversion_prompt.md; then
        log "SUCCESS" "PRD conversion completed"
        
        # Clean up temp file
        rm -f .cralph_conversion_prompt.md
        
        # Verify files were created
        local missing_files=()
        if [[ ! -f "PROMPT.md" ]]; then missing_files+=("PROMPT.md"); fi
        if [[ ! -f "@fix_plan.md" ]]; then missing_files+=("@fix_plan.md"); fi
        if [[ ! -f "specs/requirements.md" ]]; then missing_files+=("specs/requirements.md"); fi
        
        if [[ ${#missing_files[@]} -ne 0 ]]; then
            log "WARN" "Some files were not created: ${missing_files[*]}"
            log "INFO" "You may need to create these files manually or run the conversion again"
        fi
        
    else
        log "ERROR" "PRD conversion failed"
        rm -f .cralph_conversion_prompt.md
        exit 1
    fi
}

# Main function
main() {
    local source_file="$1"
    local project_name="$2"
    
    # Validate arguments
    if [[ -z "$source_file" ]]; then
        log "ERROR" "Source file is required"
        show_help
        exit 1
    fi
    
    if [[ ! -f "$source_file" ]]; then
        log "ERROR" "Source file does not exist: $source_file"
        exit 1
    fi
    
    # Default project name from filename
    if [[ -z "$project_name" ]]; then
        project_name=$(basename "$source_file" | sed 's/\.[^.]*$//')
    fi
    
    log "INFO" "Converting PRD: $source_file"
    log "INFO" "Project name: $project_name"
    
    check_dependencies
    
    # Create project directory
    log "INFO" "Creating Cralph project: $project_name"
    cralph-setup "$project_name"
    cd "$project_name"
    
    # Copy source file to project
    cp "../$source_file" .
    
    # Run conversion
    convert_prd "$source_file" "$project_name"
    
    log "SUCCESS" "🎉 PRD imported successfully!"
    echo ""
    echo "Next steps:"
    echo "  1. Review and edit the generated files:"
    echo "     - PROMPT.md (Cralph instructions)"  
    echo "     - @fix_plan.md (task priorities)"
    echo "     - specs/requirements.md (technical specs)"
    echo "  2. Start autonomous development:"
    echo "     cralph --monitor"
    echo ""
    echo "Project created in: $(pwd)"
}

# Handle command line arguments
case "${1:-}" in
    -h|--help|"")
        show_help
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
