"""
Contains the StewardAscom class which defines the Telescope Control System interface
for VATT. This version uses ASCOM/alpaca.
"""

import time
import math

from alpaca.telescope import Telescope as AlpacaTelescope
from alpaca.rotator import Rotator as AlpacaRotator

import requests
from astropy.coordinates import Angle

import azcam
import azcam.utils
import azcam.exceptions
from azcam.tools.telescope import Telescope

from .vatt_filter_code import vatt_filters


class VattAscom(Telescope):
    """
    The interface to the VATT ASCOM telescope server.
    """

    fits_keywords = {
        "RA": ["RightAscension", "right ascension", "str"],
        "DEC": ["Declination", "declination", "str"],
        "AIRMASS": [None, "airmass", "airmass", "float"],
        "HA": [None, "hour angle", "str"],
        "LST-OBS": ["SiderealTime", "local siderial time", "str"],
        "EQUINOX": [None, "equinox of RA and DEC", "float"],
        "JULIAN": [None, "julian date", "float"],
        "ELEVAT": ["Altitude", "elevation", "float"],
        "AZIMUTH": ["Azimuth", "azimuth", "float"],
        "ROTANGLE": ["Position", "rotation angle", "float"],
        "EPOCH": [None, "equinox of RA and DEC", "float"],
        "MOTION": [None, "motion flag", "int"],
        "FILTER": ["FILTER", "instrument filter", "str"],
    }

    def __init__(self, tool_id="telescope", description="VATT telescope"):
        super().__init__(tool_id, description)

        self.vfilters = vatt_filters()

        self.host = "10.0.3.25"
        self.port = 7843

        self.tserver = AlpacaTelescope(f"{self.host}:{self.port}", 0, "http")
        self.rserver = AlpacaRotator(f"{self.host}:{self.port}", 0, "http")

        if self.verbosity:
            azcam.log(f"Connected to telescope: {self.tserver.Name}")
            azcam.log(f"Description: {self.tserver.Description}")

        if 0:
            self.initialize()

        return

    def initialize(self):
        """
        Initializes the telescope interface.
        """

        if self.is_initialized:
            return

        if not self.is_enabled:
            azcam.exceptions.warning(f"{self.description} is not enabled")
            return

        if self.verbosity:
            print(
                f"Telemetry check: RA={self.tserver.RightAscension} DE={self.tserver.Declination}"
            )

        # add keywords
        self.define_keywords()

        self.is_initialized = 1

        return

    # **************************************************************************************************
    # header
    # **************************************************************************************************
    def define_keywords(self):
        """
        Defines and resets telescope keywords.
        """

        # add keywords to header
        for key in self.keywords:
            self.set_keyword(key, None, self.comments[key], self.typestrings[key])

        return

    def get_keyword(self, keyword):
        """
        Reads an telescope keyword value.
        Keyword is the name of the keyword to be read.
        This command will read hardware to obtain the keyword value.
        """

        if not self.is_enabled:
            azcam.exceptions.warning(f"{self.description} is not enabled")
            return

        if keyword == "FILTER":
            for i in range(3):
                try:
                    fdict = self.vfilters.getfilters()
                    break
                except Exception:
                    azcam.log(f"Filter read error {i}...")
                    time.sleep(0.2)
            reply = f"upper: {fdict['upper']} lower: {fdict['lower']}"

        elif keyword == "EPOCH":
            reply = 2000.0  # test

        elif keyword == "RA":
            value = getattr(self.tserver, self.keywords[keyword])
            a = Angle(f"{value}d")
            reply = f"{int(a.hms.h):02}:{int(a.hms.m):02}:{a.hms.s:.02f}"

        elif keyword == "DEC":
            value = getattr(self.tserver, self.keywords[keyword])
            a = Angle(f"{value}d")
            reply = f"{int(a.dms.d):02}:{int(a.dms.m):02}:{a.dms.s:.01f}"

        elif keyword == "AIRMASS":
            value = getattr(self.tserver, self.keywords["ELEVAT"])
            secz = 1.0 / math.cos((90.0 - value) * math.pi / 180.0)
            reply = f"{secz:.02}"

        elif keyword == "HA":
            lst = getattr(self.tserver, self.keywords["LST-OBS"])
            ra = getattr(self.tserver, self.keywords["RA"])
            ha = lst - ra
            a = Angle(f"{ha}d")
            reply = f"{int(a.hms.h):02}:{int(a.hms.m):02}:{a.hms.s:.02f}"

        elif keyword == "LST-OBS":
            value = getattr(self.tserver, self.keywords[keyword])
            a = Angle(f"{value}d")
            reply = f"{int(a.hms.h):02}:{int(a.hms.m):02}:{a.hms.s:.02f}"

        elif keyword == "EQUINOX":
            reply = 2000.0  # test

        # elif keyword == "JULIAN":
        #    reply = ""

        elif keyword == "ELEVAT":
            value = getattr(self.tserver, self.keywords[keyword])
            reply = f"{value:.01}"

        elif keyword == "AZIMUTH":
            value = getattr(self.tserver, self.keywords[keyword])
            reply = f"{value:.01}"

        elif keyword == "ROTANGLE":
            value = getattr(self.rserver, self.keywords[keyword])
            reply = f"{value:.01}"

        elif keyword == "ST":
            value = getattr(self.tserver, self.keywords[keyword])
            a = Angle(f"{value}d")
            reply = f"{int(a.hms.h):02}:{int(a.hms.m):02}:{a.hms.s:.02f}"

        else:
            raise azcam.exceptions.AzcamError(f"Unknown telescope keyword: {keyword}")

        # store value in Header
        self.header.set_keyword(keyword, reply)

        reply, t = self.header.convert_type(reply, self.header.typestrings[keyword])

        return [reply, self.comments[keyword], t]


