############################################################################
##
##     This file is part of Purdue CS 422.
##
##     Purdue CS 422 is free software: you can redistribute it and/or modify
##     it under the terms of the GNU General Public License as published by
##     the Free Software Foundation, either version 3 of the License, or
##     (at your option) any later version.
##
##     Purdue CS 422 is distributed in the hope that it will be useful,
##     but WITHOUT ANY WARRANTY; without even the implied warranty of
##     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##     GNU General Public License for more details.
##
##     You should have received a copy of the GNU General Public License
##     along with Purdue CS 422. If not, see <https://www.gnu.org/licenses/>.
##
#############################################################################

# server-python.py
# Name:
# PUID:

import sys
import socket

RECV_BUFFER_SIZE = 2048
QUEUE_LENGTH = 10
sock = None

def server(server_port):
    """TODO: Listen on socket and print received message to sys.stdout"""
    for res in socket.getaddrinfo(None, server_port, socket.AF_UNSPEC, socket.SOCK_STREAM, 0, socket.AI_PASSIVE):
        family, socktype, protocol, canonicalname, sockaddr = res

        try:
            sock = socket.socket(family, socktype, protocol)
        except socket.error as msg:
            sock = None
            continue
        try:
            sock.bind(sockaddr)
            sock.listen(QUEUE_LENGTH)
        except socket.error as msg:
            sock.close()
            sock = None
            continue
        break
    
    if sock is None:
        print('server-python: bind')
        sys.exit(1)
    
    while 1:
        conn, addr = sock.accept()

        while 1:
            msg = conn.recv(RECV_BUFFER_SIZE)
            # EOF 
            if not msg:
                break
            sys.stdout.write(msg)
            # flush 
            sys.stdout.flush()

        conn.close()


def main():
    """Parse command-line argument and call server function """
    if len(sys.argv) != 2:
        sys.exit("Usage: python server-python.py (Server Port)")
    server_port = int(sys.argv[1])
    server(server_port)

if __name__ == "__main__":
    main()
