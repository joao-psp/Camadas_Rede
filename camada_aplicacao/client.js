"use strict";
if(!process.argv[2]) {
    return console.log('Uso: node client.js <endereço>');
}

var args = process.argv[2];
var server = args.split('/')[0];
var file = args.split('/')[1];

const net = require('net');

const client = net.createConnection({ port: 20001, host: server }, () => {

    client.write('\
GET /' + file + ' HTTP/1.1\
User-Agent: Mozilla/4.0 (compatible; MSIE5.01; Windows NT)\
Host: ' + server + ' \
Accept-Language: pt-br\
Accept-Encoding: gzip, deflate\
Connection: Keep-Alive');

});
client.on('data', (data) => {
    console.log(data.toString());
    client.end();
});
