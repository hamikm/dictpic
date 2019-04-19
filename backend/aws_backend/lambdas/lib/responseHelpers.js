/**
 * Helper for returning responses from this lambda
 */
const buildResponse = (statusCode, body) => ({
  statusCode,
  headers: {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Credentials': true,
  },
  body: JSON.stringify(body),
});

const serverFailure = body => buildResponse(500, body);
const success = body => buildResponse(200, body);
const badRequest = body => buildResponse(400, body);

/**
 * Print error and return serverFailure status if callback is given
 */
const handleError = (errorMsg, callback) => {
  console.error(`--> ${errorMsg}`);  // eslint-disable-line no-console
  if (callback) {
    return callback(null, serverFailure({ error: errorMsg }));
  }
  return null;
};

exports.handleError = handleError;
exports.success = success;
exports.badRequest = badRequest;
exports.serverFailure = serverFailure;
