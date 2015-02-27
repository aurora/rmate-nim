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

# init
#
let VERSION = "0.0.1"
let VERSION_DATE = "2015-02-26"
let VERSION_STRING = "rmate-nim $# ($#)" % [VERSION, VERSION_DATE]

var hostname = ""

var host = "localhost"
var port = "52698"

var filepath = ""
var selection = ""
var displayname = ""
var filetype = ""
var verbose = false
var nowait = true
var force = false

discard gethostname(hostname, 1024)

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

# main
#

