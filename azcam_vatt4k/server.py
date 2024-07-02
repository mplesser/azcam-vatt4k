"""
Setup method for vatt4k azcamserver.
Usage example:
  python -i -m azcam_vatt4k.server
"""

import os
import sys

import azcam
import azcam.utils
import azcam.server
import azcam.shortcuts
from azcam.cmdserver import CommandServer
from azcam.header import System
from azcam.tools.instrument import Instrument
from azcam.tools.arc.controller_arc import ControllerArc
from azcam.tools.arc.exposure_arc import ExposureArc
from azcam.tools.arc.tempcon_arc import TempConArc
from azcam.tools.ds9display import Ds9Display
from azcam.webtools.webserver import WebServer
from azcam.webtools.status.status import Status
from azcam.webtools.exptool.exptool import Exptool

# from azcam_vatt4k.telescope_vatt import VattTCS
from azcam_vatt4k.telescope_vatt_ascom import VattAscom


def setup():

    # parse command line arguments
    try:
        i = sys.argv.index("-system")
        option = sys.argv[i + 1]
    except ValueError:
        option = "menu"
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

    # define folders for system
    azcam.db.systemname = "vatt4k"
    azcam.db.servermode = azcam.db.systemname

    azcam.db.systemfolder = os.path.dirname(__file__)
    azcam.db.systemfolder = azcam.utils.fix_path(azcam.db.systemfolder)
    azcam.db.datafolder = azcam.utils.get_datafolder(datafolder)

    parfile = os.path.join(
        azcam.db.datafolder,
        "parameters",
        f"parameters_server_{azcam.db.systemname}.ini",
    )

    # enable logging
    logfile = os.path.join(azcam.db.datafolder, "logs", "server.log")
    azcam.db.logger.start_logging(logfile=logfile)
    azcam.log(f"Configuring for vatt4k")

    # controller
    controller = ControllerArc()
    controller.timing_board = "gen2"
    controller.clock_boards = ["gen2"]
    controller.video_boards = ["gen2", "gen2"]
    controller.utility_board = "gen2"
    controller.set_boards()
    controller.pci_file = os.path.join(
        azcam.db.datafolder, "dspcode", "dsppci", "pci2.lod"
    )
    controller.timing_file = os.path.join(
        azcam.db.datafolder, "dspcode", "dsptiming", "tim2.lod"
    )
    controller.utility_file = os.path.join(
        azcam.db.datafolder, "dspcode", "dsputility", "util2.lod"
    )
    controller.video_gain = 2
    controller.video_speed = 2
    if lab:
        controller.camserver.set_server("conserver7", 2405)
    else:
        controller.camserver.set_server("vattccdc", 2405)

    # temperature controller
    tempcon = TempConArc()
    azcam.db.tempcon = tempcon
    tempcon.set_calibrations([0, 0, 3])
    tempcon.set_corrections([2.0, 0.0, 0.0], [1.0, 1.0, 1.0])
    tempcon.temperature_correction = 1
    tempcon.control_temperature = -115.0

    # exposure
    exposure = ExposureArc()
    filetype = "MEF"
    exposure.filetype = exposure.filetypes[filetype]
    exposure.image.filetype = exposure.filetypes[filetype]
    exposure.display_image = 0
    if lab:
        exposure.send_image = 1
        exposure.folder = "/data/vattspec"
        exposure.sendimage.set_remote_imageserver()
    else:
        exposure.send_image = 1
        exposure.folder = "/mnt/TBArray/images"
        exposure.sendimage.set_remote_imageserver(
            "10.0.1.108", 6543, "dataserver"
        )  # vattcontrol.vatt

    # detector
    detector_vatt4k = {
        "name": "vatt4k",
        "description": "STA0500 4064x4064 CCD",
        "ref_pixel": [2032, 2032],
        "format": [4064, 7, 0, 20, 4064, 0, 0, 0, 0],
        "focalplane": [1, 1, 1, 2, [2, 0]],
        "roi": [1, 4064, 1, 4064, 2, 2],
        "ext_position": [[1, 2], [1, 1]],
        "jpg_order": [1, 2],
    }
    exposure.set_detpars(detector_vatt4k)
    # WCS - plate scale (from Rich 19Mar13)
    sc = -0.000_052_1
    exposure.image.focalplane.wcs.scale1 = [sc, sc]
    exposure.image.focalplane.wcs.scale2 = [sc, sc]

    # instrument (not used)
    instrument = Instrument()

    # telescope
    telescope = VattAscom()
    if 0:
        telescope.initialize()

    # system header template
    template = os.path.join(
        azcam.db.datafolder, "templates", "fits_template_vatt4k_master.txt"
    )
    system = System("vatt4k", template)
    system.set_keyword("DEWAR", "vatt4k_dewar", "Dewar name")

    # display
    display = Ds9Display()
    display.initialize()

    # par file
    azcam.db.parameters.read_parfile(parfile)
    azcam.db.parameters.update_pars()

    # define and start command server
    cmdserver = CommandServer()
    cmdserver.port = 2402
    azcam.log(f"Starting cmdserver - listening on port {cmdserver.port}")
    azcam.db.tools["api"].initialize_api()
    cmdserver.start()

    # web server
    webserver = WebServer()
    webserver.message = f"for host VATTCCD"
    webserver.index = os.path.join(azcam.db.systemfolder, "index_vatt4k.html")
    webserver.port = 2403
    webserver.start()
    webstatus = Status(webserver)
    webstatus.initialize()
    exptool = Exptool(webserver)
    exptool.initialize()

    # azcammonitor
    azcam.db.monitor.register()

    # GUIs
    if 0:
        import azcam_vatt4k.start_azcamtool

    # finish
    azcam.log("Configuration complete")


# start
setup()
from azcam.cli import *
