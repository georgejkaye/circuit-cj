# CircuitCJ Development Log

## 2022-05-30

- Start to construct makefile
- Begin to refactor old code

## 2022-06-06

- Complete makefile
- Refactor to prefer composition over inheritance
- Complete basic hypergraph class

## 2022-06-07

- Finish wellformedness checker
- Implement {composition,tensor,trace} on new style hypergraphs
- Recreate dot generation for hypergraphs

## 2022-06-13

- Fix trace
- Implement compressors
- Change framework slightly so that users have handles on _vertices_ rather than graphs (a la hardcaml)
- Implement values
- Implement gates

## 2022-06-14

- Generalise so that vertices represent bundles of wires rather than single wire
- Implement sequential components (delay and trace)
- Add intermediate 'wire end' object to ensure users can't get handles on discarded vertices
- Start to bring examples into the new circuit design framework

# 2022-06-20

- Implement pasting in subcircuits
- Reimplement operations on interfaced circuits (composition, tensor, trace)
- Add useful constructs (e.g. extracting bits from bundles)
- Implement n-ary logic gates
- Implement 'for each bit' constructor

# 2022-06-21

- Ripple adder
- Examples
  - Serial multiplier
  - ALU
- Start implementing

# 2022-06-27

- Finish implementing hierarchical hypergraphs
  - Adjust dot generation to expand 'macros'
- Examples
  - CPU
  - Fibonacci
  - Sorting network
