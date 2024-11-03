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
    ARCHIVE_SCAN_DIRS
    ARCHIVE_EXTRACT_DIR
    ARCHIVE_STORE_DIR
    ARCHIVE_MARK_PROCESSED
    ARCHIVE_REMOVE_PROCESSED
    ARCHIVE_VERBOSE
EOF
    exit 1
}

# Function to load .env file if it exists
load_env_file() {
    if [ -f ".env" ]; then
        while IFS='=' read -r key value || [ -n "$key" ]; do
            # Skip comments and empty lines
            [[ $key =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            
            # Remove leading/trailing whitespace and quotes
            key=$(echo "$key" | tr -d '"' | tr -d "'" | xargs)
            value=$(echo "$value" | tr -d '"' | tr -d "'" | xargs)
            
            case "$key" in
                ARCHIVE_SCAN_DIRS)      SCAN_DIRS="$value" ;;
                ARCHIVE_EXTRACT_DIR)    EXTRACT_DIR="$value" ;;
                ARCHIVE_STORE_DIR)      ARCHIVE_DIR="$value" ;;
                ARCHIVE_MARK_PROCESSED) MARK_PROCESSED=$(echo "$value" | tr '[:upper:]' '[:lower:]') ;;
                ARCHIVE_REMOVE_PROCESSED) REMOVE_PROCESSED=$(echo "$value" | tr '[:upper:]' '[:lower:]') ;;
                ARCHIVE_VERBOSE)        VERBOSE=$(echo "$value" | tr '[:upper:]' '[:lower:]') ;;
            esac
        done < ".env"
    fi
}

# Function to load environment variables
load_environment() {
    # Override .env file settings with environment variables if they exist
    [ ! -z "${ARCHIVE_SCAN_DIRS}" ] && SCAN_DIRS="${ARCHIVE_SCAN_DIRS}"
    [ ! -z "${ARCHIVE_EXTRACT_DIR}" ] && EXTRACT_DIR="${ARCHIVE_EXTRACT_DIR}"
    [ ! -z "${ARCHIVE_STORE_DIR}" ] && ARCHIVE_DIR="${ARCHIVE_STORE_DIR}"
    [ ! -z "${ARCHIVE_MARK_PROCESSED}" ] && MARK_PROCESSED=$(echo "${ARCHIVE_MARK_PROCESSED}" | tr '[:upper:]' '[:lower:]')
    [ ! -z "${ARCHIVE_REMOVE_PROCESSED}" ] && REMOVE_PROCESSED=$(echo "${ARCHIVE_REMOVE_PROCESSED}" | tr '[:upper:]' '[:lower:]')
    [ ! -z "${ARCHIVE_VERBOSE}" ] && VERBOSE=$(echo "${ARCHIVE_VERBOSE}" | tr '[:upper:]' '[:lower:]')
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

