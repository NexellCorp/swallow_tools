## SiFive HiFive1 board specific files

### How to use

The standard way to include the board files is

```c
#include <micro-os-plus/board.h>
```

## Developer info

This section is intended to developers who plan to include this library in their own projects.

### Easy install

This package can be installed from the `npm` [registry](https://www.npmjs.com/package/@sifive/hifive1-board).

```console
$ xpm install @sifive/hifive1-board
```

This package is also available from [GitHub](https://github.com/micro-os-plus/sifive-hifive1-board-xpack):

```console
$ git clone https://github.com/micro-os-plus/sifive-hifive1-board-xpack.git sifive-hifive1-board-xpack.git
```

### Prerequisites

Installing from `npm` registry requires a recent [Node.js](https://nodejs.org) (>7.x; the 6.x LTS version is not compatible), and the `xpm` tool (https://www.npmjs.com/package/xpm).

```console
$ sudo npm install xpm --global
```

On Windows, global packages are installed in the user home folder, and do not require `sudo`.

The source code require a modern C++ compiler, preferably GCC 5 or higher, but was also compiled with GCC 4.8. 

### How to publish

* commit all changes
* update `CHANGELOG.md`; commit with a message like _CHANGELOG: prepare v0.1.2_
* `npm version patch`
* push all changes to GitHub
* `npm publish`

## License

The original content is released under the [MIT License](https://opensource.org/licenses/MIT), with all rights reserved to [Liviu Ionescu](https://github.com/ilg-ul).
