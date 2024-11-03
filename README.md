# Archive Extractor

## Overview

The Archive Extractor is a Bash script designed to automate the extraction of various archive formats. It provides flexible options for processing archives, including batch extraction, post-processing actions, and detailed logging capabilities.

The script was created using language models: Claude, ChatGPT,  Gemini. 

Read the [story behind](docs/CHAT.md).

## Features

- Supports multiple archive formats: `.tar.gz`, `.tar.7z`, `.tar.bz2`, `.tar.xz`, `.7z`, `.zip`
- Configurable through command-line options or environment variables
- Post-processing options: moving, removing, or marking processed files
- Detailed logging with different verbosity levels
- Pretend mode for testing configurations
- Processing limit of 100 files per run
- Fallback options for different extraction tools

## Prerequisites

The script requires one or more of the following commands based on the archive formats you want to process:
- `tar`: For handling tar-based archives (`.tar.gz`, `.tar.bz2`, `.tar.xz`)
- `7z`: For handling `.7z` files and as a fallback for `.zip` files
- `unzip`: Primary handler for `.zip` files

## Usage

```bash
./extractor.sh [options]
```

### Command Line Options

| Option | Long Option | Description | Default |
|--------|-------------|-------------|---------|
| `-c` | `--config` | Configuration file path | `.env` |
| `-s` | `--search` | Directory to scan for archives | `.` |
| `-o` | `--output` | Directory to extract archives to | Current directory |
| `-a` | `--archive` | Directory to move processed archives to | None |
| `-m` | `--mark` | Mark file extension | `.mark` |
| `-r` | `--remove` | Remove archives after processing | Disabled |
| `-v` | `--verbose` | Enable detailed logging | Disabled |
| `-q` | `--quiet` | Suppress all non-error output | Disabled |
| `-p` | `--pretend` | Show operations without executing them | Disabled |
| `-h` | `--help` | Show help message | N/A |

### Environment Variables

The script can be configured using environment variables, which can be set directly or through a configuration file:

- `CONFIG`: Path to configuration file
- `SEARCH`: Directory to scan for archives
- `OUTPUT`: Extraction output directory
- `ARCHIVE`: Directory for processed archives
- `MARK`: Mark file extension
- `REMOVE`: Remove archives after processing
- `VERBOSE`: Enable verbose logging
- `QUIET`: Suppress non-error output
- `PRETEND`: Enable pretend mode

## Configuration File

The script supports configuration through an environment file (default: `.env`). Example configuration:

```bash
SEARCH="/path/to/archives"
OUTPUT="/path/to/output"
ARCHIVE="/path/to/processed"
MARK=".processed"
REMOVE="0"
VERBOSE="1"
```

## Post-Processing Options

The script provides three mutually exclusive post-processing options:

1. **Archive**: Move processed files to an archive directory
2. **Remove**: Delete processed files
3. **Mark**: Create a mark file to indicate processing completion

## Exit Codes

- `0`: No archives processed, or all operations successful
- `1-100`: Number of successfully processed archives
- `255`: Error occurred during processing

## Examples

1. Basic usage with default options:
```bash
./extractor.sh
```

2. Extract to specific directory with verbose logging:
```bash
./extractor.sh --output /path/to/output --verbose
```

3. Process archives and move them to an archive directory:
```bash
./extractor.sh --search /path/to/archives --archive /path/to/processed
```

4. Test configuration without actual processing:
```bash
./extractor.sh --pretend --verbose
```

## Logging Levels

The script provides four logging levels:

1. **Error**: Always displayed (stderr)
2. **Warning**: Displayed unless quiet mode is enabled
3. **Info**: Displayed unless quiet mode is enabled
4. **Verbose**: Only displayed when verbose mode is enabled

## Limitations

- Maximum processing limit of 100 files per run
- Only processes files in the immediate search directory (depth=1)
- Requires appropriate extraction tools for different archive formats

## Error Handling

- Validates directories before processing
- Checks for required commands before extraction
- Reports detailed error messages
- Maintains count of errors encountered

## Best Practices

1. Always test new configurations with `--pretend` mode first
2. Use verbose mode (`-v`) for detailed operation logging
3. Consider using mark files instead of removing archives for safety
4. Check exit codes for automated processing
5. Ensure required extraction tools are installed for your archive types
