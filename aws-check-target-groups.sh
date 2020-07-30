#!/bin/bash

export AWS_PROFILE=***
export AWS_DEFAULT_REGION=eu-central-1

for TAG in $(aws elbv2 describe-target-groups|jq -r '.[]|.[].TargetGroupArn'|cut -d/ -f2|grep -v ^[0-9]); do
  echo "Checking instances in target group ${TAG}"
  RUNNING=$(aws ec2 describe-instances --filter Name=tag-key,Values=Name --query "Reservations[*].Instances[*].{Instance:InstanceId,Name:Tags[?Key=='Name']|[0].Value}"|jq -r '.[]|.[].Name'|grep ^${TAG}$|wc -l)
  TARGET_GROUP=$(aws elbv2 describe-target-groups|jq -r '.[]|.[].TargetGroupArn'|grep /${TAG}/)
  ACTUAL=$(aws elbv2 describe-target-health --target-group-arn ${TARGET_GROUP}|jq -r '.TargetHealthDescriptions[].Target.Id'|wc -l)
  #TAGS=$(aws elbv2 describe-tags --resource-arns ${TARGET_GROUP} |jq -r '.TagDescriptions[].Tags'| jq -r '.[].Key, .[].Value')
  if [[ ${RUNNING} != ${ACTUAL} ]]; then
    echo "Running instances ${RUNNING}, but target groups has ${ACTUAL}"
    for INSTANCE_ID in $(aws ec2 describe-instances --filter Name=tag-key,Values=Name --query "Reservations[*].Instances[*].{Instance:InstanceId,Name:Tags[?Key=='Name']|[0].Value}"|jq ".[][]|select(.Name==\"${TAG}\")"|jq -r .Instance); do
      ASG=$(aws autoscaling describe-auto-scaling-instances|jq '.AutoScalingInstances'|jq ".[]|select(.InstanceId==\"${INSTANCE_ID}\")"|jq -r .InstanceId)
      echo "Updating ${TARGET_GROUP} to add instances from ${ASG}"
      aws elbv2 register-targets --target-group-arn ${TARGET_GROUP} --targets "Id="${ASG}
    done
    echo "Target group for ${TAG} was updated using profile ${PROFILE}"|mail -s "Target group for ${TAG} was updated using profile ${PROFILE}" mail
  fi
done
