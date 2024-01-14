#!/bin/bash
if [ $# -eq 0 ]; then
  echo "Usage: $0 <example number>"
  exit 1
fi

call() {
  echo "$*"
  "$@"
}

STREAM_NAME=temperature-sensor-data
STREAM_ARN=arn:aws:kinesis:us-east-1:179536148295:stream/temperature-sensor-data
IAM_ROLE_NAME=kinesis-lambda-dynamodb
ROLE_ARN=arn:aws:iam::179536148295:role/kinesis-lambda-dynamodb

BUCKET_NAME=s3://sensor-data-$USER

example=$1
case $example in
  d1-create-shopping-cart)
    call aws dynamodb create-table \
      --table-name ShoppingCart \
      --attribute-definitions AttributeName=ItemName,AttributeType=S \
      --key-schema AttributeName=ItemName,KeyType=HASH \
      --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1
    ;;
  d1-describe-shopping-cart)
    call aws dynamodb describe-table \
      --table-name ShoppingCart
    ;;
  d1-put-items-cart)
    call aws dynamodb put-item --table-name ShoppingCart \
      --item '{"ItemName": {"S": "Tickle Me Elmo"}}'
    call aws dynamodb put-item --table-name ShoppingCart \
      --item '{"ItemName": {"S": "1975 Buick LeSabre"}}'
    call aws dynamodb put-item --table-name ShoppingCart \
      --item '{"ItemName": {"S": "Ken Burns: the Complete Box Set"}}'
    ;;
  d1-scan-shopping-cart)
    call aws dynamodb scan --table-name ShoppingCart
    ;;
  d1-get-item)
    call aws dynamodb get-item --table-name ShoppingCart \
      --key '{"ItemName": {"S": "Tickle Me Elmo"}}'
    ;;
  d1-get-item-consistent)
    call aws dynamodb get-item --table-name ShoppingCart \
      --key '{"ItemName": {"S": "Tickle Me Elmo"}}' \
      --consistent-read
    ;;
  d1-delete-item)
    call aws dynamodb delete-item --table-name ShoppingCart \
      --key '{"ItemName": {"S": "Tickle Me Elmo"}}'
    ;;
  d1-create-books)
    call aws dynamodb create-table \
      --table-name Books \
      --attribute-definitions AttributeName=Title,AttributeType=S \
      AttributeName=PublishYear,AttributeType=N \
      --key-schema AttributeName=Title,KeyType=HASH \
      AttributeName=PublishYear,KeyType=RANGE \
      --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1
    ;;
  d1-put-items-books)
    call aws dynamodb put-item --table-name Books \
      --item '{
        "Title": {"S": "Moby Dick"},
        "PublishYear": {"N": "1851"},
        "ISBN": {"N": "12345"}
    }'
    call aws dynamodb put-item --table-name Books \
      --item '{
        "Title": {"S": "Moby Dick"},
        "PublishYear": {"N": "1971"},
        "ISBN": {"N": "23456"},
        "Note": {"S": "Out of print"}
    }'
    call aws dynamodb put-item --table-name Books \
      --item '{
        "Title": {"S": "Moby Dick"},
        "PublishYear": {"N": "2008"},
        "ISBN": {"N": "34567"}
    }'
    ;;
  d1-query-books)
    call aws dynamodb query --table-name Books \
      --expression-attribute-values '{
        ":title": {"S": "Moby Dick"},
        ":year": {"N": "1980"}
      }' \
      --key-condition-expression 'Title = :title AND PublishYear > :year'
    ;;
  d1-query-and-project-books)
    call aws dynamodb query --table-name Books \
      --expression-attribute-values '{
        ":title": {"S": "Moby Dick"},
        ":year": {"N": "1900"}
      }' \
      --key-condition-expression 'Title = :title AND PublishYear > :year' \
      --projection-expression 'ISBN'
    ;;
  d1-query-empty-projection)
    call aws dynamodb query --table-name Books \
      --expression-attribute-values '{
        ":title": {"S": "Moby Dick"},
        ":year": {"N": "1900"}
      }' \
      --key-condition-expression 'Title = :title AND PublishYear > :year' \
      --projection-expression 'Note'
    ;;
  d1-conditional-put)
    call aws dynamodb put-item --table-name ShoppingCart \
      --item '{"ItemName": {"S": "Tickle Me Ernie"}}' \
      --condition-expression "attribute_not_exists(ItemName)"
    ;;
  d2-create-sensor-data)
    call aws dynamodb create-table \
      --cli-input-json file://sensor-data-table.json
    ;;
  d2-create-kinesis-stream)
    call aws kinesis create-stream \
      --stream-name ${STREAM_NAME} \
      --shard-count 1
    ;;
  d2-describe-kinesis-stream)
    call aws kinesis describe-stream \
      --stream-name ${STREAM_NAME} \
    ;;
  d2-kinesis-put)
    call aws kinesis put-record \
      --stream-name ${STREAM_NAME} \
      --partition-key sensor-data \
      --cli-binary-format raw-in-base64-out \
      --data "Baby's first Kinesis record"
    ;;
  d2-create-lambda-role)
    call aws iam create-role \
      --role-name ${IAM_ROLE_NAME} \
      --assume-role-policy-document file://lambda-kinesis-role.json
    call aws iam attach-role-policy \
      --role-name ${IAM_ROLE_NAME} \
      --policy-arn \
        arn:aws:iam::aws:policy/service-role/AWSLambdaKinesisExecutionRole
    call aws iam attach-role-policy \
      --role-name ${IAM_ROLE_NAME} \
      --policy-arn \
        arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess
    ;;

  d2-get-role)
    call aws iam get-role --role-name ${IAM_ROLE_NAME}
    ;;

  d2-upload-lambda)
    call cp code/ProcessKinesisRecords.js ./
    call zip ProcessKinesisRecords.zip ProcessKinesisRecords.js
    aws lambda create-function \
      --region us-east-1 \
      --function-name ProcessKinesisRecords \
      --zip-file fileb://ProcessKinesisRecords.zip \
      --role ${ROLE_ARN} \
      --handler ProcessKinesisRecords.kinesisHandler \
      --runtime nodejs18.x
    ;;
  d2-test-lambda)
    call aws lambda invoke \
      --invocation-type RequestResponse \
      --function-name ProcessKinesisRecords \
      --cli-binary-format raw-in-base64-out \
      --payload file://test-lambda-input.txt \
      lambda-output.txt
    ;;
  d2-map-source)
    call aws lambda create-event-source-mapping \
      --function-name ProcessKinesisRecords \
      --event-source-arn ${STREAM_ARN} \
      --starting-position LATEST
    ;;

  d2-kinesis-put-real)
    DATA=$(echo '{"sensor_id":"sensor-3","temperature":99.8,"current_time":123456790}' | base64 -w 0)
    call aws kinesis put-record \
      --stream-name ${STREAM_NAME} \
      --partition-key sensor-data \
      --data "$DATA"
    ;;
  d2-kinesis-put-humidity)
    DATA=$(echo '{"sensor_id":"sensor-3","temperature":99.8,"current_time":123456790,"humidity":35}' | base64 -w 0)
    call aws kinesis put-record \
      --stream-name ${STREAM_NAME} \
      --partition-key sensor-data \
      --data "$DATA"
    ;;


  d3-ingest)
    for n in {1..10}; do
      call ruby upload-sensor-data.rb sensor-${n} 1000 &
    done
    ;;
  d3-kill)
    call pgrep -f upload-sensor-data | xargs kill -9
    ;;
  d3-scan)
    call aws dynamodb scan --table-name SensorData
    ;;

  d3-query-between-timestamps)
    T1=$(aws dynamodb scan --table-name SensorData \
      --query Items[0].CurrentTime.N | tr -d '"')
    T2=$(aws dynamodb scan --table-name SensorData \
      --query Items[200].CurrentTime.N | tr -d '"')
    call aws dynamodb query --table-name SensorData \
      --expression-attribute-values '{
        ":t1": {"N": "'"$T1"'"},
        ":t2": {"N": "'"$T2"'"},
        ":sensorId": {"S": "sensor-1"}
    }' \
      --key-condition-expression \
      'SensorId = :sensorId AND CurrentTime BETWEEN :t1 AND :t2' \
      --projection-expression 'Temperature'
    ;;
  d3-count)
    call aws dynamodb scan --table-name SensorData --query Count
    ;;
  d3-create-bucket)
    call aws s3 mb ${BUCKET_NAME}
    ;;
  *)
    echo "Example $example does not exist."
    ;;
esac

