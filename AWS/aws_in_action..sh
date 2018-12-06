
tr:environment-type:  DEVELOPMENT
tr:application-asset-insight-id: 501138
tr:financial-identifier: 0661514060



aws ec2 describe-regions

aws ec2 describe-instances --filters "Name=instance-type,Values=t2.micro"


aws ec2 describe-images --query "Images[0].ImageId"
"ami-146e2a7c"

aws ec2 describe-images --query "Images[0].ImageId" --output text
ami-146e2a7c


aws ec2 describe-images --query "Images[*].State"
["available", "available"]


# get account ID from CLI
aws sts get-caller-identity --output text --query 'Account'

aws sts get-caller-identity
{
    "Account": "015887481462",
    "UserId": "AROAJVLQ6XU2X2QLZLZOI:i-03e9c213b12de8699",
    "Arn": "arn:aws:sts::015887481462:assumed-role/yongliu-role-ec2-to-s3/i-03e9c213b12de8699"
}



#--------------------------------

# Script to start a EC2 instance

#!/bin/bash -e
# You need to install the AWS Command Line Interface from http://aws.amazon.com/cli/
AMIID="$(aws ec2 describe-images --filters "Name=name,Values=amzn-ami-hvm-2017.09.1.*-x86_64-gp2" --query "Images[0].ImageId" --output text)"
VPCID="$(aws ec2 describe-vpcs --filter "Name=isDefault, Values=true" --query "Vpcs[0].VpcId" --output text)"
SUBNETID="$(aws ec2 describe-subnets --filters "Name=vpc-id, Values=$VPCID" --query "Subnets[0].SubnetId" --output text)"
SGID="$(aws ec2 create-security-group --group-name mysecuritygroup --description "My security group" --vpc-id "$VPCID" --output text)"
aws ec2 authorize-security-group-ingress --group-id "$SGID" --protocol tcp --port 22 --cidr 0.0.0.0/0
INSTANCEID="$(aws ec2 run-instances --image-id "$AMIID" --key-name mykey --instance-type t2.micro --security-group-ids "$SGID" --subnet-id "$SUBNETID" --query "Instances[0].InstanceId" --output text)"
echo "waiting for $INSTANCEID ..."
aws ec2 wait instance-running --instance-ids "$INSTANCEID"
PUBLICNAME="$(aws ec2 describe-instances --instance-ids "$INSTANCEID" --query "Reservations[0].Instances[0].PublicDnsName" --output text)"
echo "$INSTANCEID is accepting SSH connections under $PUBLICNAME"
echo "ssh -i mykey.pem ec2-user@$PUBLICNAME"
read -r -p "Press [Enter] key to terminate $INSTANCEID ..."
aws ec2 terminate-instances --instance-ids "$INSTANCEID"
echo "terminating $INSTANCEID ..."
aws ec2 wait instance-terminated --instance-ids "$INSTANCEID"
aws ec2 delete-security-group --group-id "$SGID"
echo "done."


-----------

PUBLICIPADDRESSESS="$(aws ec2 describe-instances \
--filters "Name=instance-state-name,Values=running" \
--query "Reservations[].Instances[].PublicIpAddress" \
--output text)"

for PUBLICIPADDRESS in $PUBLICIPADDRESSESS; do
  echo "$PUBLICIPADDRESS ..."
  ssh -t "ec2-user@$PUBLICIPADDRESS" "sudo yum -y --security update"
done

-----------


# find out the account ID
aws iam get-user --query "User.Arn" --output text


ARN of an EC2 instance
arn:aws:ec2:us-east-1:878533158213:instance/i-3dd4f812


aws iam create-group --group-name "admin"

aws iam attach-group-policy --group-name "admin" \
 --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"

aws iam create-user --user-name "myuser"
aws iam add-user-to-group --group-name "admin" --user-name "myuser"

aws iam create-login-profile --user-name "myuser" --password "$Password"


# terminating an EC2 instance after 5 minutes
echo "aws ec2 stop-instances --instance-ids i-0b5c991e026104db9" \
| at now + 5 minutes


# BastionHost

ssh-add $PathToKey/mykey.pem

# The -A option is important for enabling AgentForwarding; agent forwarding lets you
# authenticate with the same key you used to log in to the bastion host for further SSH
# logins initiated from the bastion host.

ssh -A ec2-user@$BastionHostPublicName


#The following command establishes an SSH connection to instance 1 by using the bastion host as a
# proxy.

ssh -J ec2-user@ec2-18-212-17-199.compute-1.amazonaws.com ec2-user@ec2-54-145-162-248.compute-1.amazonaws.com


# Deploying a Lambda function with SAM

aws cloudformation package --template-file template.yaml \
--s3-bucket yongliu-s3-bucket --output-template-file output.yaml


aws cloudformation deploy --stack-name yongliu-ec2-owner-tag \
--template-file output.yaml --capabilities CAPABILITY_IAM

aws cloudformation delete-stack --stack-name ec2-owner-tag


aws cloudformation delete-stack --stack-name yongliu-ec2-owner-tag

