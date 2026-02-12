const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient } = require("@aws-sdk/lib-dynamodb");
const { SNSClient } = require("@aws-sdk/client-sns");
const { SQSClient } = require("@aws-sdk/client-sqs");
const { SecretsManagerClient } = require("@aws-sdk/client-secrets-manager");

const REGION = process.env.AWS_REGION || "us-east-1";

const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({ region: REGION }));
const sns = new SNSClient({ region: REGION });
const sqs = new SQSClient({ region: REGION });
const secrets = new SecretsManagerClient({ region: REGION });

module.exports = { ddb, sns, sqs, secrets };
