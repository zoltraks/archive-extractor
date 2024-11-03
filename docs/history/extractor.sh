#!/bin/bash

# Default values
SEARCH="."
OUTPUT=""
ARCHIVE=""
MARK=".mark"
REMOVE=""
VERBOSE=""
PRETEND=""

# Function to display usage
show_usage() {
    cat << EOF
Usage: $(basename "$0") [options]
Process archive files in specified directory.

Options:
    -s, --search        Directory to search for archives
    -o, --output        Directory to extract archives to
    -a, --archive       Directory to move processed archives to
    -m, --mark          Mark file extension (default: .mark, empty to disable)
    -r, --remove        Remove archives after processing
    -v, --verbose       Enable verbose output
    -p, --pretend      Show what would be done without actual processing
    -h, --help         Show this help message

Configuration can be set via:
    1. .env file
    2. Environment variables
    3. Command line arguments (highest priority)

Environment variables:
    SEARCH
    OUTPUT
    ARCHIVE
    MARK
    REMOVE
    VERBOSE
    PRETEND
EOF
    exit 1
}

# Function to check if a value should be considered "true"
is_true() {
    local value="$1"
    [[ -n "$value" && "$value" != "0" ]]
}

# Function to log messages when verbose mode is enabled
log_verbose() {
    if is_true "$VERBOSE"; then
        echo "[INFO] $1"
    fi
}

# Function to log operation messages
log_operation() {
    if is_true "$PRETEND"; then
        echo "[PRETEND] Would: $1"
    else
        log_verbose "$1"
    fi
}

# Function to load .env file if it exists
load_env_file() {
    if [ -f ".env" ]; then
        log_verbose "Loading .env file"
        while IFS='=' read -r key value || [ -n "$key" ]; do
            # Skip comments and empty lines
            [[ $key =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            
            # Remove leading/trailing whitespace and quotes
            key=$(echo "$key" | tr -d '"' | tr -d "'" | xargs)
            value=$(echo "$value" | tr -d '"' | tr -d "'" | xargs)
            
            case "$key" in
                SEARCH)  SEARCH="$value" ;;
                OUTPUT)  OUTPUT="$value" ;;
                ARCHIVE) ARCHIVE="$value" ;;
                MARK)    MARK="$value" ;;
                REMOVE)  REMOVE="$value" ;;
                VERBOSE) VERBOSE="$value" ;;
                PRETEND) PRETEND="$value" ;;
            esac
        done < ".env"
    fi
}

# Function to load environment variables
load_environment() {
    # Override .env file settings with environment variables if they exist
    [ ! -z "${SEARCH}" ] && SEARCH="${SEARCH}"
    [ ! -z "${OUTPUT}" ] && OUTPUT="${OUTPUT}"
    [ ! -z "${ARCHIVE}" ] && ARCHIVE="${ARCHIVE}"
    [ ! -z "${MARK}" ] && MARK="${MARK}"
    [ ! -z "${REMOVE}" ] && REMOVE="${REMOVE}"
    [ ! -z "${VERBOSE}" ] && VERBOSE="${VERBOSE}"
    [ ! -z "${PRETEND}" ] && PRETEND="${PRETEND}"
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--search)
                SEARCH="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT="$2"
                shift 2
                ;;
            -a|--archive)
                ARCHIVE="$2"
                shift 2
                ;;
            -m|--mark)
                MARK="$2"
                shift 2
                ;;
            -r|--remove)
                REMOVE="1"
                shift
                ;;
            -v|--verbose)
                VERBOSE="1"
                shift
                ;;
            -p|--pretend)
                PRETEND="1"
                shift
                ;;
            -h|--help)
                show_usage
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                ;;
        esac
    done
}

