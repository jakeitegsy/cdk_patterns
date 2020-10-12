PROJECT=BigFan
MESSAGE="Press ENTER to"

function delimiter {
    echo "----------------------------------------------------------------------------------"
}

function continue_prompt {
    read -p "$MESSAGE continue"
}

function display_stack {
    delimiter
    read -p "$MESSAGE view available stacks"
    cdk ls
    delimiter
    read -p "$MESSAGE view CloudFormation Templates"
    cdk synth
    delimiter
    continue_prompt
}

function display_directory {
    delimiter
    pwd
    ls
    continue_prompt
}


clear
rm -rf $PROJECT
mkdir $PROJECT
cd $PROJECT
display_directory

cdk init app --language python

SETUP=$(cat <<-END
from setuptools import setup, find_packages
setup(name="$PROJECT", packages=find_packages())
END
)
printf "%s" "$SETUP" > setup.py

python3 -m venv .env
source .env/bin/activate
pip3 install -U pip
pip3 install -e .
pip3 install -r requirements.txt
CDK=aws_cdk
pip3 install $CDK.core $CDK.aws_apigateway $CDK.aws_lambda $CDK.aws_lambda_event_sources
pip3 install $CDK.aws_sns $CDK.aws_sqs
display_stack

##########################################################################################

mkdir lambdas
cd lambdas
display_directory

CREATED_STATUS=$(cat <<-END
def handler(event, context):
    print(f"request: {events}")
    
    for record in event["Records"]:
        print(f"received message {event['Records'][record]['body']}")
END
)
printf "%s" "$CREATED_STATUS" > created_status.py
display_directory

OTHER_STATUS=$(cat <<-END
def handler(event, context):
    print(f"request: {events}")
    
    for record in event["Records"]:
        print(f"received message {event['Records'][record]['body']}")
END
)
printf "%s" "$OTHER_STATUS" > other_status.py
display_directory