aws s3 rb s3://yongliu-s3-bucket --force


sudo fdisk -l

sudo mkfs -t ext4 /dev/xvdf

sudo mkdir /mnt/volume/
sudo mount /dev/xvdf /mnt/volume/

sudo umount /mnt/volume/



sudo dd if=/dev/zero of=/mnt/volume/tempfile bs=1M count=1024 \
conv=fdatasync,notrunc

echo 3 | sudo tee /proc/sys/vm/drop_caches

sudo dd if=/mnt/volume/tempfile of=/dev/null bs=1M count=1024

aws ec2 describe-volumes --region us-east-1 \
--filters "Name=size,Values=5" --query "Volumes[].VolumeId" \
--output text

fsfreeze -f /mnt/volume/


aws ec2 create-snapshot --region us-east-1 --volume-id $VolumeId


aws ec2 describe-snapshots --region us-east-1 --snapshot-ids $SnapshotId

fsfreeze -u /mnt/volume/

aws ec2 create-volume --region us-east-1 \
--snapshot-id $SnapshotId \
--availability-zone us-east-1a


aws ec2 delete-snapshot --region us-east-1 \
 --snapshot-id $SnapshotId

aws ec2 delete-volume --region us-east-1 \
--volume-id $RestoreVolumeId


aws rds describe-db-snapshots --snapshot-type automated \
 --db-instance-identifier $DBInstanceIdentifier \
 --query "DBSnapshots[0].DBSnapshotIdentifier" \
 --output text


aws rds copy-db-snapshot \
 --source-db-snapshot-identifier $SnapshotId \
 --target-db-snapshot-identifier wordpress-copy-snapshot


aws cloudformation describe-stack-resource \
--stack-name wordpress --logical-resource-id DBSubnetGroup \
--query "StackResourceDetail.PhysicalResourceId" --output text


aws rds restore-db-instance-from-db-snapshot \
 --db-instance-identifier awsinaction-db-restore \
 --db-snapshot-identifier wordpress-manual-snapshot \
 --db-subnet-group-name $SubnetGroup


# $Time with a UTC timestamp from 5 minutes ago (for example, 2017-10-19T10:55:00Z)

aws rds restore-db-instance-to-point-in-time \
--target-db-instance-identifier awsinaction-db-restore-time \
--source-db-instance-identifier $DBInstanceIdentifier \
--restore-time $Time \
--db-subnet-group-name $SubnetGroup


# Copying a database to another region

# get account ID,

aws iam get-user --query "User.Arn" --output text
arn:aws:iam::878533158213:user/mycli


aws rds copy-db-snapshot --source-db-snapshot-identifier \
 arn:aws:rds:us-east-1:$AccountId:snapshot:\
 wordpress-manual-snapshot \
 --target-db-snapshot-identifier wordpress-manual-snapshot \
 --region eu-west-1


aws rds delete-db-instance --db-instance-identifier \
 awsinaction-db-restore --skip-final-snapshot

 aws --region eu-west-1 rds delete-db-snapshot --db-snapshot-identifier \
 wordpress-manual-snapshot

curl -s https://raw.githubusercontent.com/AWSinAction/\
 code2/master/chapter11/cleanup.sh | bash -ex


aws rds create-db-instance-read-replica \
--db-instance-identifier awsinaction-db-read \
--source-db-instance-identifier $DBInstanceIdentifier


aws rds promote-read-replica --db-instance-identifier awsinaction-db-read

aws rds delete-db-instance --db-instance-identifier \
awsinaction-db-read --skip-final-snapshot



aws cloudformation create-stack --stack-name discourse \
 --template-url https://s3.amazonaws.com/awsinaction-code2/\
 chapter12/template.yaml \
 --parameters ParameterKey=KeyName,ParameterValue=mykey \
 "ParameterKey=AdminEmailAddress,ParameterValue=your@mail.com"


aws cloudformation describe-stacks --stack-name discourse \
 --query "Stacks[0].StackStatus"



aws cloudformation describe-stacks --stack-name discourse \
 --query "Stacks[0].Outputs[0].OutputValue"


aws cloudformation delete-stack --stack-name discourse




aws dynamodb create-table --table-name app-entity \
 --attribute-definitions AttributeName=id,AttributeType=S \
 --key-schema AttributeName=id,KeyType=HASH \
 --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5



aws dynamodb create-table --table-name yongliu-todo-user \
 --attribute-definitions AttributeName=uid,AttributeType=S \
 --key-schema AttributeName=uid,KeyType=HASH \
 --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5


aws dynamodb describe-table --table-name yongliu-todo-user



aws dynamodb create-table --table-name yongliu-todo-task \
 --attribute-definitions \
 AttributeName=uid,AttributeType=S \
 AttributeName=tid,AttributeType=N \
 --key-schema \
 AttributeName=uid,KeyType=HASH \
 AttributeName=tid,KeyType=RANGE \
 --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5


aws dynamodb describe-table --table-name yongliu-todo-task


