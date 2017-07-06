# log\_happy

Little log viewer that watches for the presence of absence of expected phrases
in log files. I found myself running programs with verbose logging output and
frequently using tmux's buffer search feature to look for the presence or
absence of specific text. It seemed useful to have a program that would scan
the output as it was generated instead of having to go back and manually
search later. That is what this tool does.

`log_happy` allows you to specify a log file it wil read, or a command it will
execute and monitor. It also allows you to specify multiple regex's to expect
either to find or not find in the output. It displays clearly which patterns
where found and which were not and uses green and red text to show whether
each pattern's presence matches your expectation.

## Usage

`log_happy` online help:

    Usage:
      log_happy [options]
      log_happy <filename> [options]
      log_happy [options] -- <cmd>

    Options:

      -v                        Print version information and exit.
      -e<label>;<pattern>       Add something to expect to see in the log stream.
      -E<label>;<patterh>       Add something to expect not to see in the log stream.
      -d<def-file>              Read expectations from a JSON definitions file.
      -i<in-file>               Read JSON definitions from <in-file>.
      -o<out-file>              Write the log to <out-file>. Usefull for viewing
                                output later when executing commands.
      -f                        Similar to tail, do not stop when the end of file
                                is reached but wait for additional modifications
                                to the file. -f is ignored when the input is STDIN.

    Expectation definitions take the format LABEL;REGEX where the LABEL is the text
    label log_happy will use to describe the event, and REGEX is the regular
    expression log_happy will use to identify the event.

## Definitions Format

`log_happy` also allows you to persist your expectations in a JSON definitions
file. JSON expectation definitions follow this format:

    {
      "expected": {
        "<label>": "<regex>",
        "<label>": "<regex>"
      },
      "unexpected": {
        "<label>": "<regex>",
        "<label>": "<regex>"
      }
    }
