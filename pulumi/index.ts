/**
 * Ledger Platform Infrastructure - Pulumi TypeScript
 *
 * This Pulumi program deploys the Ledger platform to AWS EKS.
 * Demonstrates IaC with TypeScript for type-safe infrastructure.
 */

import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import * as awsx from "@pulumi/awsx";
import * as eks from "@pulumi/eks";

// -----------------------------------------------------------------------------
// Configuration
// -----------------------------------------------------------------------------

const config = new pulumi.Config();
const environment = config.get("environment") || "dev";
const clusterName = config.get("clusterName") || "ledger-platform";
const nodeInstanceType = config.get("nodeInstanceType") || "t3.medium";
const minNodes = config.getNumber("minNodes") || (environment === "prod" ? 3 : 1);
const maxNodes = config.getNumber("maxNodes") || (environment === "prod" ? 10 : 3);
const desiredNodes = config.getNumber("desiredNodes") || (environment === "prod" ? 3 : 2);

// Common tags for all resources
const commonTags = {
    Project: "ledger-platform",
    Environment: environment,
    ManagedBy: "pulumi",
    Team: "platform",
};

// -----------------------------------------------------------------------------
// VPC
// -----------------------------------------------------------------------------

const vpc = new awsx.ec2.Vpc(`${clusterName}-vpc`, {
    cidrBlock: "10.0.0.0/16",
    numberOfAvailabilityZones: 3,
    enableDnsHostnames: true,
    enableDnsSupport: true,
    natGateways: {
        strategy: environment === "dev"
            ? awsx.ec2.NatGatewayStrategy.Single
            : awsx.ec2.NatGatewayStrategy.OnePerAz,
    },
    tags: {
        ...commonTags,
        Name: `${clusterName}-vpc`,
    },
});

// -----------------------------------------------------------------------------
// KMS Key for Encryption
// -----------------------------------------------------------------------------

const eksKmsKey = new aws.kms.Key(`${clusterName}-eks-key`, {
    description: "KMS key for EKS cluster encryption",
    deletionWindowInDays: 7,
    enableKeyRotation: true,
    tags: {
        ...commonTags,
        Name: `${clusterName}-eks-key`,
    },
});

const eksKmsAlias = new aws.kms.Alias(`${clusterName}-eks-alias`, {
    name: `alias/${clusterName}-eks`,
    targetKeyId: eksKmsKey.keyId,
});

// -----------------------------------------------------------------------------
// EKS Cluster
// -----------------------------------------------------------------------------

const cluster = new eks.Cluster(clusterName, {
    name: clusterName,
    vpcId: vpc.vpcId,
    publicSubnetIds: vpc.publicSubnetIds,
    privateSubnetIds: vpc.privateSubnetIds,
    instanceType: nodeInstanceType,
    desiredCapacity: desiredNodes,
    minSize: minNodes,
    maxSize: maxNodes,

    // Security: Enable encryption
    encryptionConfigKeyArn: eksKmsKey.arn,

    // Security: Enable logging
    enabledClusterLogTypes: [
        "api",
        "audit",
        "authenticator",
        "controllerManager",
        "scheduler",
    ],

    // Security: Private endpoint for production
    endpointPrivateAccess: true,
    endpointPublicAccess: environment === "dev",

    // Node configuration
    nodeAssociatePublicIpAddress: false,

    tags: {
        ...commonTags,
        Cluster: clusterName,
    },
});

// -----------------------------------------------------------------------------
// ECR Repositories
// -----------------------------------------------------------------------------

const services = ["payments-api", "audit-service", "notification-service"];

const ecrKmsKey = new aws.kms.Key(`${clusterName}-ecr-key`, {
    description: "KMS key for ECR encryption",
    deletionWindowInDays: 7,
    enableKeyRotation: true,
    tags: {
        ...commonTags,
        Name: `${clusterName}-ecr-key`,
    },
});

const ecrRepositories = services.map(service => {
    const repo = new aws.ecr.Repository(`ledger-${service}`, {
        name: `ledger/${service}`,
        imageTagMutability: "IMMUTABLE",
        imageScanningConfiguration: {
            scanOnPush: true,
        },
        encryptionConfigurations: [{
            encryptionType: "KMS",
            kmsKey: ecrKmsKey.arn,
        }],
        tags: {
            ...commonTags,
            Service: service,
        },
    });

    // Lifecycle policy to clean old images
    new aws.ecr.LifecyclePolicy(`${service}-lifecycle`, {
        repository: repo.name,
        policy: JSON.stringify({
            rules: [{
                rulePriority: 1,
                description: "Keep last 10 images",
                selection: {
                    tagStatus: "any",
                    countType: "imageCountMoreThan",
                    countNumber: 10,
                },
                action: {
                    type: "expire",
                },
            }],
        }),
    });

    return repo;
});

// -----------------------------------------------------------------------------
// IAM Roles for IRSA (IAM Roles for Service Accounts)
// -----------------------------------------------------------------------------

// Create OIDC provider for the cluster
const oidcProvider = new aws.iam.OpenIdConnectProvider(`${clusterName}-oidc`, {
    clientIdLists: ["sts.amazonaws.com"],
    thumbprintLists: ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"],
    url: cluster.core.oidcProvider?.url || "",
    tags: commonTags,
});

// Example: Pod identity for payments service
const paymentsServiceRole = new aws.iam.Role(`${clusterName}-payments-role`, {
    assumeRolePolicy: pulumi.all([oidcProvider.arn, oidcProvider.url]).apply(([arn, url]) =>
        JSON.stringify({
            Version: "2012-10-17",
            Statement: [{
                Effect: "Allow",
                Principal: {
                    Federated: arn,
                },
                Action: "sts:AssumeRoleWithWebIdentity",
                Condition: {
                    StringEquals: {
                        [`${url}:sub`]: "system:serviceaccount:default:payments-api",
                        [`${url}:aud`]: "sts.amazonaws.com",
                    },
                },
            }],
        })
    ),
    tags: {
        ...commonTags,
        Service: "payments-api",
    },
});

// -----------------------------------------------------------------------------
// Security Group for Additional Controls
// -----------------------------------------------------------------------------

const additionalSecurityGroup = new aws.ec2.SecurityGroup(`${clusterName}-additional-sg`, {
    vpcId: vpc.vpcId,
    description: "Additional security controls for Ledger platform",
    ingress: [
        {
            description: "Allow HTTPS from VPC",
            fromPort: 443,
            toPort: 443,
            protocol: "tcp",
            cidrBlocks: ["10.0.0.0/16"],
        },
    ],
    egress: [
        {
            description: "Allow all outbound",
            fromPort: 0,
            toPort: 0,
            protocol: "-1",
            cidrBlocks: ["0.0.0.0/0"],
        },
    ],
    tags: {
        ...commonTags,
        Name: `${clusterName}-additional-sg`,
    },
});

// -----------------------------------------------------------------------------
// Outputs
// -----------------------------------------------------------------------------

export const vpcId = vpc.vpcId;
export const privateSubnetIds = vpc.privateSubnetIds;
export const publicSubnetIds = vpc.publicSubnetIds;
export const clusterEndpoint = cluster.core.endpoint;
export const clusterNameOutput = cluster.core.cluster.name;
export const kubeconfig = cluster.kubeconfig;
export const ecrRepositoryUrls = ecrRepositories.map(repo => repo.repositoryUrl);
export const oidcProviderArn = oidcProvider.arn;
