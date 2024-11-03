Archive Extractor - A story behind 
==================================

Introduction
------------

One of my friends asked me to create a script that would automatically unpack .tar.gz files in a specified directory and delete the archives to make it easier for Windows users, where the 'tar' command is not available by default. Although the task is relatively trivial, I decided to see how such a tool could be written using AI.

Programming with AI
-------------------

At the begining Claude 3.5 Sonnet was used.

```

Let's create a program as bash script that can be run in Linux or Bash in Windows environment.
Program will scan specified directory or directories for archive file.
For each archive file found it will extract file contents to a specified directory or current directory and after that it will move archive file to archive directory if specified or mark it by creating empty ".mark" file or completely remove archive file.
It will use "tar" command for ".tar.gz" archives and "7z" command for files.
At the begining let's assume that execution options will be read from .env file if it exists, environment variables if they were set.
Propose set of program options in a bash script and implement reading from .env file overriden by environment setting and further with command line options.

```

This way first version of program was created.

[extractor-01.sh](log/extractor-01.sh)

It is doing nothing yet but a script defines functions like ``load_env_file``, ``load_environment``, displays usage information and is making some checks.

```
let's call environment variables without "ARCHIVE_" prefix, use them as they are, i.e. "VERBOSE". 
Implement directory scanning for supported files (.tar.gz and .7z), write out additional information about reading directory, files found and extraction process steps.
For each supported file, perform extraction.
```

```
apply these code style fixes: 
- change "SCAN_DIRS" to "SEARCH_DIR" and "scan-dirs" option to "search"
- change "EXTRACT_DIR" to "OUTPUT_DIR" and "extract-dirs" option to "output"
- change "archive-dir" option to "archive"
```

```
apply these changes:
- assume that an option like "VERBOSE" is set to true if it is not empty and not "0"
- add PRETEND option as and when it is set to true, operations would not be taken, program will only print what will be done
- only one directory will be scanned for archive files
- mark option should have value of file name extension, like ".mark" - use ".mark" as default value for mark option but allow to disable mark file creation by simple setting mark option to an empty value
- if mark option for each archive file found check if mark file exists and if that so, omit file and print log message about this situation
```

```
implement operation that will move extracted archive file to output directory if it is set.
create output directory if needed.
if output directory was not set but remove option was set then archive file should be removed.
if output directory is not set and remove option is not true and mark file name extension is not empty, then create empty mark file with file name of original archive file with trailing mark file name extension but don't overwrite if it exists.
```

```
apply these code style fixes: 
- change "REMOVE_PROCESSED" to "REMOVE"
- don't use "false" word, use empty value to set option to be a false
- start every log message with capital letter, i.e. "Create directory" instead of "create directory"
```

```
apply these code style fixes: 
- change "ARCHIVE_DIR" to "ARCHIVE"
- change "SEARCH_DIR" to "SEARCH"
- change "OUTPUT_DIR" to "OUTPUT"
```

[extractor-02.sh](log/extractor-02.sh)

[extractor-03.sh](log/extractor-03.sh)

[extractor-04.sh](log/extractor-04.sh)

[extractor-05.sh](log/extractor-05.sh)

At this point there is working script but conversation size has grown too much which makes further development difficult.

New conversation is started together with descriptive prompt containing conversation history log of above queries.

```
Attached script was created by you with the following prompts below. 
Each prompt send to you is separated below with "----------" and conversation ends with "==========".
Analyse program source code and write a prompt text that I would need to put to new chat with you that will describe program in a way that further changes will be possible by you.
```

[prompt-01.txt](log/prompt-01.txt)

Response has a descriptive form of a program based on actual source code.

[description-01.txt](log/description-01.txt)

Let's continue with next changes.

```
apply these code style fixes:
- change "Starting archive processing" to "Starting archive extraction" and "Archive processing completed" to "Archive extraction completed"
- don't use "[INFO] " prefix for verbose messages
```