class VattAscomInterface(object):
    """
    Interface to ASCOM at VATT.
    """

    # Example:
    # http://10.0.3.25:7843/api/v1/telescope/0/declination?ClientID=1&ClientTransactionID=1234

    # the value of the keyword is the string used by ASCOM
    keywords = {
        "RA": "RightAscension",
        "DEC": "declination",
        "AIRMASS": None,
        "HA": None,
        "LST-OBS": "SiderealTime",
        "EQUINOX": None,
        "JULIAN": None,
        "ELEVAT": "Altitude",
        "AZIMUTH": "Azimuth",
        "ROTANGLE": "Position",
        "ST": "SiderealTime",
        "EPOCH": None,
        "MOTION": None,
        "FILTER": "FILTER",
    }

    comments = {
        "RA": "right ascension",
        "DEC": "declination",
        "AIRMASS": "airmass",
        "HA": "hour angle",
        "LST-OBS": "local siderial time",
        "EQUINOX": "equinox of RA and DEC",
        "JULIAN": "julian date",
        "ELEVAT": "elevation",
        "AZIMUTH": "azimuth",
        "MOTION": "telescope motion flag",
        "ROTANGLE": "IIS rotation angle",
        "ST": "local siderial time",
        "EPOCH": "equinox of RA and DEC",
        "MOTION": "motion flag",
        "FILTER": "Instrument filter",
    }
    typestrings = {
        "RA": "str",
        "DEC": "str",
        "AIRMASS": "float",
        "HA": "str",
        "LST-OBS": "str",
        "EQUINOX": "float",
        "JULIAN": "float",
        "ELEVAT": "float",
        "AZIMUTH": "float",
        "MOTION": "int",
        "BEAM": "int",
        "ROTANGLE": "float",
        "ST": "str",
        "EPOCH": "float",
        "FILTER": "str",
    }

    def __init__(self):
        """
        Initialize communication interface to telescope server.
        """

        self.host = "10.0.3.25"
        self.port = 7843
        self.client_id = 1  # Client ID
        self.client_transaction_id = 0

        self.tserver = AlpacaTelescope(f"{self.host}:{self.port}", 0, "http")

        # azcam.log(f"Connected to telescope: {self.tserver.Name}")
        # azcam.log(f"Description: {self.tserver.Description}")

        print(f"RA={self.tserver.RightAscension} DE={self.tserver.Declination}")

        return

    def command(self, command):
        """
        Sends a command to the telescope server and receives the reply.
        Opens and closes the socket each time.
        """

        # requests.packages.urllib3.disable_warnings()

        r = requests.get(command, verify=False)
        reply = r.json()["Value"]

        return reply

    def make_keyword_packet(self, keyword):
        """
        Internal Use Only.<br>
        Makes a telemetry packet for transmission to the telescope server.
        """

        # http://10.0.3.25:7843/api/v1/telescope/0/declination?ClientID=1&ClientTransactionID=1234

        self.client_transaction_id += 1

        p = [
            self.host,
            self.port,
            "api",
            "v1",
            "telescope",
            "0",
            self.keywords[keyword],
            self.client_id,
            self.client_transaction_id,
        ]
        packet = f"http://{p[0]}:{p[1]}/{p[2]}/{p[3]}/{p[4]}/{p[5]}/{p[6]}?ClientID={p[7]}&ClientTransactionID={p[8]}"

        return packet

    def parse_keyword(self, keyword, value):
        """
        Parses a telescope telemetry keyword value to proper type and formatting.
        Data returned may be of type string, integer, or float.
        """

        # parse RA and DEC specially
        if keyword == "RA":
            a = Angle(f"{value}d")
            reply = "%s:%s:%s" % (reply[0:2], reply[2:4], reply[4:])

        elif keyword == "DEC":
            a = Angle(f"{value}d")
            reply = f"{int(a.dms.d)}:{int(a.dms.m)}:{a.dms.s:.02f}"
        else:

            # convert type
            if self.typestrings[keyword] == "int":
                reply = int(reply)
            elif self.typestrings[keyword] == "float":
                reply = float(reply)

        return reply
