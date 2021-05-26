# `settings` package

This package specifies numerous settings for the module, which can be edited in the file directly or accessed through functions within programs.

## Files

### [`settings.cj`](half-adder.cj)

Contains settings:

* `debugMessages` whether to print \[DEBUG\] information to the terminal during execution
  * `ToggleDebugMessages` or `SetDebugMessages` can be used to toggle mid-program
  * `DebugMessagesOn` can be used to find the current debug printing status
* `tab` the string to use as a tab in generate dot code (default is two spaces)
* `debugDot` whether to print debug information in the generated dot code
  * `ToggleDebugDot` or `SetDebugDot` can be used to toggle mid-program
  * `DebugDotOn` can be used to find the current debug dot status
* `dotDir` the directory that generated dot files are placed in (default is current directory)
  * `SetDotDir` change the dot directory
* `GetDotFile` from a filename, get the relative path of the resulting dot file, with extension