```
Add support for ".tar.7z", ".tar.bz2", ".tar.xz" and ".zip" archives. 
Don't check if command "tar" or "7z" exists before finding a suitable archive file.
For ".zip" files try "unzip" command first then "7z".
If archive file can't be extracted because an external command is missing, omit the file and print warning about that.
Count how many archive files where extracted during script execution and set exit code to that value so exit code 0 will have meaning that no archive was extracted and negative value will indicate that there were some errors during script execution but positive value of exit code will be count of archive file processed and it should be available to handle by calling program.
Introduce another option "QUIET" with command line option "-q" or "--quiet" which by default is not set.
If it is set, program will not print any messages nor warnings but errors only.
Print log messages about starting process and progress by default if "QUIET" option is not set to true.
Configuration settings should be printed out only if "VERBOSE" option is set to true.
```

After that new description was made to reflects those needs.

[description-02.txt](log/description-02.txt)

This description is used then in a new conversation to create program script again.

[extractor-06.sh](log/extractor-06.sh)

```
Start script with this block of code for better understanding which options are being used:

# Default values
VERBOSE=""
PRETEND=""
QUIET=""
SEARCH="."
OUTPUT=""
ARCHIVE=""
MARK=".mark"
REMOVE=""
```

[extractor-07.sh](log/extractor-07.sh)

```
When checking option value to be true instead using comparisation to true with "[[" command like in this code line "if [[ $VERBOSE == true ]]; then ..." change it and assume that value is true if it is not empty and not "0".
```

[extractor-08.sh](log/extractor-08.sh)

After that I ran out of Claude 3.5 Sonnet free messages.

```
/src/extractor.sh -h
```

```
Usage: extractor.sh [options]

Options:
  -s, --search DIR    Directory to scan for archives (default: ".")
  -o, --output DIR    Directory to extract archives to
  -a, --archive DIR   Directory to move processed archives to
  -m, --mark EXT      Mark file extension (default: ".mark", empty to disable)
  -r, --remove        Remove archives after processing
  -v, --verbose       Enable detailed logging
  -q, --quiet         Suppress all non-error output
  -p, --pretend       Show operations without executing them
  -h, --help          Show this help message

Environment variables: SEARCH, OUTPUT, ARCHIVE, MARK, REMOVE, VERBOSE, QUIET, PRETEND
```

At this moment I moved to ChatGPT.
 
```
Let's create a bash script for archive extraction.

Below is a list of requirements:

Core Functionality:
- Scan a specified directory for archive files (.tar.gz, .tar.7z, .tar.bz2, .tar.xz, .7z, .zip)
- Extract archives to a specified output directory using appropriate commands
- After extraction: move to archive directory, remove, or mark as processed
- Track number of successfully processed archives and return as exit code

Configuration Priority (highest to lowest):
1. Command line arguments
2. Environment variables
3. .env file

Archive Handling:
1. Support multiple archive formats:
   - .tar.gz: tar xzf
   - .tar.7z: tar with 7z
   - .tar.bz2: tar xjf
   - .tar.xz: tar xJf
   - .7z: 7z x
   - .zip: Try unzip first, fallback to 7z
2. Don't pre-check for commands - check when needed
3. Skip archives if required command is missing (with warning)
4. Count successfully processed archives
5. Exit codes:
   - Positive: Number of archives processed
   - Zero: No archives processed
   - Negative: Errors occurred

Output Control:
1. Default mode (QUIET not set):
   - Print start/completion messages
   - Show progress information
   - Display warnings
2. Quiet mode (QUIET set):
   - Show only error messages
3. Verbose mode:
   - Show configuration settings
   - Display detailed operation logs
4. All messages should be direct (no [INFO] prefix)

Post-processing Logic:
1. If OUTPUT is set: Extract to output directory
2. Then, choose one (in priority order):
   - If ARCHIVE is set: Move to archive directory
   - If REMOVE is true: Delete the archive
   - If MARK is not empty: Create mark file (unless exists)

Actual version of source code is included below.
Read it and ask for next changes to be made.

Source code:

[extractor-08.sh]
```

And here is response from ChatGPT.

