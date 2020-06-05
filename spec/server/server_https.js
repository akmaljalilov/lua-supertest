const fs = require('fs');
const express = require('express');
const https = require('https');
const app = express();

const server = https.createServer({
    key: fs.readFileSync('p_key.pem'),
    cert: fs.readFileSync('cert.pem')
}, app);

app.get('/', function (req, res) {
    res.send('Hello Lua');
});
server.listen(8000, function () {
    console.log('port 8000');
});
module.exports = server;
