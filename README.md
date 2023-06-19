# ECS Minimal Container

It's difficult to launch a AWS CloudFormation template that creates an AWS Elastic Container Service cluster as well as a build pipeline at the same time. The cluster can only be launched if there are already containers present that will respond to health checks, or the CloudFormation template will hang. Yet, such containers will only be built later by the build pipeline.

**ECS Minimal Container** is a barebones HTTP container that responds to health checks, which can be uploaded ahead of time to an Elastic Container Registry, and referenced in TaskDefinitions in the CloudFormation template. This will allow the CloudFormation to launch. The simultaneously deployed build pipeline can then build the correct images and deploy as normal, replacing the ECS Minimal Containers.

## How To Use

After completing the prerequisites below, simply run `build.sh` from a bash shell. You will be asked for:

* The region (e.g. eu-west-1).
* The root of an Elastic Container Registry (e.g. 01234567890.dkr.ecr.eu-west-1.amazonaws.com)
* An AWS Access Key ID.
* An AWS Secret Key.

The script builds the included Dockerfile, which is simply an Apache server with a couple of static HTML files for healthchecks. It then pushes it to your Elastic Container Registry, allowing you to reference it in TaskDefinitions in CloudFormation templates.

## Prerequisites

* Install Docker Desktop.
* Install AWS CLI.
* Create an Elastic Container Registry called "ecs-minimal-container" in the same region as the CloudFormation template will run.
* Create an IAM user with the following permissions:

```{
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
}```
