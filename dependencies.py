import sys
import subprocess
import json
import os

def main(build_dir, src_dir, middle_ext, object):
    package_dir = os.path.join(src_dir, f"{object}")
    # Scan the package for its dependencies
    p = subprocess.Popen(["cjc", "--scan-dependency", "--package", package_dir, "--module-name", "circuits"], stdout=subprocess.PIPE)
    out, err = p.communicate()
    data = json.loads(out)
    dependencies = data["dependencies"]
    # Create a string of objects this package depends on
    output = ' '.join([os.path.join(build_dir, f"{dep['packageName']}.{middle_ext}") for dep in dependencies])
    print(output)

if __name__ == "__main__":    
    if(len(sys.argv) < 4):
        print(f"usage: python {sys.argv[0]} <build directory> <source directory> <object file extension> <object to scan (leave blank for main)>")
        print("")
        print(f"    python {sys.argv[0]} circuits/ src/ o graphs  # Find dependencies of package graphs")
        print(f"    python {sys.argv[0]} circuits/ src/ o         # Find dependencies of main file") 
        print("")
        exit(1)
    # If no package specified, scan main package
    if len(sys.argv) < 5:
        object = ""
    else:
        object = sys.argv[4]
    main(sys.argv[1], sys.argv[2], sys.argv[3], object)
