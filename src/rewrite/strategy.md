# Reducing combinational circuits

- Keep everything unexpanded for now
- If encounter a subcircuit and all inputs are values, check if these can be applied
- If not, expand subcircuit
- If encounter ◁, check for value in in input with ▷ and expand
- Replace ▷◁ with id