```
Your script is well-structured and addresses most of the requirements. Here are a few recommended changes to enhance it:

1. **Error Codes Consistency**: Make sure that the exit code for errors is consistent and positive, as bash typically doesn’t support negative exit codes directly. Changing `exit -1` to `exit 1` should make it clearer for error handling.
   
2. **Quiet Mode Enhancements**: You could further optimize the quiet mode by suppressing all logs except for errors, making it even more concise.

3. **Pretend Mode Clarity**: Adjust the pretend mode to show operations consistently without actually executing them. For this, simply add additional verbose or quiet logs with the `[PRETEND]` tag in appropriate places.

4. **.env File Location**: Allow specifying a custom `.env` file path via a command-line argument or an environment variable to make testing and deployment more flexible.

5. **Optional Archive Extensions**: Support `.tar`, `.gz`, `.bz2`, `.xz` files individually, enhancing flexibility in cases where only these specific formats are present.

6. **Unified Summary Output**: After the main loop, provide a final summary report regardless of verbosity settings for a clear output on the number of archives processed.

Let me know if you'd like to test or add further customizations!
```

ChatGPT will show an updated version of the script with enhancements.

Still, they need to be merged into source code manually.

It points that error code can't be directly set to a negative value.
Bash will treat -1 as 255 and we can live with that and make some changes later.

Also the idea of specyfing alternative ``.env`` file sounds interesting.

[extractor-09.sh](log/extractor-09.sh)

I found interesting thing that was introduced in function ``log`` in case of ``error``.

```bash
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
```

The condition is that error is printed only when interactive terminal is being used.
On the other hand it's not used in case of ``warning``.
Strange but we'll come to that later.

There's a little bug in that script, when it's called with "-s" argument option but without value, script will wait indefinitely.
A workaround would be to introduce function that will check if an argument option parameter has value.

```bash
# Check if command line option parameter has a value
check_parameter_value() {
    local option_name="$1"
    if [[ -z "$2" ]]; then
        log error "Missing value for the $option_name option"
        exit 255
    fi
}
```

[extractor-10.sh](log/extractor-10.sh)

Now let's make a limit of 100 archive files at one execution.
This way our script will finish with status 0 if no archive was extracted, number of archives extracted (from 1 to 100) or 255 if error occured.

```
Limit processing to a maximum of 100 archive files at a time for a given script. Displays a message if the limit has been exceeded and the QUIET option has not been set.
```

Claude made total files check first and introduced new variable MAX_FILES.

For some reason it also breaks formatting of usage information.

```
  -r, --remove        Remove archives after processing
  -v, --verbose       Enable detailed logging
  -q, --quiet        Suppress all non-error output
  -p, --pretend      Show operations without executing them
```

[extractor-11.sh](log/extractor-11.sh)

We'll get around that.

```
Don't count total files first, check if maximum limit is reached in a process archives loop. Instead of MAX_FILES use local variable "limit" and don't use variable "total_files" but use "processed" variable.
```

We're getting there.

Just fixed usage information and changed "exit 1" and "exit -1" to "exit 255".

[extractor-12.sh](log/extractor-12.sh)

Now let's do some tests.

```
src/extractor.sh -p -v -s example -o work
```

```
Configuration:
  Search directory: example
  Output directory: work
  Archive directory: not set
  Mark extension: .mark
  Remove archives: false
  Pretend mode: 1
  File limit: 100
Scanning directory: example
Processing: example/test.tar.bz2
Would extract: example/test.tar.bz2
Processing: example/test.tar.7z
Would extract: example/test.tar.7z
Processing: example/test.tar.xz
Would extract: example/test.tar.xz
Processing: example/test.7z
Would extract: example/test.7z
Processing: example/test.zip
Would extract: example/test.zip
Processing: example/test.tar.gz
Would extract: example/test.tar.gz
Processing complete:
  Archives processed: 6
```

So far so good.

Let's go then without pretend option.

```
src/extractor.sh -v -s example -o work
```

```
Would you like to replace the existing file:
  Path:     work/dir/7z.txt
  Size:     3 bytes (1 KiB)
  Modified: 2024-11-02 09:09:30
with the file from archive:
  Path:     dir/7z.txt
  Size:     3 bytes (1 KiB)
  Modified: 2024-11-02 09:09:30
? (Y)es / (N)o / (A)lways / (S)kip all / A(u)to rename all / (Q)uit? 
ERROR: E_FAIL : Unspecified error

Archives with Errors: 1

Failed to extract: example/test.7z
Processing complete:
  Archives processed: 3
  Errors encountered: 1
```

