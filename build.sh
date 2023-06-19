#!/bin/bash

# Created by Hollywood Camera Work (www.hollywoodcamerawork.com). MIT License.

# This script builds an ecs-minimal-container and uploads it to an Elastic Container Registry.

# PREREQUISITES:
# - AWS CLI must be installed.
# - TaskDefinition ContainerDefinition should healthcheck using [ "CMD-SHELL", "exit 0" ].
#   There's no Curl on the Apache httpd used as the basis.
# - Create an IAM user "ecr-push" with the following inline policy, which allows pushing to any
#   repository under the account:
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Effect": "Allow",
#             "Action": [
#                 "ecr:CompleteLayerUpload",
#                 "ecr:GetAuthorizationToken",
#                 "ecr:UploadLayerPart",
#                 "ecr:InitiateLayerUpload",
#                 "ecr:BatchCheckLayerAvailability",
#                 "ecr:PutImage"
#             ],
#             "Resource": "*"
#         }
#     ]
# }

set -e
clear
export SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${SCRIPTDIR}

echo "Create ecs-minimal-container"
read -p "Region (e.g. eu-west-1)                                        : " ECR_REGION
read -p "ECR Root (e.g. 01234567890.dkr.ecr.eu-west-1.amazonaws.com)    : " ECR_ROOT
read -p "AWS Access Key                                                 : " ACCESS_KEY
read -p "AWS Secret Key                                                 : " SECRET_KEY

export AWS_ACCESS_KEY_ID="${ACCESS_KEY}"
export AWS_SECRET_ACCESS_KEY="${SECRET_KEY}"
export AWS_DEFAULT_REGION="${ECR_REGION}"

docker build -t ecs-minimal-container .
docker tag ecs-minimal-container:latest ${ECR_ROOT}/ecs-minimal-container:latest

aws ecr get-login-password --region ${ECR_REGION} | docker login --username AWS --password-stdin "${ECR_ROOT}"
docker push ${ECR_ROOT}/ecs-minimal-container:latest
