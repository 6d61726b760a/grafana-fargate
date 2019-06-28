# grafana-fargate

deploy grafana to AWS fargate using cloudformation

## prepare

* create an RDS instance for grafana to use

    ```
    INSTANCE_ID='instance-identifier'
    MASTER_USERNAME='masteruser'
    MASTER_PASSWORD='masterpassword'
    SUBNET_GROUP_NAME='subnetgroup'
    SECURITY_GROUP='securitygroup'
    AWS_PROFILE='profilename'
    TAGS=[{"Key": "tag1key", "Value": "tag1value" },{ "Key": "tag2key", "Value": "tag2value" }]

    aws rds create-db-instance \
      --db-instance-identifier ${INSTANCE_ID} \
      --allocated-storage 20 \
      --storage-encrypted  \
      --no-publicly-accessible \
      --multi-az \
      --db-instance-class db.t2.small \
      --db-subnet-group-name ${SUBNET_GROUP_NAME} \
      --vpc-security-group-ids ${SECURITY_GROUP}
      --enable-cloudwatch-logs-exports '["postgresql","upgrade"]' \
      --engine postgres \
      --master-username ${MASTER_USERNAME} \
      --master-user-password ${MASTER_PASSWORD} \
      --profile ${AWS_PROFILE}
    ```

* DB schema and user for grafana to use

    ```
    CREATE DATABASE grafana;
    CREATE USER grafana WITH ENCRYPTED PASSWORD 'grafanadbpassword';
    GRANT ALL PRIVILEGES ON DATABASE grafana TO grafana;
    ```

* SSM and Secrets for the DB you just created

    ```
    aws ssm put-parameter \
      --name "/grafana/GF_DATABASE_HOST" \
      --value "your.rds.endpoint" \
      --type String \
      --profile ${AWS_PROFILE}

    aws ssm put-parameter \
      --name "/grafana/GF_DATABASE_USER" \
      --value "grafana" \
      --type String \
      --profile ${AWS_PROFILE}

    aws secretsmanager create-secret \
        --name grafana_rds_password \
        --description "rds password for grafana" \
        --secret-string "grafanadbpassword" \
        --profile ${AWS_PROFILE}
    ```

## deploy

```
TEMPLATE="cfn-grafana.yaml
STACK_NAME="grafana"
CONTAINER_SUBNETS="subnet-1,subnet-2,subnet-3"
CONTAINER_VPC="vpc-1"
LB_SUBNETS="subnet-1,subnet-2,subnet-3"
LB_VPC="vpc-1"
TAGS="tag1key=tag1value tag2key=tag2value"
AWS_PROFILE='profilename'

aws cloudformation deploy \
  --template-file cfn-grafana-dev.yaml \
  --stack-name grafana-nonprod-dev \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides \
    ContainerVpcId="${CONTAINER_VPC}" \
    ContainerSubnets="${CONTAINER_SUBNETS}" \
    LoadBalancerVpcId="${LB_VPC}" \
    LoadBalancerSubnets="${LB_SUBNETS}" \
  --tags ${TAGS} \
  --profile ${AWS_PROFILE}
```


## extend

* add dns record for your load balancer so you can acess it from a friendly URL
* configure an redis/memcache (elasticache) instead of using the default database


