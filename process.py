files = ["hypergraphs/hypergraph.cj", "hypergraphs/labels.cj", "hypergraphs/components.cj"]
path = "/home/gkaye/circuits-cj/src/"
with open(path + "code.cj", "w") as output : 
    output.write("package code\n")
    output.write("import core.*\n")
    for name in files :
        output.write("\n")
        output.write("/*************************************************************\n")
        output.write(" * " + name + "\n")
        output.write(" *************************************************************/\n")
        output.write("\n")
        with open(path + name, "r") as src :
            lines = src.readlines()
            for line in lines :
                if(("package" not in line) and ("import" not in line)) :
                    output.write(line)

