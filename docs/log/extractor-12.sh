#!/usr/bin/env bash

# Default values
VERBOSE=""
PRETEND=""
QUIET=""
SEARCH="."
OUTPUT=""
ARCHIVE=""
MARK=".mark"
REMOVE=""
CONFIG=".env"

# Function to display usage information
show_help() {
    cat << EOF
Usage: $(basename "$0") [options]

Options:
  -c, --config ENV    Optional configuration file (default: ".env")
  -s, --search DIR    Directory to scan for archives (default: ".")
  -o, --output DIR    Directory to extract archives to
  -a, --archive DIR   Directory to move processed archives to
  -m, --mark EXT      Mark file extension (default: ".mark", empty to disable)
  -r, --remove        Remove archives after processing
  -v, --verbose       Enable detailed logging
  -q, --quiet         Suppress all non-error output
  -p, --pretend       Show operations without executing them
  -h, --help          Show this help message

Environment variables: CONFIG, SEARCH, OUTPUT, ARCHIVE, MARK, REMOVE, VERBOSE, QUIET, PRETEND

Note: Processing is limited to 100 files per run.
EOF
    exit 0
}

# Function to log messages based on verbosity
log() {
    local level=$1
    shift
    case $level in
        error)   [[ -t 2 ]] && echo "$@" >&2 ;;
        warning) [[ -z $QUIET || $QUIET == "0" ]] && echo "$@" >&2 ;;
        info)    [[ -z $QUIET || $QUIET == "0" ]] && echo "$@" ;;
        verbose) [[ -n $VERBOSE && $VERBOSE != "0" ]] && echo "$@" ;;
    esac
}

# Function to check if a command exists
check_command() {
    command -v "$1" >/dev/null 2>&1
}

# Function to extract an archive
extract_archive() {
    local file=$1
    local output_dir=${2:-.}
    local success=false

    case "${file,,}" in
        *.tar.gz)
            if check_command tar; then
                tar xzf "$file" -C "$output_dir" && success=true
            else
                log warning "tar command not found, skipping $file"
            fi
            ;;
        *.tar.7z)
            if check_command tar && check_command 7z; then
                7z x -so "$file" | tar x -C "$output_dir" && success=true
            else
                log warning "tar or 7z command not found, skipping $file"
            fi
            ;;
        *.tar.bz2)
            if check_command tar; then
                tar xjf "$file" -C "$output_dir" && success=true
            else
                log warning "tar command not found, skipping $file"
            fi
            ;;
        *.tar.xz)
            if check_command tar; then
                tar xJf "$file" -C "$output_dir" && success=true
            else
                log warning "tar command not found, skipping $file"
            fi
            ;;
        *.7z)
            if check_command 7z; then
                7z x "$file" -o"$output_dir" && success=true
            else
                log warning "7z command not found, skipping $file"
            fi
            ;;
        *.zip)
            if check_command unzip; then
                unzip -q "$file" -d "$output_dir" && success=true
            elif check_command 7z; then
                log warning "unzip not found, using 7z as fallback for $file"
                7z x "$file" -o"$output_dir" && success=true
            else
                log warning "Neither unzip nor 7z command found, skipping $file"
            fi
            ;;
        *)
            log warning "Unsupported archive format: $file"
            return 1
            ;;
    esac

    $success
}

# Function to process an archive after extraction
post_process() {
    local file=$1

    if [[ -n $ARCHIVE ]]; then
        if [[ -n $PRETEND && $PRETEND != "0" ]]; then
            log verbose "Would move $file to $ARCHIVE/"
        else
            mv "$file" "$ARCHIVE/" || return 1
        fi
    elif [[ -n $REMOVE && $REMOVE != "0" ]]; then
        if [[ -n $PRETEND && $PRETEND != "0" ]]; then
            log verbose "Would remove $file"
        else
            rm "$file" || return 1
        fi
    elif [[ -n $MARK ]]; then
        local mark_file="$file$MARK"
        if [[ ! -f $mark_file ]]; then
            if [[ -n $PRETEND && $PRETEND != "0" ]]; then
                log verbose "Would create mark file $mark_file"
            else
                touch "$mark_file" || return 1
            fi
        fi
    fi
    return 0
}

