const https = require('https');
const jwt = require('jsonwebtoken');
const uuidv4 = require('uuid/v4');

const exists = obj => obj !== null && obj !== undefined;

// Set the two Device Check bits for this device.
// Params:
//   bit0 (boolean) - true if never seen given iCloud user ID
//   bit1 (boolean) - TODO not used yet
//   cert (string) - Device Check certificate. Get from developer.apple.com)
//   keyId (string) - Part of metadata for Device Check certificate)
//   teamId (string) - My developer team ID. Can be found in iTunes Connect
//   dcToken (string) - Ephemeral Device Check token passed from frontend
//   deviceCheckHost (string) - API URL, which is either for dev or prod env
const updateTwoBits = async (
    bit0, bit1, cert, keyId, teamId, dcToken, deviceCheckHost) => {
        
    return new Promise((resolve, reject) => {
        var jwToken = jwt.sign({}, cert, {
            algorithm: 'ES256',
            keyid: keyId,
            issuer: teamId,
        });
    
        var postData = {
            'device_token' : dcToken,
            'transaction_id': uuidv4(),
            'timestamp': Date.now(),
            'bit0': bit0,
            'bit1': bit1,
        }
    
        var postOptions = {
            host: deviceCheckHost,
            port: '443',
            path: '/v1/update_two_bits',
            method: 'POST',
            headers: {
                'Authorization': 'Bearer ' + jwToken,
            },
        };
      
        var postReq = https.request(postOptions, function(res) {
            res.setEncoding('utf8');
    
            var data = '';
            res.on('data', function (chunk) {
                data += chunk;
            });

            res.on('end', function() {
                resolve();
            });
    
            res.on('error', function(data) {
                const sc = res.statusCode;
                const err = new Error(
                    `DC update failed with status code ${sc}: ${data}`);
                reject(err);
            });
        });
    
        postReq.write(new Buffer.from(JSON.stringify(postData)));
        postReq.end();
    });
};

// Query the two Device Check bits for this device.
// Params:
//     cert (string) - Device Check certificate. Get from developer.apple.com)
//     keyId (string) - Part of metadata for Device Check certificate)
//     teamId (string) - My developer team ID. Can be found in iTunes Connect
//     dcToken (string) - Ephemeral Device Check token passed from frontend
//     deviceCheckHost (string) - API URL, which is either for dev or prod env
// Return:
//     { bit0 (boolean), bit1 (boolean), lastUpdated (String) }
const queryTwoBits = async (cert, keyId, teamId, dcToken, deviceCheckHost) => {

    return new Promise((resolve, reject) => {

        var jwToken = jwt.sign({}, cert, {
            algorithm: 'ES256',
            keyid: keyId,
            issuer: teamId,
        });

        var postData = {
            'device_token' : dcToken,
            'transaction_id': uuidv4(),
            'timestamp': Date.now(),
        }

        var postOptions = {
            host: deviceCheckHost,
            port: '443',
            path: '/v1/query_two_bits',
            method: 'POST',
            headers: {
                'Authorization': 'Bearer ' + jwToken,
            },
        };
    
        var postReq = https.request(postOptions, function(res) {
            res.setEncoding('utf8');

            var data = '';
            res.on('data', function (chunk) {
                data += chunk;
            });

            res.on('end', function() {
                try {
                    var json = JSON.parse(data);
                    if (exists(json.bit0) && exists(json.bit1)) {
                        resolve({ bit0: json.bit0, bit1: json.bit1 });
                    } else {
                        const msg = `No bits in DC query response: ${json}`;
                        reject(new Errow(msg));
                    }
                } catch (error) {
                    // don't log caught error - it's just JSON parse error
                    const sc = res.statusCode;
                    const err = new Error(
                        `DC query failed with status code ${sc}: ${data}`);
                    reject(err);
                }
            });

            res.on('error', function(data) {
                const sc = res.statusCode;
                const err = new Error(
                    `DC query failed with status code ${sc}: ${data}`);
                reject(err);
            });
        });

        postReq.write(new Buffer.from(JSON.stringify(postData)));
        postReq.end();
    });
};

// Make sure device is valid.
// Params:
//   cert (string) - Device Check certificate. Get from developer.apple.com)
//   keyId (string) - Part of metadata for Device Check certificate)
//   teamId (string) - My developer team ID. Can be found in iTunes Connect
//   dcToken (string) - Ephemeral Device Check token passed from frontend
//   deviceCheckHost (string) - API URL, which is either for dev or prod env
const validateDevice = async (
    cert, keyId, teamId, dcToken, deviceCheckHost) => {
        
    return new Promise((resolve, reject) => {
        var jwToken = jwt.sign({}, cert, {
            algorithm: 'ES256',
            keyid: keyId,
            issuer: teamId,
        });
    
        var postData = {
            'device_token' : dcToken,
            'transaction_id': uuidv4(),
            'timestamp': Date.now(),
        }
    
        var postOptions = {
            host: deviceCheckHost,
            port: '443',
            path: '/v1/validate_device_token',
            method: 'POST',
            headers: {
                'Authorization': 'Bearer ' + jwToken,
            },
        };
      
        var postReq = https.request(postOptions, function(res) {
            res.setEncoding('utf8');
    
            var data = '';
            res.on('data', function (chunk) {
                data += chunk;
            });

            res.on('end', function() {
                if (res.statusCode === 200) {
                    resolve();
                } else {
                    const sc = res.statusCode;
                    const err = new Error(
                        `DC validation failed with status code ${sc}: ${data}`);
                    reject(err);
                }
            });
    
            res.on('error', function(data) {
                const sc = res.statusCode;
                const err = new Error(
                    `DC validation failed with status code ${sc}: ${data}`);
                reject(err);
            });
        });
    
        postReq.write(new Buffer.from(JSON.stringify(postData)));
        postReq.end();
    });
};

exports.updateTwoBits = updateTwoBits;
exports.queryTwoBits = queryTwoBits;
exports.validateDevice = validateDevice;
