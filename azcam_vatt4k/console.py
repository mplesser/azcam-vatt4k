"""
Setup method for vatt4k console.
Usage example:
  python -i -m azcam_vatt4k.console
"""

import os
import sys
import threading

import azcam
import azcam_console
import azcam_console.shortcuts
from azcam_console.tools.ds9display import Ds9Display
from azcam_console.tools.focus import FocusConsole


def setup():
    try:
        i = sys.argv.index("-datafolder")
        datafolder = sys.argv[i + 1]
    except ValueError:
        datafolder = None
    try:
        i = sys.argv.index("-lab")
        lab = 1
    except ValueError:
        lab = 0

    # files and folders
    azcam.db.systemname = "vatt4k"

    azcam.db.systemfolder = f"{os.path.dirname(__file__)}"
    azcam.db.datafolder = azcam.utils.get_datafolder(datafolder)

    parfile = os.path.join(
        azcam.db.datafolder,
        "parameters",
        f"parameters_server_{azcam.db.systemname}.ini",
    )

    # start logging
    logfile = os.path.join(azcam.db.datafolder, "logs", "console.log")
    azcam.db.logger.start_logging(logfile=logfile)
    azcam.log(f"Configuring console for {azcam.db.systemname}")

    # display
    display = Ds9Display()
    dthread = threading.Thread(target=display.initialize, args=[])
    dthread.start()  # thread just for speed

    # console tools
    from azcam_console.tools import create_console_tools

    create_console_tools()

    # focus script
    focus = FocusConsole()
    focus.focus_component = "telescope"
    focus.focus_type = "absolute"

    # try to connect to azcamserver
    server = azcam.db.tools["server"]
    connected = server.connect(port=2402)
    if connected:
        azcam.log("Connected to azcamserver")
    else:
        azcam.log("Not connected to azcamserver")

    # par file
    azcam.db.parameters.read_parfile(parfile)
    azcam.db.parameters.update_pars("azcamconsole")

    # finish
    azcam.log("Configuration complete")


# start
setup()
from azcam.cli import *