aws dynamodb update-table --table-name yongliu-todo-task \
 --attribute-definitions \
 AttributeName=uid,AttributeType=S \
 AttributeName=tid,AttributeType=N \
 AttributeName=category,AttributeType=S \
 --global-secondary-index-updates "[{\
 \"Create\": {\
 \"IndexName\": \"category-index\", \
 \"KeySchema\": [{\"AttributeName\": \"category\", \"KeyType\": \"HASH\"}, \
               {\"AttributeName\": \"tid\",      \"KeyType\": \"RANGE\"}], \
 \"Projection\": {\"ProjectionType\": \"ALL\"}, \
 \"ProvisionedThroughput\": {\"ReadCapacityUnits\": 5, \
                          \"WriteCapacityUnits\": 5} \
}}]"



aws dynamodb describe-table --table-name=yongliu-todo-task \
--query "Table.GlobalSecondaryIndexes"



aws dynamodb get-item --table-name todo-user \
 --key '{"uid": {"S": "michael"}}' \
 --return-consumed-capacity TOTAL \
 --query "ConsumedCapacity"

aws dynamodb get-item --table-name todo-user \
 --key '{"uid": {"S": "michael"}}' \
 --consistent-read --return-consumed-capacity TOTAL \
 --query "ConsumedCapacity"



aws ec2 describe-regions

aws ec2 describe-availability-zones --region $Region


aws ec2 describe-instances --filters "Name=tag:Name,\
 Values=jenkins-multiaz" "Name=instance-state-code,Values=16" \
 --query "Reservations[0].Instances[0].\
 [InstanceId, PublicIpAddress, PrivateIpAddress, SubnetId]"


aws ec2 terminate-instances --instance-ids $InstanceId

aws cloudformation delete-stack --stack-name jenkins-multiaz

aws cloudformation wait stack-delete-complete \
 --stack-name jenkins-multiaz


aws s3 mb s3://url2png-$yourname

aws s3 website s3://url2png-$yourname --index-document index.html \
--error-document error.html

aws sqs create-queue --queue-name url2png


aws sqs get-queue-attributes \
 --queue-url "$QueueUrl" \
 --attribute-names ApproximateNumberOfMessages


aws elasticbeanstalk list-available-solution-stacks

aws cloudformation describe-stacks --stack-name yongliu-imagery



aws cloudformation describe-stack-resource --stack-name yongliu-imagery \
 --logical-resource-id Bucket \
 --query "StackResourceDetail.PhysicalResourceId"
 --output text


aws s3 rm s3://$bucketname --recursive

aws cloudformation delete-stack --stack-name imagery

# send 500,000 requests to the load balancer using 15 threads.
# The load test is limited to 600 seconds and we’re using a connection timeout
# of 120 seconds.

yum install -y httpd24-tools


ab -n 500000 -c 15 -t 600 -s 120 -r http://${LoadBalancer.DNSName}/



IDENTITY_POOL_ID=$(aws cognito-identity create-identity-pool --identity-pool-name $IDENTITY_POOL_NAME \
        --allow-unauthenticated-identities --developer-provider-name $DEVELOPER_PROVIDER_NAME \
        --query 'IdentityPoolId' --output text --region $REGION)


aws iam create-role --role-name sampleAuthChangePassword --assume-role-policy-document file://Policy_Trust_Lambda.json

aws iam update-assume-role-policy --role-name sampleAuthChangePassword --policy-document file://Policy_Trust_Lambda.json
aws iam put-role-policy --role-name sampleAuthChangePassword --policy-name sampleAuthChangePassword --policy-document file://sampleAuthChangePassword.json


aws iam get-role --role-name sampleAuthChangePassword
aws iam get-role-policy --role-name sampleAuthChangePassword --policy-name sampleAuthChangePassword


roles='{"unauthenticated":"arn:aws:iam::'"015887481462"':role/'"$unauthRole"'" , "authenticated":"arn:aws:iam::'"015887481462"':role/'"$authRole"'"}'
aws cognito-identity set-identity-pool-roles \
  --identity-pool-id us-east-1:f07a5c39-deed-439a-b92e-cfdfa3431d32 \
  --roles $roles \
  --region $REGION



cd sampleAuthChangePassword

zip -r sampleAuthChangePassword.zip index.js config.json lib/

aws lambda create-function --function-name sampleAuthChangePassword \
      --runtime nodejs8.10 \
      --role arn:aws:iam::015887481462:role/sampleAuthChangePassword \
      --handler index.handler \
      --zip-file fileb://sampleAuthChangePassword.zip \
      --region us-east-1

aws lambda tag-resource --resource arn:aws:lambda:us-east-1:015887481462:function:sampleAuthChangePassword  \
--tags '{"tr:application-asset-insight-id": "501138", "tr:financial-identifier":"0661514060" }'


aws lambda update-function-code --function-name sampleAuthChangePassword \
      --zip-file fileb://sampleAuthChangePassword.zip \
      --region us-east-1


cd wwww

aws s3 sync . s3://yongliu-s3-bucket --cache-control max-age="10" --acl public-read






