import sys
import subprocess
import json
import os


def package_dependencies(module_resolve, module, package_name):
    module_name = module["name"]
    for package in module_resolve["resolves"]:
        if package["packageName"] == f"{module_name}/{package_name}":
            output = ""
            for dependency in package["requires"]:
                full_dependency = f"build/{dependency}.cjo"
                output = f"{output}{full_dependency} "
            print(output)
            exit(0)
    print(f"Package {module_name}/{package_name} not found")
    exit(1)


def dependency_order(module_resolve):
    order = []
    for package in module_resolve["resolves"]:
        order.append(package["packageName"])
    order.reverse()
    output = ""
    for dependency in order[1:]:
        output = f"{output}{dependency} "
    print(output)
    exit(0)


def bad_arguments():
    print(
        f"usage: python {sys.argv[0]} mode <module name> <module-resolve.json path> <package>")
    print("")
    print(
        f"    python {sys.argv[0]} --package graphs # Find dependencies of package graphs")
    print(
        f"    python {sys.argv[0]} --order          # Get the dependency order of the module")
    exit(1)


def get_module_resolve():
    subprocess.run(["cpm", "update"], stdout=subprocess.DEVNULL)
    with open("module-resolve.json") as f:
        data = json.load(f)
    return data


def get_module():
    with open("module.json") as f:
        data = json.load(f)
    return data


if __name__ == "__main__":
    if len(sys.argv) < 2:
        bad_arguments()
    module_resolve = get_module_resolve()
    module = get_module()
    if sys.argv[1] == "--package" and len(sys.argv) == 3:
        package_name = sys.argv[2]
        package_dependencies(module_resolve, module, package_name)
    elif sys.argv[1] == "--order" and len(sys.argv) == 2:
        dependency_order(module_resolve)
    bad_arguments()
