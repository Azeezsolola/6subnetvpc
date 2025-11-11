#!/usr/bin/python

import boto3,botocore

#quarantine_sg = isolationSg
    
def remediationaction(event):
    #===calling Sts to get caller identity 
    sts = boto3.client('sts',region_name='us-east-1')
    response = sts.get_caller_identity()
    print(response['Arn']) 
    Instance_ID=event['Findings'][0]['Resource']['InstanceId']
    Instance_State=event['Findings'][0]['Resource']['InstanceState']

    print("This is the isnstance ID:",Instance_ID)
    print("This is the instance State:",Instance_State)

    #===Describing the compromised instance 
    ec2=boto3.client('ec2',region_name='us-east-1')
    response = ec2.describe_instances(InstanceIds=[Instance_ID], DryRun=False)
    #print(response)
    
    #====Extracting some parameters that will be used later on
    instance = response['Reservations'][0]['Instances'][0]
    security_groups = instance['SecurityGroups'][0]['GroupName']
    VPC_ID = instance['VpcId']
    ebs_volume_id = instance['BlockDeviceMappings'][0]['Ebs']['VolumeId']

    print('This is the secuirty group currently attached to the instance:',security_groups)
    print('This is the VPC_ID where the SG is created',VPC_ID)
    
    #===Listing security groups and also filtering a specific SG
    Listsecuritygroups = boto3.client('ec2',region_name='us-east-1')
    response = Listsecuritygroups.describe_security_groups(
    Filters=[
        {
            'Name': 'group-name',
            'Values': ['quarantine_sg']
        }
    ]
    )
    #print(response)
    #===Extracting some data from response 
    securitygroup_confirmation = response['SecurityGroups'][0]['GroupName']
    print(securitygroup_confirmation)
    print('The securitygroup confirmation printed')
    
    SG_status_code = response['ResponseMetadata']['HTTPStatusCode']
    
    #=====conditional statatement to check if SQ already exist or not 
    if securitygroup_confirmation == 'quarantine_sg':
        print('Isolation security group already exist')
        
        vpc_instatiation = boto3.client('ec2',region_name='us-east-1')
        vpcs = vpc_instatiation.describe_vpcs(
            Filters=[
                {'Name': 'tag:Name', 'Values': ['TerraformVPC']}
            ]
        )
        vpc_id = vpcs['Vpcs'][0]['VpcId']
        print('The vpcID is:',vpc_id)
        
        
        ec2 = boto3.client('ec2',region_name='us-east-1')
        sg_name = 'quarantine_sg'
        response = ec2.describe_security_groups(
            Filters=[
                {
                    'Name': 'group-name',
                    'Values': [sg_name]
                },{'Name': 'vpc-id', 'Values': [vpc_id]}
            ]
        )
        #print(response)
        New_SECURITY_GROUP_ID=response['SecurityGroups'][0]['GroupId']
        print('The Existing security ID is:',New_SECURITY_GROUP_ID)
        
    else:
        print('Isolation SG does not exist.Now Creating.....')
        response=ec2.create_security_group(Description='Ssecurity group for isolating compromised ec2 instance',
        GroupName='quarantine_sg',
        VpcId=VPC_ID,
        TagSpecifications=[
            {
                'ResourceType': 'security-group',
                'Tags': [
                {
                        'Key': 'Name',
                        'Value': 'quarantine_sg'
                    },
                ]
            },
        ],
        DryRun=False
        )
        New_SECURITY_GROUP_ID=response['GroupId']
        print(response['GroupId'])
    
    

        
    eni_id = ec2.describe_instances(InstanceIds=[Instance_ID])['Reservations'][0]['Instances'][0]['NetworkInterfaces'][0]['NetworkInterfaceId']
    response=ec2.modify_network_interface_attribute(
         NetworkInterfaceId=eni_id,
         Groups=[New_SECURITY_GROUP_ID]
     )

    status_code = response['ResponseMetadata']['HTTPStatusCode']
    print(status_code)
    
    if status_code == 200:
        print('Compromised Instance have been completely isolated with status code:',status_code)
    else:
        print('Isolation failed.Failed, status code:',status_code)

    Loadbalancer_name = 'TerraformLB'
    lb = boto3.client('elbv2',region_name='us-east-1' )
    response = lb.describe_load_balancers(
    
    Names=[Loadbalancer_name],
    )
    
    #print(response)
    
    Loadbalancer_arn = response['LoadBalancers'][0]['LoadBalancerArn']
    print('This is the load balancer ARN:',Loadbalancer_arn)
    
    
    #===Describing target group so i can extract some data 
    TG = boto3.client('elbv2',region_name='us-east-1' )
    response = TG.describe_target_groups(
    LoadBalancerArn=Loadbalancer_arn,
    )
    #print(response)

    Targetgroup_arn = response['TargetGroups'][0]['TargetGroupArn']
    print('This is the Target group arn:',Targetgroup_arn)
    
    #====Creating snapshot of the compromised ec2 instance 
    ec2_snapshot = boto3.client('ec2',region_name='us-east-1')
    response = ec2_snapshot.create_snapshot(
    Description='Creating snapshot for compromised ec2 instance',
    VolumeId= ebs_volume_id,
    TagSpecifications=[
        {
            'ResourceType': 'snapshot',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': 'Compromised_Instance_Snapshot'
                },
            ]
        },
    ],
    DryRun=False
    )
    status_code = response['ResponseMetadata']['HTTPStatusCode']
    #===Checking exit status 
    if status_code == 200:
        print('Snapshot for the compromised ec2 instance has been created.status code:',status_code)
    
    else:
        print('Snapshot for the compromised ec2 instance failed with status code:',status_code)
        
    #===Deregistering the compromised instance from the target group
    Deregister_Taregt =  boto3.client('elbv2',region_name='us-east-1' )
    response = Deregister_Taregt.deregister_targets(
    TargetGroupArn=Targetgroup_arn,
    Targets=[
        {
            'Id': Instance_ID
            
        },
    ]
    )

    
    #===Checking the exit status of the deregistration
    Elbderegistering=response['ResponseMetadata']['HTTPStatusCode']
    print(Elbderegistering)
    if Elbderegistering == 200:
        print('Instance was completely deregistered from ELB with status code:',status_code)
        print('Remediaition Process complete. All Job done !!!!')
    else:
         print('Deregistration of Instance from ELB failed with status code:',status_code)
         print('Deregisteration of the compromised instance failed.')
         
         







if __name__ == "__main__":
    # Hardcoded test JSON event
    event = {
        "Findings": [
            {
                "Resource": {
                    "InstanceId": "i-0e39d12c963adcc06",
                    "InstanceState": "running"
                }
            }
        ]
    }

    remediationaction(event)
    
    
    
    
