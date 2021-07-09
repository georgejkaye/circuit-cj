# A hardware design language for Cangjie

This repo contains a library for designing hardware in Cangjie. In particular, we want to be able to perform the following things:

* Design
* Simulation/Reduction
* Synthesis
* Verification

For more documentation see the [wiki](https://gitlab-uk.rnd.huawei.com/cpl_uk_team/circuits-cj/-/wikis/home).

## Scripts

### Compiling

A script is provided to compile all the files.
If you only want to compile the main executable (which is often desired since compiling the `circuits` package is often lengthy), you can add a `main` flag to just compile this.

```sh
chmod +x compile.sh
# compiles all packages, expecting a main.cj file in src/, creates executable bin/main.out
./compile.sh
# compiles just the main.cj file in src/
./compile.sh main
```

### Running

A script is provided that runs the produced executable and then generates svgs for any `.dot` files in `dot/`.

```sh
# runs the executable ./bin/main.out, then draws any dot graphs in dot/
./run.sh
```

### Drawing

If `run.sh` encounters an error it will terminate immediately and not draw any graphs.
If you still want to draw all the graphs you've generated, you can use the `dot.sh` script to generate svgs and pngs for all `.dot` files in `dot/`. 

```sh
chmod +x dot.sh
./dot.sh
```
