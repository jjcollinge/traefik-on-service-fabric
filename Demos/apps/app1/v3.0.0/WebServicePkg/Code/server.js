var http = require('http');

const PORT = process.env.NODE_PORT || 3000;
const RESPONSE = process.env.RES_STRING || "Hello World"

var server = http.createServer(function (req, res) {
    var body = RESPONSE;
    var content_length = body.length;
    res.writeHead(200, {
        'Content-Length': content_length,
        'Content-Type': 'text/plain' });
    res.end(body);
});
server.listen(PORT);
console.log('Server is running on port ' + PORT);