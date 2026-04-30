#!/usr/bin/env bash
# Usage: source ~/.env.nao-secrets && bash setup.sh
set -euo pipefail

: "${NAO_DB_PASSWORD:?NAO_DB_PASSWORD is required}"
: "${DATA_SOURCE_RDS_INSTANCE:?DATA_SOURCE_RDS_INSTANCE is required}"

AWS_REGION="us-east-2"
export AWS_DEFAULT_REGION="$AWS_REGION"

KEY_NAME="nao-key"
AMI_ID="ami-0ba835c136633e16f"  # Ubuntu 22.04 LTS, us-east-2
MY_IP="$(curl -s https://checkip.amazonaws.com)/32"

echo "Checking AWS credentials..."
aws sts get-caller-identity

VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=isDefault,Values=true" \
  --query 'Vpcs[0].VpcId' --output text)

echo "Creating key pair..."
KEY_FILE="/tmp/${KEY_NAME}.pem"
rm -f "$KEY_FILE"
aws ec2 delete-key-pair --key-name "$KEY_NAME" 2>/dev/null || true
aws ec2 create-key-pair \
  --key-name "$KEY_NAME" \
  --query 'KeyMaterial' --output text > "$KEY_FILE"
chmod 400 "$KEY_FILE"

echo "Creating security groups..."
EC2_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=nao-ec2-sg" "Name=vpc-id,Values=$VPC_ID" \
  --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || true)

if [ "$EC2_SG" = "None" ] || [ -z "$EC2_SG" ]; then
  EC2_SG=$(aws ec2 create-security-group \
    --group-name "nao-ec2-sg" \
    --description "Nao EC2" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' --output text)
  aws ec2 authorize-security-group-ingress --group-id "$EC2_SG" --protocol tcp --port 22 --cidr "$MY_IP"
  aws ec2 authorize-security-group-ingress --group-id "$EC2_SG" --protocol tcp --port 80 --cidr "0.0.0.0/0"
fi

RDS_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=nao-rds-sg" "Name=vpc-id,Values=$VPC_ID" \
  --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || true)

if [ "$RDS_SG" = "None" ] || [ -z "$RDS_SG" ]; then
  RDS_SG=$(aws ec2 create-security-group \
    --group-name "nao-rds-sg" \
    --description "Nao RDS" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' --output text)
  aws ec2 authorize-security-group-ingress --group-id "$RDS_SG" --protocol tcp --port 5432 --source-group "$EC2_SG"
fi

echo "Launching EC2 instance..."
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type "t3.small" \
  --key-name "$KEY_NAME" \
  --security-group-ids "$EC2_SG" \
  --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":20,"VolumeType":"gp3"}}]' \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=nao-server}]' \
  --query 'Instances[0].InstanceId' --output text)

aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

read ALLOC_ID ELASTIC_IP <<< $(aws ec2 allocate-address --domain vpc --query '[AllocationId,PublicIp]' --output text)
aws ec2 associate-address --instance-id "$INSTANCE_ID" --allocation-id "$ALLOC_ID"

echo "Creating RDS metadata DB..."
SUBNETS=$(aws ec2 describe-subnets \
  --filters "Name=defaultForAz,Values=true" \
  --query 'Subnets[*].SubnetId' --output text | tr '\t' ' ')

aws rds create-db-subnet-group \
  --db-subnet-group-name "nao-subnet-group" \
  --db-subnet-group-description "Nao" \
  --subnet-ids $SUBNETS 2>/dev/null || true

echo "Configuring RDS SSL parameter group..."
aws rds create-db-parameter-group \
  --db-parameter-group-name "nao-pg16-no-ssl" \
  --db-parameter-group-family postgres16 \
  --description "Nao - SSL not forced" 2>/dev/null || true

aws rds modify-db-parameter-group \
  --db-parameter-group-name "nao-pg16-no-ssl" \
  --parameters "ParameterName=rds.force_ssl,ParameterValue=0,ApplyMethod=immediate"

aws rds create-db-instance \
  --db-instance-identifier "nao-metadata-db" \
  --db-instance-class "db.t3.micro" \
  --engine postgres --engine-version "16" \
  --master-username "nao_user" \
  --master-user-password "$NAO_DB_PASSWORD" \
  --db-name "nao_db" \
  --allocated-storage 20 --storage-type gp3 \
  --vpc-security-group-ids "$RDS_SG" \
  --db-subnet-group-name "nao-subnet-group" \
  --db-parameter-group-name "nao-pg16-no-ssl" \
  --no-publicly-accessible \
  --backup-retention-period 7 \
  --preferred-backup-window "03:00-04:00" \
  --no-multi-az 2>/dev/null || true

echo "Waiting for RDS (~10 min)..."
aws rds wait db-instance-available --db-instance-identifier "nao-metadata-db"

DB_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier "nao-metadata-db" \
  --query 'DBInstances[0].Endpoint.Address' --output text)

echo "Configuring data source DB access..."
DATA_SOURCE_SG=$(aws rds describe-db-instances \
  --db-instance-identifier "$DATA_SOURCE_RDS_INSTANCE" \
  --query 'DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId' \
  --output text)

aws ec2 authorize-security-group-ingress \
  --group-id "$DATA_SOURCE_SG" \
  --protocol tcp --port 5432 --cidr "${ELASTIC_IP}/32" 2>/dev/null || true

echo ""
echo "════════════════════════════════════════════════════════"
echo " Setup complete! Next steps:"
echo "════════════════════════════════════════════════════════"
echo ""
echo " 1. Add to ~/.env.nao-secrets:"
echo "    export NAO_METADATA_URL=\"postgres://nao_user:${NAO_DB_PASSWORD}@${DB_ENDPOINT}:5432/nao_db\""
echo "    export DATA_SOURCE_HOST=\"<rds-datasource-endpoint>\""
echo ""
echo " 2. Copy and run:"
echo "    scp -i ${KEY_FILE} /c/Users/katep/Secrets/.env.nao-secrets /c/Users/katep/claude/nao-deployment/deploy.sh ubuntu@${ELASTIC_IP}:~/"
echo "    ssh -i ${KEY_FILE} ubuntu@${ELASTIC_IP}"
echo ""
echo " 3. On the EC2:"
echo "    source ~/.env.nao-secrets && bash ~/deploy.sh"
echo ""
echo " 4. Access Nao at: http://${ELASTIC_IP}"
echo "════════════════════════════════════════════════════════"
