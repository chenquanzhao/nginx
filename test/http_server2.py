#!/usr/bin/env python

from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer
import time

PORT_NUMBER = 8081

class myHandler(BaseHTTPRequestHandler):

    def do_GET(self):
        #time.sleep(30)
        self.send_response(200)
        self.send_header('Content-type','text/html')
        self.end_headers()
        # Send the html message
        self.wfile.write("Hello Nginx2\n")
        return

try:
    server = HTTPServer(('127.0.0.1', PORT_NUMBER), myHandler)
    print 'Started httpserver on port ' , PORT_NUMBER
    server.serve_forever()
except KeyboardInterrupt:
    print 'received, shutting down the web server'
    server.socket.close()
