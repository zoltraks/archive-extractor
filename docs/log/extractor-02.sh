#!/bin/bash

# Default values
SCAN_DIRS="."
EXTRACT_DIR="."
ARCHIVE_DIR=""
MARK_PROCESSED=false
REMOVE_PROCESSED=false
VERBOSE=false

# Function to display usage
show_usage() {
    cat << EOF
Usage: $(basename "$0") [options]
Process archive files in specified directories.

Options:
    -s, --scan-dirs     Directories to scan for archives (comma-separated)
    -e, --extract-dir   Directory to extract archives to
    -a, --archive-dir   Directory to move processed archives to
    -m, --mark          Create .mark file for processed archives
    -r, --remove        Remove archives after processing
    -v, --verbose       Enable verbose output
    -h, --help          Show this help message

Configuration can be set via:
    1. .env file
    2. Environment variables
    3. Command line arguments (highest priority)

Environment variables:
    SCAN_DIRS
    EXTRACT_DIR
    ARCHIVE_DIR
    MARK_PROCESSED
    REMOVE_PROCESSED
    VERBOSE
EOF
    exit 1
}

# Function to log messages when verbose mode is enabled
log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo "[INFO] $1"
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
                SCAN_DIRS)       SCAN_DIRS="$value" ;;
                EXTRACT_DIR)     EXTRACT_DIR="$value" ;;
                ARCHIVE_DIR)     ARCHIVE_DIR="$value" ;;
                MARK_PROCESSED)  MARK_PROCESSED=$(echo "$value" | tr '[:upper:]' '[:lower:]') ;;
                REMOVE_PROCESSED) REMOVE_PROCESSED=$(echo "$value" | tr '[:upper:]' '[:lower:]') ;;
                VERBOSE)         VERBOSE=$(echo "$value" | tr '[:upper:]' '[:lower:]') ;;
            esac
        done < ".env"
    fi
}

# Function to load environment variables
load_environment() {
    # Override .env file settings with environment variables if they exist
    [ ! -z "${SCAN_DIRS}" ] && SCAN_DIRS="${SCAN_DIRS}"
    [ ! -z "${EXTRACT_DIR}" ] && EXTRACT_DIR="${EXTRACT_DIR}"
    [ ! -z "${ARCHIVE_DIR}" ] && ARCHIVE_DIR="${ARCHIVE_DIR}"
    [ ! -z "${MARK_PROCESSED}" ] && MARK_PROCESSED=$(echo "${MARK_PROCESSED}" | tr '[:upper:]' '[:lower:]')
    [ ! -z "${REMOVE_PROCESSED}" ] && REMOVE_PROCESSED=$(echo "${REMOVE_PROCESSED}" | tr '[:upper:]' '[:lower:]')
    [ ! -z "${VERBOSE}" ] && VERBOSE=$(echo "${VERBOSE}" | tr '[:upper:]' '[:lower:]')
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--scan-dirs)
                SCAN_DIRS="$2"
                shift 2
                ;;
            -e|--extract-dir)
                EXTRACT_DIR="$2"
                shift 2
                ;;
            -a|--archive-dir)
                ARCHIVE_DIR="$2"
                shift 2
                ;;
            -m|--mark)
                MARK_PROCESSED=true
                shift
                ;;
            -r|--remove)
                REMOVE_PROCESSED=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
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
    local extract_path="$EXTRACT_DIR"
    
    log_verbose "Processing archive: $archive_file"
    
    # Create extraction directory if it doesn't exist
    mkdir -p "$extract_path"
    
    # Extract based on file extension
    if [[ "$archive_file" == *.tar.gz ]]; then
        log_verbose "Extracting tar.gz archive..."
        tar xzf "$archive_file" -C "$extract_path"
    elif [[ "$archive_file" == *.7z ]]; then
        log_verbose "Extracting 7z archive..."
        7z x "$archive_file" -o"$extract_path"
    fi
    
    # Process the extracted archive
    if [ $? -eq 0 ]; then
        log_verbose "Extraction successful"
        
        if [ ! -z "$ARCHIVE_DIR" ]; then
            log_verbose "Moving archive to: $ARCHIVE_DIR/$base_name"
            mkdir -p "$ARCHIVE_DIR"
            mv "$archive_file" "$ARCHIVE_DIR/"
        elif [ "$MARK_PROCESSED" = true ]; then
            log_verbose "Marking archive as processed"
            touch "${archive_file}.mark"
        elif [ "$REMOVE_PROCESSED" = true ]; then
            log_verbose "Removing processed archive"
            rm "$archive_file"
        fi
    else
        echo "Error: Failed to extract $archive_file"
        return 1
    fi
}

# Function to scan directories and process archives
scan_and_process() {
    local IFS=','
    local dirs=($SCAN_DIRS)
    
    for dir in "${dirs[@]}"; do
        dir=$(echo "$dir" | xargs)  # Trim whitespace
        log_verbose "Scanning directory: $dir"
        
        if [ ! -d "$dir" ]; then
            echo "Warning: Directory not found: $dir"
            continue
        fi
        
        # Find and process archives
        while IFS= read -r -d '' file; do
            process_archive "$file"
        done < <(find "$dir" -type f \( -name "*.tar.gz" -o -name "*.7z" \) -print0)
    done
}

# Main initialization
load_env_file
load_environment
parse_arguments "$@"

# Validate configuration
if [ "$VERBOSE" = true ]; then
    echo "Configuration:"
    echo "  Scan directories: $SCAN_DIRS"
    echo "  Extract directory: $EXTRACT_DIR"
    echo "  Archive directory: $ARCHIVE_DIR"
    echo "  Mark processed: $MARK_PROCESSED"
    echo "  Remove processed: $REMOVE_PROCESSED"
    echo "  Verbose: $VERBOSE"
fi

# Validate conflicting options
if [ "$MARK_PROCESSED" = true ] && [ "$REMOVE_PROCESSED" = true ]; then
    echo "Error: Cannot both mark and remove processed archives"
    exit 1
fi

if [ "$REMOVE_PROCESSED" = true ] && [ ! -z "$ARCHIVE_DIR" ]; then
    echo "Error: Cannot both remove and move processed archives"
    exit 1
fi

# Check for required commands
check_requirements

# Start processing
log_verbose "Starting archive processing"
scan_and_process
log_verbose "Archive processing completed"

