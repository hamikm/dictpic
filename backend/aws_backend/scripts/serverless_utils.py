import boto3 as boto


def fail(msg):
    print msg
    sys.exit(1)


class AwsFetcher(object):
    def __init__(self, stack, stage, info_to_fetch):
        # INFO maps from key to a function that can fetch that key
        self.INFO = {
            'AwsApiGatewayInvokeUrl': self.fetch_api_gateway_invoke_url,
            'AwsRegion': self.fetch_region,
            'LogLevel': self.fetch_log_level,
        }

        self.stage = stage
        self.stack_name = stack + '-' + self.stage
        self.to_fetch = info_to_fetch  # array of things to fetch from stack
        self.stack = self.get_stack()

    def get_stack(self):
        client = boto.client('cloudformation')
        stack = client.describe_stacks(StackName=self.stack_name)['Stacks'][0]

        # If we haven't finished making the stack, fail
        if stack['StackStatus'] not in ('CREATE_COMPLETE', 'UPDATE_COMPLETE'):
            fail('The StackStatus of {} is not CREATE_COMPLETE or '
                 'UPDATE_COMPLETE'.format(self.stack_name))

        self.stack = stack
        self.outputs = {}  # OutputKey to output mapping
        for output in self.stack['Outputs']:
            self.outputs[output['OutputKey']] = output

        print '\nChecks succeeded\n'

    def fetch(self):
        '''fetch fetches the info in self.to_fetch'''
        store = {}
        for key in self.to_fetch:
            if key not in self.INFO:
                print 'WARNING: Unknown key {}'.format(key)
            store[key] = self.INFO[key]()

        return store

    def _get_output_value(self, key):
        return self.outputs[key]['OutputValue']

    def fetch_api_gateway_invoke_url(self):
        return self._get_output_value('ServiceEndpoint')

    def fetch_region(self):
        session = boto.session.Session()
        return session.region_name

    def fetch_log_level(self):
        return 'silent'


if __name__ == '__main__':
    import sys
    import json

    if len(sys.argv) < 4:
        msg = '''
        not enough arguments
        usage: python serverless_utils.py stack stage desired_info...
        ex:    python serverless_utils.py tapdef-backend dev AwsApiGatewayInvokeUrl...
        '''
        fail(msg)

    stack = sys.argv[1]
    stage = sys.argv[2]
    desired_info = sys.argv[3:]

    fetcher = AwsFetcher(stack, stage, desired_info)
    data = fetcher.fetch()

    #  this path is relative to the serverless directory
    outfile = 'backend_config.{}.json'.format(stage)
    print 'Writing info to {}'.format(outfile)
    with open(outfile, 'w') as f:
        f.writelines(json.dumps(
            data,
            indent=2,
            sort_keys=True,
        ))
