# A hardware design language for Cangjie

This repo contains a library for designing hardware in Cangjie.
In particular, we want to be able to perform the following things:

- Design
- Simulation/Reduction
- Synthesis
- Verification

For more documentation see the [wiki](https://gitee.com/HW-PLLab/circuit-cj/wikis).

## Compiling

The library compiles with Cangjie version `0.39.4`.

```
cjpm build
```

When developing, you may wish to add the `--incremental` flag so you don't need
to compile the whole project from scratch each time.

```
cjpm build --incremental
```