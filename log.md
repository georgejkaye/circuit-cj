# CircuitCJ Development Log

# 2022-08-17

- Begin rewrite framework

# 2022-08-16

- Modify how subgraphs are drawn (add little nodes to indicate when data from a vertex enters a subgraph)
- Finish sorting network and fibonacci examples
- Finish documenting design stuff

# 2022-08-15

- Make sure examples work again
- Extend subcircuit framework to represent values as hierarchical graphs too

# 2022-08-03

- Complete refactoring components package

# 2022-07-29

- Continue refactoring components packag

# 2022-07-28

- Refactor graphs package
- Begin to refactor components package

# 2022-07-27

- Complete integration of labels on ports
- Refactor syntax package, simplify specifications

# 2022-07-26

- Continue to integrate labels on ports
- Begin to generalise exceptions framework

# 2022-07-25

- Complete CPU example
- Add labels to ports on circuits

# 2022-06-28

- Add option to expand dot graphs to show implementation of subcircuits
- Continue CPU example

# 2022-06-27

- Finish implementing hierarchical hypergraphs
- Modify how subcircuits are used
- Gates for thicker width wires are now implemented as subcircuits
- Multiplexers are now implemented as subcircuits

# 2022-06-21

- Ripple adder
- Examples
  - Serial multiplier
  - ALU
- Start implementing hierarchical hypergraphs

# 2022-06-20

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
