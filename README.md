# A hardware design language for Cangjie

This repo contains a library for designing hardware in Cangjie. In particular, we want to be able to perform the following things:

* Design
* Simulation/Reduction
* Synthesis
* Verification

For more documentation see the [wiki](https://gitlab-uk.rnd.huawei.com/cpl_uk_team/circuits-cj/-/wikis/home).

## Scripts

### Prerequisites

Currently due to the arcane package management system (or my misunderstanding of it), you will need to add all the build directories to the `CANGJIE_PATH` environment variable before compiling.

```sh
export CIRCUITS_ROOT=/home/gkaye/circuits-cj   # replace appropriately
export CANGJIE_PATH=$CangJie_ROOT/build/build/modules/io:$CIRCUITS_ROOT/build/debug:$CIRCUITS_ROOT/build/settings:$CIRCUITS_ROOT/build/circuits:$CIRCUITS_ROOT/build/examples:$CANGJIE_PATH
```

As of the last test with `cjc` (`dev` commit `cceb7f2e78038c67fa1101f78317f582894ad05a`), you may also need to fiddle with the standard library, as the current implementation of Map breaks very easily and blows the stack.

```cpp
// stdlib/core/Map.cj

6 -- let DEFAULT_INITIAL_CAPACITY: Int64 = 16            // 初始容量，应确保为2的次方
6 ++ let DEFAULT_INITIAL_CAPACITY: Int64 = 1024          // 初始容量，应确保为2的次方
```

This might have been fixed by now, but I haven't got around to checking yet.

### Compiling

This repo has currently been tested up to the `cjc` executable compiled from repo `arklang-sync` branch `dev` commit `cceb7f2e78038c67fa1101f78317f582894ad05a`.
As of this commit there is a major bug in the package manager that means nothing can import the `circuits` package.
Therefore the `circuits` package must be compiled to an executable instead.

To compile all the files (whether or not the hacks are requieed)

```sh
chmod +x compile.sh

# compiles all packages, expecting a main.cj file in src/, creates executable bin/main.out
./compile.sh
# compiles debug, settings and circuits, expecting a main function in src/circuits, creates executable build/circuits/main
./compile.sh hack
```

### Running

A script is provided that runs the produced executable and then generates svgs for any `.dot` files in `dot/`.

```sh
chmod +x run.sh

# runs the executable ./bin/main.out, then draws any dot graphs in dot/
./run.sh
# runs the executable ./build/circuits/main, then draws any dot graphs in dot/
./run.sh hack 
```

### Drawing

If `run.sh` encounters an error it will terminate immediately and not draw any graphs.
If you still want to draw all the graphs you've generated, you can use the `dot.sh` script to generate svgs and pngs for all `.dot` files in `dot/`. 

```sh
chmod +x dot.sh
./dot.sh
```
