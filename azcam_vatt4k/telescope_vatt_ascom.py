"""
Contains the StewardAscom class which defines the Telescope Control System interface
for VATT. This version uses ASCOM/alpaca.
"""

import time
import math

from alpaca.telescope import Telescope as AlpacaTelescope
from alpaca.rotator import Rotator as AlpacaRotator

from astropy.coordinates import Angle, SkyCoord
from astropy import units as u

import azcam
import azcam.utils
import azcam.exceptions
from azcam.tools.telescope import Telescope

from .vatt_filter_code import vatt_filters


class VattAscom(Telescope):
    """
    The interface to the VATT ASCOM telescope server.
    """

    def __init__(self, tool_id="telescope", description="VATT telescope"):
        super().__init__(tool_id, description)

        self.fits_keywords = {
            "RA": ["RightAscension", "right ascension", "str"],
            "DEC": ["Declination", "declination", "str"],
            "AIRMASS": [None, "airmass", "float"],
            "HA": [None, "hour angle", "str"],
            "LST-OBS": ["SiderealTime", "local siderial time", "str"],
            "EQUINOX": [None, "equinox of RA and DEC", "float"],
            "JULIAN": ["julianday", "julian date", "float"],
            "ELEVAT": ["Altitude", "elevation", "float"],
            "AZIMUTH": ["Azimuth", "azimuth", "float"],
            "ROTANGLE": ["Position", "rotation angle", "float"],
            "EPOCH": [None, "equinox of RA and DEC", "float"],
            "MOTION": ["Slewing", "motion flag", "int"],
            "FILTER": ["FILTER", "instrument filter", "str"],
        }
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
        for key in self.fits_keywords:
            fits_list = self.fits_keywords[key]
            self.set_keyword(key, None, fits_list[1], fits_list[2])

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

        try:

            if keyword == "FILTER":
                fdict = {}
                for i in range(3):
                    try:
                        fdict = self.vfilters.getfilters()
                        break
                    except Exception:
                        azcam.log(f"Filter read error {i}...")
                        time.sleep(0.2)
                        fdict["upper"] = "unknown"
                        fdict["lower"] = "unknown"
                reply = f"upper: {fdict['upper']} lower: {fdict['lower']}"

            elif keyword == "EPOCH":
                reply = 2000.0  # test

            elif keyword == "RA":
                value = getattr(self.tserver, self.fits_keywords[keyword][0])
                # a = Angle(f"{value}d")
                coord = SkyCoord(value * u.deg, 0 * u.deg)
                h = int(coord.hms[0])
                m = int(coord.hms[1])
                s = float(coord.hms[3])
                reply = f"{h.hms.h:02}:{a.hms.m:02}:{a.hms.s:.02f}"

            elif keyword == "DEC":
                value = getattr(self.tserver, self.fits_keywords[keyword][0])
                a = Angle(f"{value}d")
                d = int(a.dms.d)
                m = abs(int(a.dms.m))
                s = abs(int(a.dms.s))
                reply = f"{d:02}:{m:02}:{s:.01f}"

            elif keyword == "AIRMASS":
                value = getattr(self.tserver, "Altitude")
                secz = 1.0 / math.cos((90.0 - value) * math.pi / 180.0)
                reply = f"{secz:.02}"

            elif keyword == "HA":
                lst = getattr(self.tserver, self.fits_keywords["LST-OBS"][0])
                ra = getattr(self.tserver, self.fits_keywords["RA"][0])
                ha = lst - ra
                a = Angle(f"{ha}d")
                reply = f"{int(a.hms.h):02}:{int(a.hms.m):02}:{a.hms.s:.02f}"

            elif keyword == "LST-OBS":
                value = getattr(self.tserver, self.fits_keywords[keyword][0])
                a = Angle(f"{value}d")
                reply = f"{int(a.hms.h):02}:{int(a.hms.m):02}:{a.hms.s:.02f}"

            elif keyword == "EQUINOX":
                reply = 2000.0  # test

            elif keyword == "JULIAN":
                try:
                    value = self.tserver.Action("julianday", [])
                except Exception:
                    value = ""
                reply = value

            elif keyword == "ELEVAT":
                value = getattr(self.tserver, self.fits_keywords[keyword][0])
                reply = f"{value:.03}"

            elif keyword == "MOTION":
                value = getattr(self.tserver, self.fits_keywords[keyword][0])
                reply = 1 if value else 0

            elif keyword == "AZIMUTH":
                value = getattr(self.tserver, self.fits_keywords[keyword][0])
                reply = f"{value:.04}"

            elif keyword == "ROTANGLE":
                value = getattr(self.rserver, self.fits_keywords[keyword][0])
                reply = f"{value:.04}"

            elif keyword == "ST":
                value = getattr(self.tserver, self.fits_keywords[keyword][0])
                a = Angle(f"{value}d")
                reply = f"{int(a.hms.h):02}:{int(a.hms.m):02}:{a.hms.s:.02f}"

            else:
                if keyword in self.fits_keywords:
                    self.header.set_keyword(
                        keyword, "unsupported", self.fits_keywords[keyword][1], "str"
                    )
                    return ["unsupported", self.fits_keywords[keyword][1], "str"]

                else:
                    raise azcam.exceptions.AzcamError(
                        f"Unknown telescope keyword: {keyword}"
                    )

            # store value in Header
            self.header.set_keyword(keyword, reply)

            reply, t = self.header.convert_type(reply, self.fits_keywords[keyword][2])

        except Exception as e:
            azcam.log(f"header error for keyword {keyword}: {e}")
            reply = ""
            t = "str"

        return [reply, self.fits_keywords[keyword][1], t]