# Check if command line option parameter has a value
check_parameter_value() {
    local option_name="$1"
    if [[ -z "$2" ]]; then
        log error "Missing value for the $option_name option"
        exit 255
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config)  check_parameter_value "$@" ; CONFIG="$2"; shift 2 ;;
        -s|--search)  check_parameter_value "$@" ; SEARCH="$2"; shift 2 ;;
        -o|--output)  check_parameter_value "$@" ; OUTPUT="$2"; shift 2 ;;
        -a|--archive) check_parameter_value "$@" ; ARCHIVE="$2"; shift 2 ;;
        -m|--mark)    check_parameter_value "$@" ; MARK="$2"; shift 2 ;;
        -r|--remove)  REMOVE="1"; shift ;;
        -v|--verbose) VERBOSE="1"; shift ;;
        -q|--quiet)   QUIET="1"; shift ;;
        -p|--pretend) PRETEND="1"; shift ;;
        -h|--help)    show_help ;;
        *)            log error "Unknown option: $1"; exit 255 ;;
    esac
done

# Load environment variables from .env file if it exists
if [[ -f "$CONFIG" ]]; then
    # shellcheck disable=SC1091
    source "$CONFIG"
fi

# Set variables
processed=0
errors=0
limit=100

# Validate directories
if [[ ! -d $SEARCH ]]; then
    log error "Search directory does not exist: $SEARCH"
    exit 255
fi

if [[ -n $OUTPUT && ! -d $OUTPUT ]]; then
    if [[ -n $PRETEND && $PRETEND != "0" ]]; then
        log verbose "Would create output directory: $OUTPUT"
    else
        mkdir -p "$OUTPUT" || exit 255
    fi
fi

if [[ -n $ARCHIVE && ! -d $ARCHIVE ]]; then
    if [[ -n $PRETEND && $PRETEND != "0" ]]; then
        log verbose "Would create archive directory: $ARCHIVE"
    else
        mkdir -p "$ARCHIVE" || exit 255
    fi
fi

# Show configuration in verbose mode
if [[ -n $VERBOSE && $VERBOSE != "0" ]]; then
    log verbose "Configuration:"
    log verbose "  Search directory: $SEARCH"
    log verbose "  Output directory: ${OUTPUT:-not set}"
    log verbose "  Archive directory: ${ARCHIVE:-not set}"
    log verbose "  Mark extension: ${MARK:-disabled}"
    log verbose "  Remove archives: ${REMOVE:-false}"
    log verbose "  Pretend mode: ${PRETEND:-false}"
    log verbose "  File limit: $limit"
fi

# Process archives
log info "Scanning directory: $SEARCH"

while IFS= read -r -d '' file; do
    if [[ $processed -ge $limit ]]; then
        log warning "Reached limit of $limit files. Stopping processing."
        break
    fi

    log verbose "Processing: $file"

    if [[ -n $PRETEND && $PRETEND != "0" ]]; then
        log verbose "Would extract: $file"
        ((processed++))
        continue
    fi

    if extract_archive "$file" "${OUTPUT:-.}"; then
        if post_process "$file"; then
            log info "Successfully processed: $file"
            ((processed++))
        else
            log error "Failed to post-process: $file"
            ((errors++))
        fi
    else
        log error "Failed to extract: $file"
        ((errors++))
    fi
done < <(find "$SEARCH" -maxdepth 1 -type f \( -name "*.tar.gz" -o -name "*.tar.7z" -o -name "*.tar.bz2" -o -name "*.tar.xz" -o -name "*.7z" -o -name "*.zip" \) -print0)

# Show summary
if [[ -z $QUIET || $QUIET == "0" ]]; then
    log info "Processing complete:"
    log info "  Archives processed: $processed"
    [[ $errors -gt 0 ]] && log info "  Errors encountered: $errors"
fi

# Exit with appropriate code
if [[ $errors -gt 0 ]]; then
    exit -1
elif [[ $processed -gt 0 ]]; then
    exit "$processed"
else
    exit 0
fi
