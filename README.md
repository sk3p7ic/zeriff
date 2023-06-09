# zeriff - file diffing done in zig

<img alt="Zero the Ziguana" src="https://raw.githubusercontent.com/ziglang/logo/master/zero.svg" width="148" align="right" />

This is a project written in [zig](https://ziglang.org) for file diffing--the process of comparing two files to one another
and calculating the changes in those files.
Thanks is given to [tsoding/piff](https://github.com/tsoding/piff) for help with the implementation of the modified
Levenshtein distance algorithm that was used.

**Zeriff?** ZERIFF = ZEro + dIFF!  
_Please note that this project is not in any way associated with the Zig Foundation. The use of Zero is merely because this project
is named after it._

## Dependencies

This project uses:

- [zigzap/zap](https://github.com/zigzap/zap) - BLAZINGLY FAST replacement for REST APIs written in other lesser languages.

## Building and Running

This software isn't ready yet and probably will never be (it's just a side project to learn Zig), but if you're so inclined as to try
running:

```sh
git clone https://github.com/sk3p7ic/zeriff.git
# You can also use ssh if you like using the better way
```

Then follow the installation instructions found at [zigzap/zap](https://github.com/zigzap/zap) (they're subject to change).  
Finally, run

```sh
# Build, run, and show the help to you.
zig build run -- -h
```

and you now have a development version running on your machine.

## Todo:

- [x] File diffing.
- [X] Can specify two files and get their diff.
- [X] Create a web server with
  - [X] Route to check two files and get the patch
  - [ ] Documentation route?
- [ ] Update tests for web server to follow a more proper format
- [X] Command-line args to either start server or run a diff locally
- [ ] Potentially make diff follow a universal format?
