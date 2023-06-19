# ECS Minimal Container

It's difficult to launch a AWS CloudFormation template that creates an AWS Elastic Container Service cluster as well as a build pipeline at the same time. The cluster can only be launched if there are already containers present that will respond to health checks, or the CloudFormation template will hang. Yet, such containers will only be built later by the build pipeline.

**ECS Minimal Container** is a barebones HTTP container that responds to health checks, which can be uploaded ahead of time to an Elastic Container Registry, and referenced in TaskDefinitions in the CloudFormation template. This will allow the CloudFormation to launch. The simultaneously deployed build pipeline can then build the correct images and deploy as normal, replacing the ECS Minimal Containers.

## How To Use

After completing the prerequisites below, simply run `build.sh` from a Bash shell. You will be asked for:

* The region (e.g. eu-west-1).
* The root of an Elastic Container Registry (e.g. 01234567890.dkr.ecr.eu-west-1.amazonaws.com)
* An AWS Access Key ID.
* An AWS Secret Key.

The script builds the included Dockerfile, which is simply an Apache server with a couple of static HTML files for healthchecks. It then pushes it to your Elastic Container Registry, allowing you to reference it in TaskDefinitions in CloudFormation templates.

The container will now respond to health checks on `/index.html` and `/healthcheck.html`. Modify the files in public_html if you need different health checks.

## Prerequisites

* Install Docker Desktop.
* Install AWS CLI.
* Create an Elastic Container Registry called "ecs-minimal-container" in the same region as the CloudFormation template will run.
* Create an IAM user with the following inline policy. Save the Access Key and Secret for entry into the Bash script:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:CompleteLayerUpload",
                "ecr:GetAuthorizationToken",
                "ecr:UploadLayerPart",
                "ecr:InitiateLayerUpload",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage"
            ],
            "Resource": "*"
        }
    ]
}
```

## How to reference ECS Minimal Container in TaskDefinitions

Under a TaskDefinition -> ContainerDefinition, simply reference the minimal container image:

`Image: 01234567890.dkr.ecr.eu-west-1.amazonaws.com/ecs-minimal-container:latest`

Additionally, the usual AWS advice about doing container health check by running a curl call on the container won't work with the pure Apache container. Instead, simply echo a neutral status as the container health check:

```
HealthCheck:
  Command: [ "CMD-SHELL", "exit 0" ]
  Interval: 6
  Retries: 5
  StartPeriod: 5
  Timeout: 5
```
Example TaskDefinition. **Importantly**, you should configure the TaskDefinition with the memory and CPU capacities that you need for the real task, not just for the minimal image. Once you deploy the correct image after the build pipeline has run, only the image will change. 

```
  MyTaskDefinition:
    Type: AWS::ECS::TaskDefinition
    Properties:
      Family: service-name-production
      NetworkMode: bridge
      RequiresCompatibilities: [ EC2 ]
      ExecutionRoleArn: !GetAtt ECSTaskExecutionRole.Arn
      TaskRoleArn: !GetAtt MyTaskRole.Arn
      ContainerDefinitions:
        - Name: service-name-production
          Essential: true
          Image: 01234567890.dkr.ecr.eu-west-1.amazonaws.com/ecs-minimal-container:latest
          MemoryReservation: 128
          PortMappings:
            - ContainerPort: 80
              Protocol: tcp
          HealthCheck:
            Command: [ "CMD-SHELL", "exit 0" ]
            Interval: 6
            Retries: 5
            StartPeriod: 5
            Timeout: 5
          LogConfiguration:
            LogDriver: awslogs
            Options:
              awslogs-group: /ecs/service-name-production
              awslogs-region: eu-west-1
              awslogs-create-group: true
              awslogs-stream-prefix: ecs