cd ..
##########################################################################################
display_directory
cd big_fan
display_directory
BIG_FAN_STACK=$(cat <<-END
from aws_cdk.core import Construct, Stack, Duration
from aws_cdk.aws_lambda import Code, Function, Runtime
from aws_cdk.aws_lambda_event_sources import SqsEventSource
from aws_cdk.aws_iam import Role, ServicePrincipal
from aws_cdk.aws_sns import Topic, SubscriptionFilter
from aws_cdk.aws_sns_subscriptions import SqsSubscription
from aws_cdk.aws_sqs import Queue
from aws_cdk.aws_apigateway import (
    RestApi, StageOptions, MethodLoggingLevel, JsonSchema, JsonSchemaType,
    JsonSchemaVersion, IntegrationOptions, IntegrationResponse, PassthroughBehavior,
    Integration, IntegrationType, MethodResponse

)

import json


class $PROJECT(Stack):

    def add_response_model(self, name=None, title=None, properties=dict()):
        return self.gateway.add_model(
            name,
            content_type="application/json",
            model_name=name,
            schema=JsonSchema(
                schema=JsonSchemaVersion.DRAFT4,
                title=title,
                type=JsonSchemaType.OBJECT,
                properties=properties
            )
        )

    def create_queue(self, name, duration=300):
        return Queue(
            self, name,
            visibility_timeout=Duration.seconds(duration),
            queue_name=name
        )

    def add_subscription(self, topic=None, queue=None, filter_policy=None):
        topic.add_subscription(
            SqsSubscription(
                queue,
                raw_message_delivery=True,
                filter_policy={"status": filter_policy}
            )
        )
    
    def create_lambda(self, name=None, handler=None):
        return Function(
            self, name,
            runtime=Runtime.PYTHON_3_8,
            handler=handler,
            code=Code.from_asset("lambdas"),
        )

    def create_method_response(self, status_code=None, model=None):
        return MethodResponse(
            status_code=status_code,
            response_parameters={
                "method.response.header.Content-Type": True,
                "method.response.header.Access-Control-Allow-Origin": True,
                "method.response.header.Access-Control-Allow-Credentials": True
            },
            response_models={
                "application/json": model
            }
        )

    def __init__(self, scope: Construct, id: str, **kwargs):
        super().__init__(scope, id, **kwargs)
        
        self.gateway = RestApi(
            self, "API",
            deploy_options=StageOptions(
                metrics_enabled=True,
                logging_level=MethodLoggingLevel.INFO,
                data_trace_enabled=True,
                stage_name="prod"
            )
        )

        gateway_role = Role(
            self, "GatewayRole",
            assumed_by=ServicePrincipal("apigateway.amazonaws.com")
        )

        self.topic = Topic(
            self, "Topic",
            display_name="Big Fan Topic"
        )
        
        created_status_subscriber = self.create_lambda(
            name="CreatedStatusLambda",
            handler="created_status.handler"
        )
        other_status_subscriber = self.create_lambda(
            name="AnyOtherStatusLambda",
            handler="other_status.handler"
        )

        created_status_queue = self.create_queue(
            "StatusCreatedSubscriberQueue"
        )
        other_status_queue = self.create_queue(
            "AnyOtherStatusCreatedSubscriberQueue"
        )

        created_status_subscriber.add_event_source(SqsEventSource(created_status_queue))
        other_status_subscriber.add_event_source(SqsEventSource(other_status_queue))

        status = "created"
        created_status_filter = SubscriptionFilter.string_filter(whitelist=[status])
        other_status_filter = SubscriptionFilter.string_filter(blacklist=[status])

        self.topic.grant_publish(gateway_role)
        self.add_subscription(
            topic=self.topic, queue=created_status_queue, 
            filter_policy=created_status_filter
        )
        self.add_subscription(
            topic=self.topic, queue=other_status_queue, 
            filter_policy=other_status_filter
        )

        response_model = self.add_response_model(
            name="ResponseModel",
            title="pollResponse",
            properties={
                "message": JsonSchema(type=JsonSchemaType.STRING)
            }
        )
        error_response_model = self.add_response_model(
            name="ErrorResponseModel",
            title="errorResponse",
            properties={
                "state": JsonSchema(type=JsonSchemaType.STRING),
                "message": JsonSchema(type=JsonSchemaType.STRING)
            }
        )

        request_template = (
            "Action=Publish&"
            "Target=$util.urlEncode('{topic.topic_arn}')&"
            "Message=$util.urlEncode($input.path('$.message'))&"
            "Version=2010-03-31&"
            "MessageAttributes.entry.1.Name=status&"
            "MessageAttributes.entry.1.Value.DataType=String&"
            "MessageAttributes.entry.1.Value.StringValue=$util.urlEncode($.input.path('$.status'))"
        )

        error_template = json.dumps(
            dict(
                state="error", 
                message="$util.escapeJavaScript($input.path('$.errorMessage'))"
            ),
            separators=(",", ":")
        )
        
        integration_options = IntegrationOptions(
            credentials_role=gateway_role,
            request_parameters={
                "integration.request.header.Content-Type": "'application/x-www-form-urlencoded'"
            },
            request_templates={
                "application/json": request_template
            },
            passthrough_behavior=PassthroughBehavior.NEVER,
            integration_responses=[
                IntegrationResponse(
                    status_code="200",
                    response_templates={
                        "application/json": json.dumps(
                            dict(message="message added to topic")
                        )
                    }
                ),
                IntegrationResponse(
                    selection_pattern="^\[Error\].*",
                    status_code="400",
                    response_templates={
                        "application/json": error_template
                    },
                    response_parameters={
                        "method.response.header.Content-Type": "'application/json'",
                        "method.response.header.Access-Control-Allow-Origin": "'*'",
                        "method.response.header.Access-Control-Allow-Credentials": "'true'"
                    }
                )
            ]
        )
        
        (self.gateway
             .root.add_resource("SendEvent")
             .add_method(
                "POST",
                Integration(
                    type=IntegrationType.AWS,
                    integration_http_method="POST",
                    uri="arn:aws:apigateway:us-west-2:sns:path//",
                    options=integration_options,
                ),
                method_responses=[
                    self.create_method_response(
                        status_code="200", model=response_model
                    ),
                    self.create_method_response(
                        status_code="400", model=error_response_model
                    ),
                ]
            )
        )
END
)
printf "%s" "$BIG_FAN_STACK" > big_fan_stack.py
cat big_fan_stack.py
display_directory
cd ..
##########################################################################################

display_directory
APP=$(cat <<-END
from aws_cdk.core import App
from big_fan.big_fan_stack import $PROJECT


app = App()
$PROJECT(app, "$PROJECT")
app.synth()
END
)
printf "%s" "$APP" > app.py
display_stack

##########################################################################################
