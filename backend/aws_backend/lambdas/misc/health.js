const resp = require('../lib/responseHelpers');

exports.main = async (event, context, callback) => {
    const body = JSON.parse(event.body);
    const val = body.value;

    return callback(null, resp.success({
        'value': `<p>value=${val}</p>`,
        'ok': true,
    }));
};
