# A hardware design language for Cangjie

This repo contains a library for designing hardware in Cangjie.
In particular, we want to be able to perform the following things:

- Design
- Simulation/Reduction
- Synthesis
- Verification

## Compiling

The library compiles with Cangjie version `0.51.4`.

```
cjpm build
```

When developing, you may wish to add the `--incremental` flag so you don't need
to compile the whole project from scratch each time.

```
cjpm build --incremental
```

## Documentation

Documentation can be generated using [Sphinx](https://www.sphinx-doc.org/en/master/).
If you have Sphinx installed, run the following to generate HTML docs in
`docs/_build/html`.

```
make docs
```