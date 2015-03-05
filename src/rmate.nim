# rmate-nim
# Copyright (C) 2015 by Harald Lapp <harald@octris.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#
# This script can be found at:
# https://github.com/aurora/rmate-nim
#

#
# Thanks very much to all users and contributors! All bug-reports,
# feature-requests, patches, etc. are greatly appreciated! :-)
#

import strutils
import os
import posix
import net
import streams
import parsecfg

# init
#
let VERSION = "0.0.1"
let VERSION_DATE = "2015-02-26"
let VERSION_STRING = "rmate-nim $# ($#)" % [VERSION, VERSION_DATE]

let app_name = "rmate"

var hostname = ""
var home = getHomeDir()

var host = "localhost"
var port = "52698"

var ssl_cert = ""
var ssl_verify = CVerifyNone

var filepath = ""
var selection = ""
var displayname = ""
var filetype = ""
var verbose = false
var nowait = true
var force = false

discard gethostname(hostname, 1024)

# load config file
#
proc loadConfig(rc_file: string) =
    if fileExists(rc_file):
        var input = newFileStream(rc_file, fmRead)
        var p: CfgParser

        if input != nil:
            open(p, input, rc_file)

            while true:
                var k = next(p)

                case k.kind
                    of cfgEof:
                        break
                    of cfgKeyValuePair:
                        case k.key
                            of "host":
                                host = k.value
                            of "port":
                                port = k.value
                            of "ssl_cert":
                                ssl_cert = k.value
                            of "ssl_verify":
                                if (k.value == "true" or k.value == "yes" or k.value == "1"):
                                    ssl_verify = CVerifyPeer
                                else:
                                    ssl_verify = CVerifyNone
                            else:
                                discard
                    else:
                        discard

            close(p)

let search_path = [
    "/etc/" & app_name,
    home & "/." & app_name & "/" & app_name & ".rc",
    home & "/." & app_name & ".rc"
]

for i in search_path:
    loadConfig(i)

# process command-line parameters
#
proc getargs(): iterator(): string =
    return iterator(): string =
        let args = commandLineParams()

        for arg in args:
            yield arg

        yield ""

proc showUsage() =
    echo("""usage: rmate [arguments] file-path  edit specified file
   or: rmate [arguments] -          read text from stdin

    -H, --host HOST  Connect to HOST. Use 'auto' to detect the host from
                     SSH. Defaults to $#.
    -p, --port PORT  Port number to use for connection. Defaults to $#.
        --cert FILE  Client certificate file (pem format) for SSL connection.
        --verify     Verify peer for SSL connection.
    -w, --[no-]wait  Wait for file to be closed by TextMate.
    -l, --line LINE  Place caret on line number after loading file.
    -m, --name NAME  The display name shown in TextMate.
    -t, --type TYPE  Treat file as having specified type.
    -f, --force      Open even if file is not writable.
    -v, --verbose    Verbose logging messages.
    -h, --help       Display this usage information.
        --version    Show version and exit.
    """ % [host, port])

proc log(msg: string) =
    if verbose:
        stderr.writeln(msg)

let arguments = getargs()
var arg = arguments()

while true:
    if finished(arguments) or not arg.startsWith("-"):
        break

    case arg
        of "-":
            break
        of "--host", "-H":
            host = arguments()
        of "--port", "-p":
            port = arguments()
        of "--cert":
            ssl_cert = arguments()
        of "--verify":
            ssl_verify = CVerifyPeer
        of "--wait", "-w":
            nowait = false
        of "--no-wait":
            nowait = true
        of "--line", "-l":
            selection = arguments()
        of "--name", "-m":
            displayname = arguments()
        of "--type", "-t":
            filetype = arguments()
        of "--force", "-f":
            force = true
        of "--verbose", "-v":
            verbose = true
        of "--help", "-h":
            showUsage()
            quit(QuitSuccess)
        of "-?":
            showUsage()
            quit(QuitFailure)
        of "--version":
            echo(VERSION_STRING)
            quit(QuitSuccess)
        else:
            discard

    arg = arguments()

if not finished(arguments):
    filepath=arg

    arg = arguments()

    if not finished(arguments) and arg != "":
        echo("There are more than one files specified. Opening only $# and ignoring other." % [filepath])

if filepath == "":
    showUsage()
    quit(QuitFailure)

if filepath != "-":
    if fileExists(filepath) and fpUserWrite notin getFilePermissions(filepath):
        if not force:
            echo("File $# is not writable! Use -f to open anyway." % [filepath])
            quit(QuitFailure)
        else:
            log("File $# is not writable! Opening anyway." % [filepath])

    if displayname == "":
        displayname = hostname & ":" & filepath
else:
    displayname = "$#:untitled" % [hostname]

if ssl_cert != "":
    if not fileExists(ssl_cert):
        echo("SSL client ceritificate file $# not found" % [ssl_cert])
        quit(QuitFailure)

    displayname = "[SSL] " & displayname

# main
#
proc handleConnection(socket: Socket) =
    var inp = "".TaintedString
    var cmd = ""
    var token = ""
    var tmp = ""

    while true:
        socket.readLine(inp)
        inp = strip(inp)

        if inp == "":
            break

        cmd = inp
        token = ""
        tmp = ""

        while true:
            socket.readLine(inp)
            inp = strip(inp)

            if inp == "":
                break

            let pos = inp.find(":")

            case inp[0..pos-1]
                of "token":
                    token = inp[pos+2..inp.len-1]
                of "data":
                    let size = parseInt(inp[pos+2..inp.len-1])
                    var buffer = ""

                    discard socket.recv(buffer, size)

                    tmp = tmp & buffer
                else:
                    discard

        case cmd
            of "close":
                log("Closing $#" % [token])
            of "save":
                log("Saving $#" % [token])

                if token != "-":
                    writeFile(token, tmp)
            else:
                discard


var inp = "".TaintedString
var socket = newSocket()

if ssl_cert != "":
    let context = newContext(verifyMode = ssl_verify, certFile = ssl_cert, keyFile = ssl_cert)
    wrapSocket(context, socket)

try:
    socket.connect(host, Port(parseInt(port)))
except:
    echo("Unable to connect to TextMate on $#:$#" % [host, port])
    quit(QuitFailure)

socket.readLine(inp)

log(inp.string)

if not inp.startsWith("220 "):
    echo("Unable to connect to TextMate on $#:$#" % [host, port])
    quit(QuitFailure)

log("Connected to TextMate on $#:$# $#using SSL" % [host, port, if ssl_cert != "": "" else: "not "])

socket.send("open\n")
socket.send("display-name: $#\n" % [displayname])
socket.send("real-path: $#\n" % [filepath])
socket.send("data-on-save: yes\n")
socket.send("re-activate: yes\n")
socket.send("token: $#\n" % [filepath])

if selection != "":
    socket.send("selection: $#\n" % [selection])

if filetype != "":
    socket.send("file-type: $#\n" % [filetype])

if filepath != "-" and fileExists(filepath):
    socket.send("data: $#\n" % [$getFileSize(filepath)])
    socket.send(readFile(filepath))
elif filepath == "-":
    if isatty(0) == 1:
        echo("Reading from stdin, press ^D to stop")
    else:
        log("Reading from stdin")

    let data = readAll(stdin)

    socket.send("data: $#\n" % [$len(data)])
    socket.send(data)
else:
    socket.send("data: 0\n")

socket.send("\n.\n")

if nowait:
    let pid = fork()

    if pid == 0:
        handleConnection(socket)
        socket.close()
else:
    handleConnection(socket)
    socket.close()
