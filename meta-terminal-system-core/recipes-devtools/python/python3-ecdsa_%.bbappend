# Backport of meta-python 41d5dfbf9: python3-pbr is not needed at runtime and pulls in python3-pip.
RDEPENDS:${PN}:remove = "python3-pbr"
