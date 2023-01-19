#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Stop EC2/RDS instances that resource_state tag is defined as 'hold' and 'decommissioned'
#
import json
import os
import re
import boto3
from boto3.session import Session

region = os.environ["AWS_REGION"]

session = Session(region_name=region)
client_ec2 = session.client("ec2")
resource_ec2 = boto3.resource("ec2", region_name=region)
rdsclient = session.client("rds")


def stop_ec2():
    try:
        filters = [
            {"Name": "instance-state-name", "Values": ["running"]},
            {"Name": "tag-key", "Values": ["resource_state"]},
        ]

        instances = resource_ec2.instances.filter(Filters=filters)
        for i in instances:
            # Do only if resource_state tag is defined as 'decommissioned' or "hold"
            resource_state_tag = [x["Value"] for x in i.tags if x["Key"] == "resource_state"]
            resource_state = resource_state_tag[0] if len(resource_state_tag) else ""

            if not (
                resource_state.lower() == "decommissioned" or resource_state.lower() == "hold"
            ):
                continue

           

            # Stop EC2 instances which have 'decommissioned' resource_state tag
            try:
                response = client_ec2.stop_instances(
                    InstanceIds=[i.id],
                    # DryRun=True,
                    Force=False,
                )
               
            except Exception as e:
                raise e

    except Exception as e:
        raise e


def stop_rds():

    # Describe DB Instances
    response = rdsclient.describe_db_instances()

    # List of RDS instances that need to be stopped
    # because resource_state == 'decommissioned' AND..
    # DBInstanceStatus == 'available'
    decomm_rds_instances = []
    for each_rds in response["DBInstances"]:

        # Grab resource_state tag from resource tags
        resource_state = None
        for each_taglist in each_rds["TagList"]:
            found_resource_state = False
            for tag_k, tag_v in each_taglist.items():
                if tag_k == "Key" and tag_v == "resource_state":
                    found_resource_state = True

                if tag_k == "Value" and found_resource_state:
                    resource_state = tag_v
                    found_resource_state = False

        # Set list of decomm_rds_instances
        if (
            resource_state
            and (resource_state.lower() == "decommissioned" or resource_state.lower() == "hold")
            and (each_rds["DBInstanceStatus"])
            and (each_rds["DBInstanceStatus"] == "available")
        ):

            # RDS Instances
            if "DBInstanceIdentifier" in each_rds:
                decomm_rds_instances.append(each_rds["DBInstanceIdentifier"])

    # Stop decommissioned RDS Instances
    if decomm_rds_instances:
        for rds_ins in decomm_rds_instances:
            try:
                result = rdsclient.stop_db_instance(DBInstanceIdentifier=rds_ins)
            except Exception as e:
                print(e)
            else:
                print(f"Stopped decommissioned RDS Instance : {rds_ins}")


def stop_rds_cluster():

    # Describe DB Clusters
    response = rdsclient.describe_db_clusters()

    # List of RDS clusters that need to be stopped
    # because resource_state == 'decommissioned' AND..
    # Status == 'available'
    decomm_rds_clusters = []
    for each_rds in response["DBClusters"]:

        # Grab resource_state tag from resource tags
        resource_state = None
        for each_taglist in each_rds["TagList"]:
            found_resource_state = False
            for tag_k, tag_v in each_taglist.items():
                if tag_k == "Key" and tag_v == "resource_state":
                    found_resource_state = True

                if tag_k == "Value" and found_resource_state:
                    resource_state = tag_v
                    found_resource_state = False

        # Set list of decomm_rds_clusters
        if (
            resource_state
            and (resource_state.lower() == "decommissioned" or resource_state.lower() == "hold")
            and (each_rds["Status"])
            and (each_rds["Status"] == "available")
        ):

            # RDS Clusters
            if "DBClusterIdentifier" in each_rds:
                decomm_rds_clusters.append(each_rds["DBClusterIdentifier"])

    # Stop decommissioned RDS Clusters
    if decomm_rds_clusters:
        for rds_cls in decomm_rds_clusters:
            try:
                result = rdsclient.stop_db_cluster(DBClusterIdentifier=rds_cls)
            except Exception as e:
                print(e)
            else:
                print(f"Stopped decommissioned RDS Cluster : {rds_cls}")


def lambda_handler(event, context):
    try:
        stop_ec2()
        stop_rds()
        stop_rds_cluster()

    except Exception as e:
        raise e
