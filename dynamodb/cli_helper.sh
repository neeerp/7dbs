#!/bin/bash
if [ $# -eq 0 ]; then
  echo "Usage: $0 <example number>"
  exit 1
fi

call() {
  echo "$*"
  "$@"
}

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
  *)
    echo "Example $example does not exist."
    ;;
esac