It fails because file exists during extraction using ``7z`` command.
Easy to fix with ``-aoa`` switch for ``7z`` and ``-o`` for ``unzip``.

Also changed ``output_dir`` variable name in ``extract_archive`` function to simply ``output``.

Script is working properly now when it comes to its main function.

```
src/extractor.sh -s example -o work -v
```

```
Configuration:
  Search directory: example
  Output directory: work
  Archive directory: not set
  Mark extension: .mark
  Remove archives: false
  Pretend mode: false
Scanning directory: example
Processing: example/test.tar.bz2
Successfully processed: example/test.tar.bz2
Processing: example/test.tar.7z
Successfully processed: example/test.tar.7z
Processing: example/test.tar.xz
Successfully processed: example/test.tar.xz
Processing: example/test.7z
Successfully processed: example/test.7z
Processing: example/test.zip
Successfully processed: example/test.zip
Processing: example/test.tar.gz
Successfully processed: example/test.tar.gz
Processing complete:
  Archives processed: 6
```

```
ls work/dir/
```

```
7z.txt  tar.7z.txt  tar.bz2.txt  tar.gz.txt  tar.xz.txt  TEST.txt  zip.txt
```

It also creates ``.mark`` files but on the other hand it doesn't ignore archives that were marked before.

```
Improve script in the way that when MARK variable is not empty check if mark file exists and skip archive file and print message if VERBOSE option was set.
```

This time Claude again has some issue with ``show_help``.

```
  -r, --remove        Remove archives after processing
  -v, --verbose       Enable detailed logging
  -q, --quiet        Suppress all non-error output
  -p, --pretend       Show operations without executing them
  -h, --help          Show this help message
```

Cleverly it adds ``skipped`` local variable and counts how many files were omitted.

```bash
    # Check for mark file if MARK is set
    if [[ -n $MARK && -f "$file$MARK" ]]; then
        log verbose "Skipping already processed file: $file"
        ((skipped++))
        continue
    fi
```

[extractor-15.sh](log/extractor-15.sh)

Beautifully, it works as it should now.

```
Configuration:
  Search directory: example
  Output directory: work
  Archive directory: not set
  Mark extension: .mark
  Remove archives: false
  Pretend mode: false
Scanning directory: example
Skipping already processed file: example/test.tar.bz2
Skipping already processed file: example/test.tar.7z
Skipping already processed file: example/test.tar.xz
Skipping already processed file: example/test.7z
Skipping already processed file: example/test.zip
Skipping already processed file: example/test.tar.gz
Processing complete:
  Archives processed: 0
  Archives skipped: 6
```

```
rm example/test.7z.mark
```

```
Processing complete:
  Archives processed: 1
  Archives skipped: 5
```

Let's make clean test, this time with ``archive`` parameter and ``remove`` option.

```
src/extractor.sh -s example -o work -v -a archive
```

```
src/extractor.sh -s example -o work -v -r
```

A final improvement will be to count files moved to the archive or deleted and display the appropriate information.

```
Count how many files were moved to archive or were removed and print unless QUIET option was set.
```

Okay, this time Claude didn't make any changes.

```
The actual moving/removing is handled in the post_process function, but it uses the same counter (processed) for all cases.

If you want to specifically track only moved/removed files (excluding marked files), you would need to add a separate counter specifically for that purpose. Would you like me to help modify the script to track moves and removals separately from other processed files?
````

So here we are.

Let's make some nice documentation and that's it.

Browse all changes merged into one [history log](https://github.com/zoltraks/archive-extractor/commits/main/docs/history/extractor.sh) here.

Conclusions
===========

As you can see, the program was almost entirely generated using queries to language models. However, there were some errors and shortcomings. The whole process took almost a full day's work, about 5 hours. 

At the moment, at the end of 2024, it seems to me that language models should be treated as a tool to facilitate software development, but still require the assistance of the human brain.
