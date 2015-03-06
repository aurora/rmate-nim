# rmate

**EXPERIMENTAL**

This is a port of my [rmate shell script](https://github.com/aurora/rmate) to [Nim](http://nim-lang.org/).
Current state is: seems working, but be careful: i am just learning Nim :)

## Description

TextMate 2 adds a nice feature, where it is possible to edit files on a remote server
using a helper script. The tool needs to be copied to the server, you want to remote
edit files, on. After that, open your TM2 preferences and enable "Allow rmate connections"
setting in the "Terminal" settings and adjust the setting "Access for" according to your
needs:

### Local client connection

It's a good idea to allow access only for local clients. In this case you need to open
a SSH connection to the system you want to edit a file on and specify a remote tunnel in
addition:

	ssh -R 52698:localhost:52698 user@example.com

If you are logged in on the remote system, you can now just execute

	rmate test.txt

Please have a look at the sections "Remote client connection" or "SSL secured client
connection" if ssh is not available or in environments where remote port forwarding
could result in conflicts for example with concurrent users.

### Remote client connection

On some machines, where port forwarding is not possible, you can allow access for
"remote clients". Just ssh or telnet to the remote machine and execute:

    rmate -H textmate-host test.txt

To secure your TextMate, rmate supports SSL secured connections and client certificate
authentication. See the section "SSL secured client connection" below for details.

### SSL secured client connection

This version of rmate supports SSL secured connections and client certificate
authentication. For this to work it's recommended to configure TextMate to
allow connections from local clients only.

Next you must install a proxy supporting SSL -> non-SSL connections like stunnel
or haproxy on your Mac. Details regarding this would be to much for this documentation.
For haproxy there is an example configuration [available](https://github.com/aurora/rmate-nim/blob/master/share/haproxy.dist.conf).

Have a look at [this](http://blog.nategood.com/client-side-certificate-authentication-in-ngi)
excellent tutorial for details on how to create self-signed SSL server certificates and
certificates for client side certificate authentication.

Create a PEM file of the client certificate by merging the client certificate and the
client certificate key file, for example:

     cat ca.crt ca.key > ca.pem

Copy the resulting client certificate file over to the machine you have installed rmate
on and you want to edit files from.

To enable SSL encrypted connections, the `--ssl` flag needs to be specified as argument
for the rmate command. Additionally the `--cert ...` flag needs to be specified if
client side certificate authentication must be used. To verify the SSL server certificate
on rmate side, you can additional specify the `--verify` flag. This flag should be ommited
when using self-signed certificates.

Optionally the flags can be configured in the rmate configuration file, similar to host
and port settings:

    ssl=yes
    ssl_cert=file
    ssl_verify=yes

Note that the `ssl_verify` setting should be omitted when using self-signed certificates.

### Example

Example session: Editing html file located on an SGI o2: <https://github.com/aurora/rmate/wiki/Screens>

## Requirements

A bash with compiled support for "/dev/tcp" is required. This is not the case on some
older linux distributions, like Ubuntu 9.x.

## Usage

Edit specified file

    $ ./rmate [arguments] file-path

Read text from stdin

    $ echo "hello TextMate" | ./rmate [arguments] -

### Arguments

    -H, --host HOST  Connect to HOST. Use 'auto' to detect the host from
                     SSH. Defaults to $#.
    -p, --port PORT  Port number to use for connection. Defaults to $#.
        --ssl        Use SSL encrypted connection.
        --cert FILE  Certificate file (PEM format) for client side certificate
                     authentication.
        --verify     Verify peer for SSL connection.
    -w, --[no-]wait  Wait for file to be closed by TextMate.
    -l, --line LINE  Place caret on line number after loading file.
    -m, --name NAME  The display name shown in TextMate.
    -t, --type TYPE  Treat file as having specified type.
    -f, --force      Open even if file is not writable.
    -v, --verbose    Verbose logging messages.
    -h, --help       Display this usage information.
        --version    Show version and exit.

### Default parameter configuration

Some default parameters (_host_ and _port_) can be configured by defining them
as the environment variables `RMATE_HOST` and `RMATE_PORT` or by putting them
in a configuration file. The configuration files loaded are `/etc/rmate.rc`
and `~/.rmate.rc`, e.g.:

    host: auto  # prefer host from SSH_CONNECTION over localhost
    port: 52698

Alternative notation for configuration file is:

    host=auto
    port=52698

The precedence for setting the configuration is (higher precedence counts):

1. default (localhost, 52698)
2. /etc/rmate.rc
3. ~/.rmate/rmate.rc
4. ~/.rmate.rc
5. environment variables (RMATE\_HOST, RMATE\_PORT)

## Disclaimer

Use with caution. This software may contain serious bugs. I can not be made responsible for
any damage the software may cause to your system or files.

## License

rmate

Copyright (C) 2015 by Harald Lapp <harald@octris.org>

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
