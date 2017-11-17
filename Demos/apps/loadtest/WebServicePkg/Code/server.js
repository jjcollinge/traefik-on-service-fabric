var http = require('http');

const PORT = process.env.NODE_PORT || 3000;
const RESPONSE = process.env.RES_STRING || "Hello World"

/**
 * Returns a random integer between min (inclusive) and max (inclusive)
 * Using Math.round() will give you a non-uniform distribution!
 */
function getRandomInt(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}


var server = http.createServer(function (req, res) {
    if (req.url.includes('large')) {
        var body = JSON.stringify(new Array(getRandomInt(1000,2000000)));
    } else {
        var body = RESPONSE;
    }
    var content_length = body.length;
    res.writeHead(200, {
        'Content-Length': content_length,
        'Content-Type': 'text/plain' });
    res.end(body);
});
server.listen(PORT);
console.log('Server is running on port ' + PORT);


