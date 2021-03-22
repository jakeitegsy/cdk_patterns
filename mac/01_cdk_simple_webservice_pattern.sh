DIRECTORY="simple_webservice"
rm -rf $DIRECTORY
mkdir $DIRECTORY
cd $DIRECTORY
cdk init app --language python
python3 -m venv .env
source .env/bin/activate

SETUP=$(cat <<-END
from setuptools import setup, find_packages
setup(name="SimpleWebService", packages=find_packages())
END
)
printf "%s" "$SETUP" > setup.py
pip3 install -e .
pip3 install -r requirements.txt
pip3 install aws_cdk.core aws_cdk.aws_lambda aws_cdk.aws_dynamodb aws_cdk.aws_apigatewayv2
pip3 install boto3
cdk synth
cdk bootstrap

rm -rf simple_webservice/simple_webservice_stack.py
WEBSERVICE=$(cat <<-END
from aws_cdk.core import Construct, Stack, CfnOutput, RemovalPolicy
from aws_cdk.aws_apigatewayv2 import HttpApi, LambdaProxyIntegration
from aws_cdk.aws_dynamodb import Table, Attribute, AttributeType
from aws_cdk.aws_lambda import Function, Code, Runtime


class SimpleWebService(Stack):

    def __init__(self, scope: Construct, id: str, **kwargs):
        super().__init__(scope, id, **kwargs)

        self.hits_table = Table(
            self, "Hits",
            removal_policy=RemovalPolicy.DESTROY,
            partition_key=Attribute(
                name="path",
                type=AttributeType.STRING,
            )
        )
			
        self.lambda_function = Function(
            self, "DynamoLambdaHandler",
            runtime=Runtime.PYTHON_3_7,
            handler="hitcounter.handler",
            code=Code.from_asset("lambdas"),
            environment={
                "HITS_TABLE_NAME": self.hits_table.table_name
            }
        )
			
        self.hits_table.grant_read_write_data(self.lambda_function)

        self.api = HttpApi(
            self, "Endpoint",
            default_integration=LambdaProxyIntegration(
                handler=self.lambda_function
            )
        )

        CfnOutput(self, "HTTP API URL", value=self.api.url)
END
)
printf "%s" "$WEBSERVICE" > simple_webservice/simple_webservice.py

mkdir lambdas
LAMBDA=$(cat <<-END
import boto3
import os
dynamodb = boto3.client("dynamodb")

def handler(event, context):
    dynamodb.update_item(
        TableName=os.environ["HITS_TABLE_NAME"],
        Key={"path": {"S": event["rawPath"]}},
        UpdateExpression="ADD hits :incr",
        ExpressionAttributeValues={":incr": {"N": "1"}},
    )
    print("inserted counter for ", event["rawPath"])
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "text/html"},
        "body": "You have connected with the Lambda"
    }
END
)
printf "%s" "$LAMBDA" > lambdas/hitcounter.py
 
APP=$(cat <<-END
#!/usr/bin/env python3

from aws_cdk.core import App
from simple_webservice.simple_webservice import SimpleWebService

app = App()
SimpleWebService(app, "SimpleWebService")
app.synth()
END
)
printf "%s" "$APP" > app.py

cdk synth
cdk ls
cdk deploy