# Function to check if required commands are available
check_requirements() {
    local missing_commands=()
    
    if ! command -v tar &> /dev/null; then
        missing_commands+=("tar")
    fi
    
    if ! command -v 7z &> /dev/null; then
        missing_commands+=("7z")
    fi
    
    if [ ${#missing_commands[@]} -ne 0 ]; then
        echo "Error: Required commands not found: ${missing_commands[*]}"
        echo "Please install the missing packages and try again."
        exit 1
    fi
}

# Function to process a single archive file
process_archive() {
    local archive_file="$1"
    local base_name=$(basename "$archive_file")
    local mark_file="${archive_file}${MARK}"
    
    # Check if file is already processed (if mark option is set)
    if [ -n "$MARK" ] && [ -f "$mark_file" ]; then
        log_verbose "Skipping $archive_file - Already processed (mark file exists)"
        return 0
    fi
    
    log_verbose "Processing archive: $archive_file"
    
    # Handle extraction
    if [ -n "$OUTPUT" ]; then
        # Create extraction directory if it doesn't exist
        if is_true "$PRETEND"; then
            log_operation "Create directory: $OUTPUT"
        else
            mkdir -p "$OUTPUT"
        fi
        
        # Extract based on file extension
        if [[ "$archive_file" == *.tar.gz ]]; then
            log_operation "Extract tar.gz archive: $archive_file to $OUTPUT"
            if ! is_true "$PRETEND"; then
                tar xzf "$archive_file" -C "$OUTPUT"
            fi
        elif [[ "$archive_file" == *.7z ]]; then
            log_operation "Extract 7z archive: $archive_file to $OUTPUT"
            if ! is_true "$PRETEND"; then
                7z x "$archive_file" -o"$OUTPUT"
            fi
        fi
    fi
    
    # Process the extracted archive
    if [ $? -eq 0 ] || is_true "$PRETEND"; then
        log_verbose "Extraction successful"
        
        if [ ! -z "$ARCHIVE" ]; then
            if is_true "$PRETEND"; then
                log_operation "Create directory: $ARCHIVE"
                log_operation "Move $archive_file to $ARCHIVE/$base_name"
            else
                mkdir -p "$ARCHIVE"
                mv "$archive_file" "$ARCHIVE/"
            fi
        elif is_true "$REMOVE"; then
            log_operation "Remove file: $archive_file"
            if ! is_true "$PRETEND"; then
                rm "$archive_file"
            fi
        elif [ -n "$MARK" ]; then
            if [ ! -f "$mark_file" ]; then
                log_operation "Create mark file: $mark_file"
                if ! is_true "$PRETEND"; then
                    touch "$mark_file"
                fi
            else
                log_verbose "Mark file already exists: $mark_file"
            fi
        fi
    else
        echo "Error: Failed to extract $archive_file"
        return 1
    fi
}

# Function to scan directory and process archives
scan_and_process() {
    log_verbose "Scanning directory: $SEARCH"
    
    if [ ! -d "$SEARCH" ]; then
        echo "Error: Directory not found: $SEARCH"
        exit 1
    fi
    
    # Find and process archives
    while IFS= read -r -d '' file; do
        process_archive "$file"
    done < <(find "$SEARCH" -maxdepth 1 -type f \( -name "*.tar.gz" -o -name "*.7z" \) -print0)
}

# Main initialization
load_env_file
load_environment
parse_arguments "$@"

# Validate configuration
if is_true "$VERBOSE"; then
    echo "Configuration:"
    echo "  Search directory: $SEARCH"
    echo "  Output directory: $OUTPUT"
    echo "  Archive directory: $ARCHIVE"
    echo "  Mark extension: ${MARK:-"<disabled>"}"
    echo "  Remove archives: ${REMOVE:-"<disabled>"}"
    echo "  Verbose output: ${VERBOSE:-"<disabled>"}"
    echo "  Pretend mode: ${PRETEND:-"<disabled>"}"
fi

# Check for required commands
check_requirements

# Start processing
log_verbose "Starting archive processing"
scan_and_process
log_verbose "Archive processing completed"

