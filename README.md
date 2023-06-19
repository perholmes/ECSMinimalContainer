# ECS Minimal Container

It's difficult to launch a AWS CloudFormation template that creates an AWS Elastic Container Service cluster as well as a build pipeline at the same time. The cluster can only be launched if there are already containers present that will respond to health checks, or the CloudFormation template will hang. Yet, such containers will only be built later by the build pipeline.

**ECS Minimal Container** is a barebones HTTP container that responds to health checks, which can be uploaded ahead of time to an Elastic Container Registry, and referenced in TaskDefinitions in the CloudFormation template. This will allow the CloudFormation to launch. Actual images will be deployed once the build system runs.

## Workflow

* You provide a list of container names as a comma-separate list, e.g. "my-service-staging, my-service-production".
* A repository named after each container is created in ECR.
* A minimal image is built and pushed for **each container**.
* The result is a bunch of ECR repositories pre-populated with a first image that's enough of a health check responder that you can boot your CloudFormation template and ECS cluster.
* You can reference this dummy container in Task Definitions, using my-service-production:latest.
* Once your build system runs, your properly built images will simply become the new :latest

## Caveats

* This workflow means that CloudFormation is not in charge of creating or destroying your ECR registries. They're created ahead of time in this script so that the dummy image is available for the first run of your CloudFormation. And you're responsible for removing ECR registries.
* This script creates ECR registries with a lifecycle policy of keeping the latest 5 images and using KMS-encryption using account keys. If you want different settings, they must be configured here in this script and not in CloudFormation. CloudFormation does not own these registries.

## How To Use

After completing the prerequisites below, edit `build.sh` to populate the following values (examples provided), so that they don't have to be provided over and over:

export ECR_REGION=eu-west-1
export ECR_ROOT=01234567890.dkr.ecr.eu-west-1.amazonaws.com
export AWS_ACCESS_KEY_ID=AKIAT010101010101BD2

Then run `./build.sh`. You will be prompted for:

* A comma-separated list of containers you want to prep ECR registries for.
* An AWS Secret Key.

The script builds the included Dockerfile, which is simply an Apache server with a couple of static HTML files for healthchecks.

The container will now respond to health checks on `/index.html` and `/healthcheck.html`. Modify the files in public_html if you need different health checks.

## Prerequisites

* Install Docker Desktop.
* Install AWS CLI.
* Create an IAM user with the following inline policy. Save the Access Key and Secret for entry into the Bash script:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:*"
            ],
            "Resource": "*"
        }
    ]
}
```

## How to reference ECS Minimal Container in TaskDefinitions

The minimal container is simply a first image that already exists in an ECR when your CloudFormation runs for the first time, allowing it to put. Otherwise, CloudFormation will hang and fail.

Under a TaskDefinition -> ContainerDefinition, simply reference the minimal container image. WHen proper images are built, they just become the new :latest.

`Image: 01234567890.dkr.ecr.eu-west-1.amazonaws.com/my-service-production:latest`

Additionally, the usual AWS advice about doing container health check by running a curl call on the container won't work with the pure Apache container. Instead, simply echo a neutral status as the container health check:

```
HealthCheck:
  Command: [ "CMD-SHELL", "exit 0" ]
  Interval: 6
  Retries: 5
  StartPeriod: 5
  Timeout: 5
```

**Importantly**, you should configure the TaskDefinition with the memory and CPU capacities that you need for the real task, not just for the minimal image. Once you deploy the correct image after the build pipeline has run, only the image will change. 
