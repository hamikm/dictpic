#!/bin/bash

STAGE=$1
STACK_NAME="tapdef-backend"

python scripts/serverless_utils.py $STACK_NAME $STAGE AwsApiGatewayInvokeUrl LogLevel AwsRegion