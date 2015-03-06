# RMATE

## NAME

rmate -- remote editing utility for TextMate and compatible editors

## SYNOPSIS

    rmate [options] file-path
    rmate [options] -

## DESCRIPTION

The following options are available:

    -H, --host HOST  Connect to HOST. Use 'auto' to detect the host from SSH.
    -p, --port PORT  Port number to use for connection.
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

