"use strict";
const net = require('net');
const fs = require('fs');

const htdocs = '..';

const server = net.createServer((c) => {
    c.on('data', (data) => {
        let parsedData = data.toString('utf8').split(' ');
        let file = parsedData[1].length != 0 ? parsedData[1] : 'index.html';
        let fileData = fs.readFileSync(htdocs + file);
        let stats = fs.statSync(htdocs + file);

        c.write('\
HTTP/1.1 200 OK\
Date: ' + new Date().toUTCString() + '\
Server: Node.js\
Last-Modified: ' + new Date(stats.mtime).toUTCString() + '\
Accept-Ranges: bytes\
Content-Length: ' + stats.size + '\
Content-Type: text/html ' + fileData);

  console.log('\
HTTP/1.1 200 OK\
Date: ' + new Date().toUTCString() + '\
Server: Node.js\
Last-Modified: ' + new Date(stats.mtime).toUTCString() + '\
Accept-Ranges: bytes\
Content-Length: ' + stats.size + '\
Content-Type: text/html ' + fileData);

    });

    console.log()
});
server.listen(20007, () => {

});
