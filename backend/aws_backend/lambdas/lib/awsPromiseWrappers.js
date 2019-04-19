const invokeLambda = (lambda, funcName, body) => {
    return new Promise((resolve, reject) => {
        lambda.invoke({
            FunctionName: funcName,
            Payload: JSON.stringify({ body: JSON.stringify(body) }),
            InvocationType: 'RequestResponse',
        }, (err, data) => {
            if (err) {
                reject(err);
            } else {
                const payload = data.Payload && JSON.parse(data.Payload);
                if (payload && payload.body) {
                    resolve(payload.body);
                } else {
                    const errorMsg =
                        `Lambda call failed. Status code ${data.StatusCode}`;
                    reject(new Error(errorMsg));
                }
            }
        });
    });
};
  
const invokeDynamoDBGet = (dynamodb, params) => {
    return new Promise((resolve, reject) => {
        dynamodb.get(params, (err, data) => {
            if (err) {
                return reject(err);
            } else {
                return resolve(data.Item);
            }
        });
    });
};

const invokeDynamoDBPut = (dynamodb, row) => {
    return new Promise((resolve, reject) => {
        dynamodb.put(row, (err) => {
            if (err) {
                reject(err);
            } else {
                resolve();
            }
        });
    });
};

exports.invokeLambda = invokeLambda;
exports.invokeDynamoDBGet = invokeDynamoDBGet;
exports.invokeDynamoDBPut = invokeDynamoDBPut;
