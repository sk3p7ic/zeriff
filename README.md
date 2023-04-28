# zeriff - file diffing done in zig

<img style="float: right;"  alt="Zero the Ziguana" src="https://raw.githubusercontent.com/ziglang/logo/master/zero.svg" width="120" />
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
zig build run
```

and you now have a development version running on your machine.

## Todo:

- [x] File diffing.
- [ ] Create a web server with
  - [ ] Route to check two files and get the patch
  - [ ] Documentation route?
- [ ] Command-line args to either start server or run a diff locally
