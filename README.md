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

```sh 
make library
```

### Just the scratchpad

```sh
make main
```

### Cleaning

```sh
make clean
```

### Drawing

If `run.sh` encounters an error it will terminate immediately and not draw any graphs.
If you still want to draw all the graphs you've generated, you can use the `dot.sh` script to generate svgs and pngs for all `.dot` files in `dot/`. 

```sh
./dot.sh
```
