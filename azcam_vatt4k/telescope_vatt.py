# Contains the StewardTCS class which defines the Telescope Control System interface for VATT.

import os
import socket
import sys
import time

from .vatt_filter_code import vatt_filters

import azcam
import azcam.utils
import azcam.exceptions
from azcam.header import System
from azcam.tools.telescope import Telescope


class VattTCS(Telescope):
    """
    The interface to the Steward Observatory TCS telescope server.
    """

    def __init__(self, tool_id="telescope", description="VATT telescope"):
        super().__init__(tool_id, description)

        self.vfilters = vatt_filters()

        self.DEBUG = 0

    def initialize(self):
        """
        Initializes the telescope interface.
        """

        if self.is_initialized:
            return

        if not self.is_enabled:
            azcam.exceptions.warning(f"{self.description} is not enabled")
            return

        # telescope server interface
        self.Tserver = TelcomServerInterface()

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
        for key in self.Tserver.keywords:
            self.set_keyword(
                key, "", self.Tserver.comments[key], self.Tserver.typestrings[key]
            )

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

        else:
            try:
                command = self.Tserver.make_packet(
                    "REQUEST " + self.Tserver.keywords[keyword]
                )
            except KeyError:
                return ["ERROR", "Keyword %s not defined" % keyword]
            ReplyLength = self.Tserver.ReplyLengths[keyword]
            ReplyLength = ReplyLength + 3  # is this right?
            reply = self.Tserver.command(command, ReplyLength + self.Tserver.Offset)
            if reply[0] != "OK":
                self.header.set_keyword(keyword, "")
                return reply
            reply = self.Tserver.parse_reply(reply[1], ReplyLength)

        # parse RA and DEC specially
        if keyword == "RA":
            reply = "%s:%s:%s" % (reply[0:2], reply[2:4], reply[4:])
        elif keyword == "DEC":
            reply = "%s:%s:%s" % (reply[0:3], reply[3:5], reply[5:])
        else:
            pass

        # store value in Header
        self.header.set_keyword(keyword, reply)

        reply, t = self.header.convert_type(reply, self.header.typestrings[keyword])

        return [reply, self.Tserver.comments[keyword], t]

    # **************************************************************************************************
    # Focus
    # **************************************************************************************************

    def set_focus(self, FocusPosition, FocusID=0):
        """
        Move the telescope focus to the specified position.
        Currently just prompts user to move focus and enter new focus value.
        FocusPosition is the focus position to set.
        FocusID is the focus mechanism ID.
        """

        azcam.utils.prompt("Move to focus %s and press Enter..." % FocusPosition)

        self.FocusPosition = FocusPosition

        return

    def get_focus(self, FocusID=0):
        """
        Return the current telescope focus position.
        Current just prompts user for current focus value.
        FocusID is the focus mechanism ID.
        """

        focpos = azcam.utils.prompt("Enter current focus position:")

        try:
            self.FocusPosition = float(focpos)
        except:
            self.FocusPosition = focpos

        return [self.FocusPosition]

    # **************************************************************************************************
    # Move
    # **************************************************************************************************

    def offset(self, RA, Dec):
        """
        Offsets telescope in arcsecs.
        """

        if not self.is_enabled:
            return ["WARNING", "telescope not enabled"]

        command = self.Tserver.make_packet("RADECGUIDE %s %s" % (RA, Dec))

        replylen = 1024
        reply = self.Tserver.command(command, replylen)

        # wait for motion to stop
        reply = self.wait_for_move()

        return reply

    def move(self, RA, Dec, Epoch=2000.0):
        """
        Moves telescope to an absolute RA,DEC position.
        """

        if not self.is_enabled:
            return ["WARNING", "telescope not enabled"]

        if self.DEBUG == 1:
            return

        replylen = 1024

        command = "EPOCH %s" % Epoch
        command = self.Tserver.make_packet(command)
        reply = self.Tserver.command(command, replylen)
        command = "NEXTRA %s" % RA
        command = self.Tserver.make_packet(command)
        reply = self.Tserver.command(command, replylen)
        command = "NEXTDEC %s" % Dec
        command = self.Tserver.make_packet(command)
        reply = self.Tserver.command(command, replylen)

        command = "MOVNEXT"
        command = self.Tserver.make_packet(command)
        reply = self.Tserver.command(command, replylen)

        # wait for motion to START
        time.sleep(1.5)

        # wait for motion to stop
        reply = self.wait_for_move()

        return reply

    def move_start(self, RA, Dec, Epoch=2000.0):
        """
        Moves telescope to an absolute RA,DEC position without waiting for motion to stop.
        """

        azcam.log("move_start command received:%s %s" % (RA, Dec))

        if not self.is_enabled:
            azcam.exceptions.warning("telescope not enabled")
            return

        if self.DEBUG == 1:
            return

        replylen = 1024

        command = "EPOCH %s" % Epoch
        command = self.Tserver.make_packet(command)
        reply = self.Tserver.command(command, replylen)
        command = "NEXTRA %s" % RA
        command = self.Tserver.make_packet(command)
        reply = self.Tserver.command(command, replylen)
        command = "NEXTDEC %s" % Dec
        command = self.Tserver.make_packet(command)
        reply = self.Tserver.command(command, replylen)

        command = "MOVNEXT"
        command = self.Tserver.make_packet(command)
        reply = self.Tserver.command(command, replylen)

        return

    def wait_for_move(self):
        """
        Wait for telescope to stop moving.
        """

        if not self.is_enabled:
            azcam.exceptions.warning("telescope not enabled")
            return

        if self.DEBUG == 1:
            return

        # loop without timeout
        azcam.log("Checking for telescope motion...")
        cycle = 0
        while True:
            reply = self.get_keyword("MOTION")
            if azcam.utils.check_reply(reply):
                return reply
            try:
                motion = int(reply[1])
            except:
                azcam.exceptions.AzcamError("bad MOTION status keyword: %s" % reply[1])

            if not motion:
                azcam.log("Telescope reports it is STOPPED")
                azcam.log(
                    "Coords:", self.get_keyword("RA")[1], self.get_keyword("DEC")[1]
                )
                azcam.log(
                    "Coords:", self.get_keyword("RA")[1], self.get_keyword("DEC")[1]
                )
                azcam.log(
                    "Coords:", self.get_keyword("RA")[1], self.get_keyword("DEC")[1]
                )
                return
            else:
                azcam.log(
                    "Coords:", self.get_keyword("RA")[1], self.get_keyword("DEC")[1]
                )

            time.sleep(0.1)
            cycle += 1  # not used for now

        # stop the telescope
        azcam.log("Telescope motion TIMEOUT - sending CANCEL")
        command = "CANCEL"
        command = self.Tserver.make_packet(command)
        reply = self.Tserver.command(command, 1024)

        return


