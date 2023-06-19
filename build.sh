#!/bin/bash

# Created by Per Holmes / Hollywood Camera Work (www.hollywoodcamerawork.com). MIT License.

# This script builds an ECS Minimal Container and uploads it to an Elastic Container Registry,
# allowing a CloudFormation template to boot an ECS cluster before a build pipeline has run for the
# first time.
#
# See https://github.com/perholmes/ECSMinimalContainer for instructions.

set -e
clear
export SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${SCRIPTDIR}


export ECR_REGION=eu-west-1
export ECR_ROOT=01234567890.dkr.ecr.eu-west-1.amazonaws.com
export AWS_ACCESS_KEY_ID=AKIAT010101010101BD2


if [ -z ${SERVICENAME} ]; then
    read -p "List of repositories to create (comma-separated): " SERVICES
fi

read -p "AWS Secret Key: " AWS_SECRET_ACCESS_KEY

export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
export AWS_DEFAULT_REGION="${ECR_REGION}"

IFS=', ' read -r -a SERVICEARRAY <<< "$SERVICES"
for SERVICENAME in "${SERVICEARRAY[@]}"
do
    SERVICENAME=$(echo "${SERVICENAME}" | xargs)

    echo
    echo "========= Creating repository $SERVICENAME ========="
    echo

    docker build -t ${SERVICENAME} .
    docker tag ${SERVICENAME}:latest ${ECR_ROOT}/${SERVICENAME}:latest

    aws ecr create-repository \
                --repository-name ${SERVICENAME} \
                --region ${ECR_REGION} \
                --encryption-configuration encryptionType=KMS \
                --image-tag-mutability MUTABLE \
                --image-scanning-configuration scanOnPush=false || true

    aws ecr put-lifecycle-policy \
                --repository-name ${SERVICENAME} \
                --region ${ECR_REGION} \
                --lifecycle-policy-text "file://lifecyclepolicy.json" || true
        
    aws ecr get-login-password --region ${ECR_REGION} | docker login --username AWS --password-stdin "${ECR_ROOT}"
    docker push ${ECR_ROOT}/${SERVICENAME}:latest
done
