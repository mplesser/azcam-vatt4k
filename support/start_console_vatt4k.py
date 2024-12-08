"""
Python process start file
"""

import subprocess

OPTIONS = ""
CMD = f"ipython --ipython-dir=/data/ipython --profile azcamconsole -i -m azcam_vatt4k.console -- {OPTIONS}"

p = subprocess.Popen(
    CMD,
    creationflags=subprocess.CREATE_NEW_CONSOLE,
)