class TelcomServerInterface(object):
    Host = ""
    Port = 0
    Socket = 0

    TELID = ""  # Telescope ID
    SYSID = "TCS"  # Subsystem ID
    PID = "001"  # Packet ID

    # the value of the keyword is the string used by TCS
    keywords = {
        "RA": "RA",
        "DEC": "DEC",
        "AIRMASS": "SECZ",
        "HA": "HA",
        "LST-OBS": "ST",
        "EQUINOX": "EQ",
        "JULIAN": "JD",
        "ELEVAT": "EL",
        "AZIMUTH": "AZ",
        "ROTANGLE": "ROT",
        "ST": "ST",
        "EPOCH": "EQ",
        "MOTION": "MOTION",
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
    # ReplyLengths={'RA':9,'DEC':9,'AIRMASS':5,'HA':9,'LST-OBS':8,'EQUINOX':7,
    #      'JULIAN':10,'ELEVAT':5,'AZIMUTH':6,'MOTION':1,'ROTANGLE':5,'ST':8,'EPOCH':7}
    ReplyLengths = {
        "RA": 9,
        "DEC": 9,
        "AIRMASS": 5,
        "HA": 9,
        "LST-OBS": 8,
        "EQUINOX": 7,
        "JULIAN": 9,
        "ELEVAT": 5,
        "AZIMUTH": 6,
        "MOTION": 1,
        "ROTANGLE": 5,
        "ST": 8,
        "EPOCH": 7,
        "FILTER": -1,
    }
    Offsets = {
        "RA": 4,
        "DEC": 14,
        "AIRMASS": 57,
        "HA": 25,
        "LST-OBS": 35,
        "EQUINOX": 76,
        "JULIAN": 85,
        "ELEVAT": 44,
        "AZIMUTH": 50,
        "MOTION": 1,
        "ROTANGLE": 129,
        "ST": 35,
        "EPOCH": 76,
        "FILTER": -1,
    }

    def __init__(self):
        """
        Initialize communication interface to telescope server.
        """

        self.Host = "vatttel.vatt"
        self.Port = 5750
        self.TELID = "VATT"
        self.Offset = 10

        return

    def open(self, Host="", Port=-1):
        """
        Opens a connection (socket) to the telescope server.
        Creates the socket and connects.
        """
        if Host != "":
            self.Host = Host
        if Port != -1:
            self.Port = Port

        self.Socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.Socket.settimeout(5.0)
        try:
            self.Socket.connect((self.Host, self.Port))
            return ["OK"]
        except Exception as inst:
            return ["ERROR", '"could not open telescope server socket: %s"' % inst]

    def close(self):
        """
        Closes an open connection (socket) to a telescope server.
        """
        try:
            self.Socket.close()
        except:
            pass

    def command(self, command, ReplyLength):
        """
        Sends a command to the telescope server and receives the reply.
        Opens and closes the socket each time.
        """

        reply = self.open()
        if reply[0] == "OK":
            self.send(command)
            reply = self.recv(ReplyLength)
            self.close()
        else:
            pass

        return reply

    def send(self, command):
        """
        Sends a command to a socket telescope.
        Appends CRLF to command.
        """

        try:
            reply = self.Socket.send(
                str.encode(command + "\r\n")
            )  # send command with terminator
        except:
            pass

    def recv(self, Length):
        """
        Receives a reply from a socket telescope.
        """

        try:
            msg = self.Socket.recv(Length).decode()
            return ["OK", msg]
        except Exception as inst:
            msg = chunk = ""
            return ["ERROR", "telescope server read error: %s" % inst]

    def make_packet(self, command):
        """
        Internal Use Only.<br>
        Makes a telemetry packet for transmission to the telescope server.
        """

        # packetlist = [self.TELID,self.SYSID,self.PID,'REQUEST',command]
        packetlist = [self.TELID, self.SYSID, self.PID, command]
        packet = " ".join(packetlist)
        return packet

    def parse_keyword(self, keyword, telemetry):
        """
        Returns a telescope telemetry keyword value from the telemetry string.
        Data returned may be of type string, integer, or float.
        """

        ReplyLength = self.ReplyLengths[keyword]

        ReplyLength = ReplyLength + 3
        if keyword == "ROTANGLE":
            ReplyLength = ReplyLength - 2

        reply = telemetry[
            self.Offsets[keyword] - 1 : self.Offsets[keyword] + ReplyLength
        ]

        # parse RA and DEC specially
        if keyword == "RA":
            reply = "%s:%s:%s" % (reply[0:2], reply[2:4], reply[4:])
        elif keyword == "DEC":
            reply = "%s:%s:%s" % (reply[0:3], reply[3:5], reply[5:])
        else:
            pass

        # convert type
        try:
            if self.typestrings[keyword] == "int":
                reply = int(reply)
            elif self.typestrings[keyword] == "float":
                reply = float(reply)
        except Exception as message:
            azcam.log("ERROR reading telescope data (%s):" % keyword, message)
            return ["ERROR", message]

        return ["OK", reply]

    def parse_reply(self, reply, ReplyLength):
        """
        Internal Use Only.<br>
        """
        try:
            reply = reply.rstrip()
            replist = reply.split(" ")
            reply = self.parse_remove_null(replist)
            return reply[3]
        except:
            return ["ERROR", '"telescope parse error"']

    def parse_remove_null(self, List):
        """
        Internal Use Only.
        """

        while 1:
            try:
                List.remove("")
            except:
                break

        return List
