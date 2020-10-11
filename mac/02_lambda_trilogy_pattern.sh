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

DIRECTORY=LambdaTrilogy
rm -rf $DIRECTORY
mkdir $DIRECTORY
cd $DIRECTORY
display_directory

cdk init --language python

SETUP=$(cat <<-END
from setuptools import setup, find_packages
setup(name="$DIRECTORY", packages=find_packages())
END
)

printf "%s" "$SETUP" > setup.py

python3 -m venv .env
source .env/bin/activate
pip3 install --upgrade pip
pip3 install -e .
pip3 install -r requirements.txt
pip3 install aws_cdk.core aws_cdk.aws_lambda aws_cdk.aws_apigateway
display_stack

###########################################################################
mkdir lambdas
mkdir lambdas/single_purpose_lambda lambdas/fat_lambda lambdas/lambdalith

cd lambdas/single_purpose_lambda
display_directory
ADD=$(cat <<-END
def get_number(event, key):
    try: 
        number = event["queryStringParameters"][key]
    except KeyError:
        number = 0
    return number

def handler(event, context):
    first_number = get_number(event, "firstNum")
    second_number = get_number(event, "secondNum")
    result = float(first_number) + float(second_number)
    print(f"The result of {first_number} + {second_number} = {result}")
    return {"body": result, "statusCode": 200}
END
)
printf "%s" "$ADD" > add.py
display_directory

SUBTRACT=$(cat <<-END
def get_number(event, key):
    try: 
        number = event["queryStringParameters"][key]
    except KeyError:
        number = 0
    return number

def handler(event, context):
    first_number = get_number(event, "firstNum")
    second_number = get_number(event, "secondNum")
    result = float(first_number) - float(second_number)
    print(f"The result of {first_number} - {second_number} = {result}")
    return {"body": result, "statusCode": 200}
END
)
printf "%s" "$SUBTRACT" > subtract.py
display_directory

MULTIPLY=$(cat <<-END
def get_number(event, key):
    try: 
        number = event["queryStringParameters"][key]
    except KeyError:
        number = 0
    return number

def handler(event, context):
    first_number = get_number(event, "firstNum")
    second_number = get_number(event, "secondNum")
    result = float(first_number) * float(second_number)
    print(f"The result of {first_number} * {second_number} = {result}")
    return {"body": result, "statusCode": 200}
END
)
printf "%s" "$MULTIPLY" > multiply.py
display_directory

DIVIDE=$(cat <<-END
def get_number(event, key):
    try: 
        number = event["queryStringParameters"][key]
    except KeyError:
        number = 0
    return number

def handler(event, context):
    first_number = get_number(event, "firstNum")
    second_number = get_number(event, "secondNum")
    result = float(first_number) / float(second_number)
    print(f"The result of {first_number} / {second_number} = {result}")
    return {"body": result, "statusCode": 200}
END
)
printf "%s" "DIVIDE" > divide.py
display_directory
cd ../..
display_directory
###########################################################################

cd lambdas/fat_lambda
display_directory
FAT_LAMBDA=$(cat <<-END
def get_number(event, key):
    try: 
        number = event["queryStringParameters"][key]
    except KeyError:
        number = 0
    return number

def get_numbers(event):
    first_number = get_number(event, "firstNum")
    second_number = get_number(event, "secondNum")
    return first_number, second_number

def add(event, context):
    first_number, second_number = get_numbers(event)
    result = float(first_number) + float(second_number)
    print(f"The result of {first_number} + {second_number} = {result}")
    return {"body": result, "statusCode": 200}

def subtract(event, context):
    first_number, second_number = get_numbers(event)
    result = float(first_number) - float(second_number)
    print(f"The result of {first_number} - {second_number} = {result}")
    return {"body": result, "statusCode": 200}

def multiply(event, context):
    first_number, second_number = get_numbers(event)
    result = float(first_number) * float(second_number)
    print(f"The result of {first_number} * {second_number} = {result}")
    return {"body": result, "statusCode": 200}

def divide(event, context):
    first_number, second_number = get_numbers(event)
    result = float(first_number) / float(second_number)
    print(f"The result of {first_number} / {second_number} = {result}")
    return {"body": result, "statusCode": 200}
END
)
printf "%s" "$FAT_LAMBDA" > fat_lambda.py
display_directory
cd ../..
display_directory

cd lambdas/lambdalith
REQUIREMENTS=$(cat <<-END
aws-wsgi
Flask
END
)
printf "%s" "$REQUIREMENTS" > requirements.txt
pip3 install -r requirements.txt --target flask
cd flask
display_directory
LAMBDALITH=$(cat <<-END
import awsgi
from flask import (Flask, jsonify, request)

app = Flask(__name__)

def get_number(request, key):
    return request.args.get(key, default=0, type=float)

def get_numbers(request):
    first_number = get_number(request, "firstNum")
    second_number = get_number(request, "secondNum")
    return first_number, second_number

@app.route("/add")
def add():
    first_number, second_number = get_numbers(request)
    result = first_number + second_number
    print(f"The result of {first_number} + {second_number} = {result}")
    return jsonify(result=result)

@app.route("/subtract")
def subtract():
    first_number, second_number = get_numbers(request)
    result = first_number - second_number
    print(f"The result of {first_number} - {second_number} = {result}")
    return jsonify(result=result)

@app.route("/multiply")
def multiply():
    first_number, second_number = get_numbers(request)
    result = first_number * second_number
    print(f"The result of {first_number} * {second_number} = {result}")
    return jsonify(result=result)

@app.route("/divide")
def add():
    first_number, second_number = get_numbers(request)
    result = first_number / second_number
    print(f"The result of {first_number} / {second_number} = {result}")
    return jsonify(result=result)

def handler(event, context):
    return awsgi.response(app, event, context, base64_content_types={"image/png"})
END
)
printf "%s" "$LAMBDALITH" > lambdalith.py
display_directory
cd ../../..
display_directory

