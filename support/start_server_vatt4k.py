"""
Python process start file
"""

import subprocess

OPTIONS = "-system vatt4k"
CMD = f"ipython --ipython-dir=/data/ipython --profile azcamserver -i -m azcam_vatt4k.server -- {OPTIONS}"

p = subprocess.Popen(
    CMD,
    creationflags=subprocess.CREATE_NEW_CONSOLE,
)
