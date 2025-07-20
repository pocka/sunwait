<!--
Copyright (C) 2025 Shota FUJI

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

SPDX-License-Identifier: GPL-3.0-only
-->

# sunwait

Sunwait calculates sunrise or sunset times and blocks until next sunrise/sunwait event.
This software is a fork of [Dan Risacher's original sunwait program](https://github.com/risacher/sunwait).

## Install using Nix Flake

This repository contains [`flake.nix`](./flake.nix) file that builds and provides `sunwait` executable file.

## Build from source

You need Zig compiler v0.14.x.

```sh
zig build -Dlegacy
```

To build and run the built application in one go, use this command instead:

```sh
zig build -Dlegacy run

# To pass arguments to the program, set them after "--"
zig build -Dlegacy run -- poll
```

To build new CLI, remove `-Dlegacy` option from the above.

```sh
zig build
zig build run
zig build run -- poll
```

To build and install man page as well, run `man` step or set `-Dman` option to the default build.

```sh
# Build and install man page
zig build man

# Build and install man page in addition to the application binary
zig build -Dman
```