######################################################################################
cd lambda_trilogy
display_directory
rm -rf lambda_trilogy_stack.py

SINGLE_PURPOSE_LAMBDA_STACK=$(cat <<-END
from aws_cdk.core import Construct, Stack
from aws_cdk.aws_lambda import Function, Code, Runtime
from aws_cdk.aws_apigateway import LambdaRestApi, LambdaIntegration

class SinglePurposeLambda(Stack):
    
    def __init__(self, scope: Construct, id: str, **kwargs):
        super().__init__(scope, id, **kwargs)

        adder = Function(
            self, "AddingLambda",
            runtime=Runtime.PYTHON_3_8,
            handler="add.handler",
            code=Code.from_asset("lambdas/single_purpose_lambda")
        )

        subtracter = Function(
            self, "SubtractingLambda",
            runtime=Runtime.PYTHON_3_8,
            handler="subtract.handler",
            code=Code.from_asset("lambdas/single_purpose_lambda")
        )

        multiplier = Function(
            self, "MultiplyingLambda",
            runtime=Runtime.PYTHON_3_8,
            handler="multiply.handler",
            code=Code.from_asset("lambdas/single_purpose_lambda")
        )

        divider = Function(
            self, "DividingLambda",
            runtime=Runtime.PYTHON_3_8,
            handler="divide.handler",
            code=Code.from_asset("lambdas/single_purpose_lambda")
        )

        api = LambdaRestApi(
            self, "SinglePurposefunctionAPI",
            handler=adder,
            proxy=False,

        )
        for (operation, function) in (
            ("add", adder),
            ("subtract", subtracter),
            ("multiply", multiplier),
            ("divide", divider)
        ):
            api.root.resource_for_path(operation).add_method("GET", LambdaIntegration(function))
        
END
)
printf "%s" "$SINGLE_PURPOSE_LAMBDA_STACK" > single_purpose_lambda_stack.py
display_directory

#################################################################################

FAT_LAMBDA_STACK=$(cat <<-END
from aws_cdk.core import Construct, Stack
from aws_cdk.aws_lambda import Function, Code, Runtime
from aws_cdk.aws_apigateway import LambdaRestApi, LambdaIntegration

class FatLambda(Stack):
    
    def __init__(self, scope: Construct, id: str, **kwargs):
        super().__init__(scope, id, **kwargs)

        adder = Function(
            self, "AddingLambda",
            runtime=Runtime.PYTHON_3_8,
            handler="fat_lambda.add",
            code=Code.from_asset("lambdas/fat_lambda")
        )

        subtracter = Function(
            self, "SubtractingLambda",
            runtime=Runtime.PYTHON_3_8,
            handler="fat_lambda.subtract",
            code=Code.from_asset("lambdas/fat_lambda")
        )

        multiplier = Function(
            self, "MultiplyingLambda",
            runtime=Runtime.PYTHON_3_8,
            handler="fat_lambda.multiply",
            code=Code.from_asset("lambdas/fat_lambda")
        )

        divider = Function(
            self, "DividingLambda",
            runtime=Runtime.PYTHON_3_8,
            handler="fat_lambda.divide",
            code=Code.from_asset("lambdas/fat_lambda")
        )

        api = LambdaRestApi(
            self, "FatLambdaAPI",
            handler=adder,
            proxy=False
        )
        for (operation, function) in (
            ("add", adder),
            ("subtract", subtracter),
            ("multiply", multiplier),
            ("divide", divider)
        ):
            api.root.resource_for_path(operation).add_method("GET", LambdaIntegration(function))
END
)
printf "%s" "$FAT_LAMBDA_STACK" > fat_lambda_stack.py
display_directory

#################################################################################

LAMBDALITH_STACK=$(cat <<-END
from aws_cdk.core import Construct, Stack
from aws_cdk.aws_lambda import Function, Code, Runtime
from aws_cdk.aws_apigateway import LambdaRestApi, LambdaIntegration

class LambdaLith(Stack):
    
    def __init__(self, scope: Construct, id: str, **kwargs):
        super().__init__(scope, id, **kwargs)

        lambdalith = Function(
            self, "LambdaLithHandler",
            runtime=Runtime.PYTHON_3_8,
            handler="lambdalith.handler",
            code=Code.from_asset("lambdas/lambdalith/flask")
        )

        LambdaRestApi(
            self, "LambdaLithAPI", 
            handler=lambdalith
        )
END
)
printf "%s" "$LAMBDALITH_STACK" > lambdalith_stack.py
display_directory

#######################################################################################
cd ..
display_directory

APP=$(cat <<-END
#!/usr/bin/env python3

from aws_cdk.core import App
from lambda_trilogy.single_purpose_lambda_stack import SinglePurposeLambda
from lambda_trilogy.fat_lambda_stack import FatLambda
from lambda_trilogy.lambdalith_stack import LambdaLith

app = App()
SinglePurposeLambda(app, "SinglePurposeLambda")
FatLambda(app, "FatLambda")
LambdaLith(app, "LambdaLith")
app.synth()
END
)
printf "%s" "$APP" > app.py

display_stack
cdk synth SinglePurposeLambda
continue_prompt
cdk synth FatLambda
continue_prompt
cdk synth LambdaLith

cdk deploy SinglePurposeLambda
cdk deploy FatLambda
cdk deploy LambdaLith
