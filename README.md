# A hardware design language for Cangjie

This repo contains a library for designing hardware in Cangjie. In particular, we want to be able to perform the following things:

* Design
* Simulation/Reduction
* Synthesis
* Verification

For more documentation see the [wiki](https://gitlab-uk.rnd.huawei.com/cpl_uk_team/circuits-cj/-/wikis/home).

## Compiling

To make compiling easier, you should use `make`.

### Everything

To build the library and create an executable `main.out` from a scratchpad file `src/main.cj`:

```sh
make
```

### Just the library

To build the library in `src/`:

```sh 
make library
```

### Just the scratchpad

To compile an executable `main.out` from a file `src/main.cj`:

```sh
make main
```

### Drawing

To draw all the graphs in `dot/`:

```sh
make dot
```

### Cleaning

To delete the build directory `circuits/`, the executable `main.out`, and any svgs in `dot/`:

```sh
make clean
```