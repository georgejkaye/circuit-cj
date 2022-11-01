# CircuitCJ Development Log

## 2022-10-32

- Add composite expansion rule to rewriter
- Add bundler rule to rewriter
- Work on reducing 'next' subgraph in a suitable way

## 2022-10-25

- Fix some issues with the new constructions
- Add some documentation throughout the codebase
- Continue implementing the rewriter

## 2022-10-24

- Port wiki across to Gitee
- Complete reworking constructions to add consistency between them
  - `Bitwise`
  - `Map`
  - `Ripple`
  - `BitwiseRipple`
  - `BitwiseMap` (used to be called `Bitwise`)
  - `BitwiseRipple` (used to be called `InternalRipple`)
  - `RippleMap` (used to be called `GeneralRipple`)
  - `BitwiseRippleMap`

## 2022-10-18

- Continue updating wiki
- Begin reworking constructions

## 2022-10-17

- Begin to update wiki to new framework

## 2022-10-11

- Finish signature framework
- Add waveform subcircuits
- Update examples to use signature framework

## 2022-10-10

- Continue implementing signature framework

## 2022-10-04

- Continue implementing signature framework

## 2022-10-03

- Start implementing signature framework

## 2022-09-27

- Fix bursting subgraph bug
- Add streaming step into unfolding step
- Consider more general signature framework

## 2022-09-26

- Refine waveform framework, add `Waveform` structs
- Refactor in some `use` keywords
- Add function to apply arguments to circuits

## 2022-09-20

- Add in yanking to eliminate pointless loops before applying instant feedback
- Add unfolding equation

## 2022-09-14

- Rethink instant feedback equation

## 2022-09-13

- Implement working instant feedback equation

## 2022-09-06

- Continue to implement the instant feedback equation

## 2022-09-05

- Implement tentacles so we can talk about feedback
- Rehaul graph rendering to reuse code between subgraphs and the top level graph
- Begin to implement the instant feedback equation

## 2022-08-23

- Tweak graph rendering to show forking interfaces better

## 2022-08-22

- Adapt traversal algorithm for graph rewriting

## 2022-08-17

- Begin rewrite framework
- Complete basic graph traversal algorithm

## 2022-08-16

- Modify how subgraphs are drawn (add little nodes to indicate when data from a vertex enters a subgraph)
- Finish sorting network and fibonacci examples
- Finish documenting design stuff

## 2022-08-15

- Make sure examples work again
- Extend subcircuit framework to represent values as hierarchical graphs too

## 2022-08-03

- Complete refactoring components package

## 2022-07-29

- Continue refactoring components packag

## 2022-07-28

- Refactor graphs package
- Begin to refactor components package

## 2022-07-27

- Complete integration of labels on ports
- Refactor syntax package, simplify specifications

## 2022-07-26

- Continue to integrate labels on ports
- Begin to generalise exceptions framework

## 2022-07-25

- Complete CPU example
- Add labels to ports on circuits

## 2022-06-28

- Add option to expand dot graphs to show implementation of subcircuits
- Continue CPU example

## 2022-06-27

- Finish implementing hierarchical hypergraphs
- Modify how subcircuits are used
- Gates for thicker width wires are now implemented as subcircuits
- Multiplexers are now implemented as subcircuits

## 2022-06-21

- Ripple adder
- Examples
  - Serial multiplier
  - ALU
- Start implementing hierarchical hypergraphs

## 2022-06-20

- Implement pasting in subcircuits
- Reimplement operations on interfaced circuits (composition, tensor, trace)
- Add useful constructs (e.g. extracting bits from bundles)
- Implement n-ary logic gates
- Implement 'for each bit' constructor

## 2022-06-14

- Generalise so that vertices represent bundles of wires rather than single wire
- Implement sequential components (delay and trace)
- Add intermediate 'wire end' object to ensure users can't get handles on discarded vertices
- Start to bring examples into the new circuit design framework

## 2022-06-13

- Fix trace
- Implement compressors
- Change framework slightly so that users have handles on _vertices_ rather than graphs (a la hardcaml)
- Implement values
- Implement gates

## 2022-06-07

- Finish wellformedness checker
- Implement {composition,tensor,trace} on new style hypergraphs
- Recreate dot generation for hypergraphs

## 2022-06-06

- Complete makefile
- Refactor to prefer composition over inheritance
- Complete basic hypergraph class

## 2022-05-30

- Start to construct makefile
- Begin to refactor old code
