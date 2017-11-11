# Vault Setup
## Intro and Purpose
The purpose of this project is to allow someone to have a complete vault setup starting from nothing. And, maybe, so someone else doesn't have to go through the hassle that I went through trying to figure out exactly how to do this.

## What is Vault?
Vault is an open source secrets management tool developed by Hashicorp. You can find more information here: https://www.vaultproject.io/

## Acknowledgements
There were a couple of valuable resources I used while working on this project:  
* [Hashicorp](https://www.hashicorp.com/) provided a [quickstart template](https://aws.amazon.com/quickstart/architecture/vault/) that provided a good starting point for this project.
* The front end uses [Vault-UI](https://github.com/djenriquez/vault-ui) by DJ Enrequez.

## Prerequisites
There are a few things you'll to setup a vault server for yourself.
1. A free account with [CircleCI](https://circleci.com/). I recommend attaching your github account. This will allow CircleCI to build your github repositories.
1. An AWS account here https://aws.amazon.com/. This is where the vault server will be hosted.  
You will also need the following services on AWS
* An IAM user with enough permissions to deploy all of the services. (Services > Security, Identity & Compliance > IAM > Users)
* An access key for the IAM user. (Make sure to note down the secret key, you won't be able to retrieve it again)
* A DNS Hosted Zone (Services > Networking & Content Delivery > Route 53)
* A wildstar SSL certificate for the domain you intend to use (Services > Security, Identity & Compliance > Certificate Manager)
* A key pair (Services > Compute > EC2 > Network & Security > Key Pairs)
* An S3 bucket (Services > Storage > S3). This bucket will be used to manage the state of your setup.   
Note: When you create a key pair, a file will be downloaded to your computer. **Do not lose this file. You will need it to set up the vault server and you will not be able to download it again.**

## Initial Setup
1. Fork this repository into one of your own
1. Sign into [CircleCI](https://circleci.com), and give it what ever permissions it asks for github.
1. If this is your first time logging into CircleCI, you will be presented with a list of repositories from your github account. Make sure only `vault-setup` is checked before continuing.  
CircleCI will now start building the vault-setup repository. Initially, though, it will only run a linter to validate.

## Before Continuing
If you're setting this up for your own personal use, this will work as is. The UI and API end points will be accessable from anywhere. However, if you have more stringent security requirements, access can be locked down.  
In the file `securitygroups/vars.tf` is an entry for setting up a white list. Replace the existing array with an array of IP ranges you want to restrict access to.

## Setup CircleCI
* In CircleCI, click on the `Projects` tab. Then click the `Settings` icon to the right of the `vault-setup` project.
* Under `Permissions` click on `AWS Permissions`, then enter in the access and secret key you created in the prerequisite section above.
* Under `Build Settings` click on `Environment Variables`. Add the environment variables listed below.  

There are quite a few environment variables that will need to be set. This will set the build up to work specifically for your setup.  
NOTE: for the environment variables that end with `_state_key` you can use the value I provide, unless you understand terraform state.
### Environment Variables
**TF_VAR_aws_region**: The region where you want the server deployed (example: `us-west-1`)   
**TF_VAR_availability_zone**: A single availability zone in the region. This is where the subnets will be deployed. (example: `us-west-1a`)  
**TF_VAR_prefix**: A unique prefixed used for a number of resources. This is for quickly identifying the resources used for vault, if you have several other projects in the same region  
**TF_VAR_aws_key_pair_name**: The name of the key pair you created in the prerequesits above.  
**TF_VAR_dns_zone_id**: The id of the DNS hosted zone you plan to use. (Services > Route 53 > Hosted Zones) The ID will be on the far right.  
**TF_VAR_root_domain**: The root domain associated with the hosted zone. (example: `mydomain.com`)  
**TF_VAR_server_subdomain**: The subdomain of the API endpoint for the vault server. If, for example, you want the vault API to be at `api.mydomain.com` you would only enter `api` here.  
**TF_VAR_ui_subdomain**: The subdomain you want to use for the front end. If, for example, you want the front end to be at `ui.mydomain.com` you would only enter `ui` here.  
**TF_VAR_ssl_certificate**: The ARN of the wildcard SSL cert for the domain. (Services > Security, Identity & Compliance > Certificate Manager). Select the certificate and copy the entire ARN from the `Details` section  
**TF_VAR_vault_bucket**: A name for the storage the vault server will use. This will primarily be used internally and needs to be unique across all of AWS, so use something random. (example: `vault-6750306882b3`)   
**TF_VAR_server_tag**: A tag for the server image. (example: `vault-server-ami`)  
**TF_VAR_ui_tag**: A tag for the UI image. (example: `vault-ui-ami`)  
**TF_VAR_tfstate_bucket_name**: The name of the S3 Bucket you created as part of the prerequisites.  
**TF_VAR_jumpbox_state_key**: `vault/jumpbox/terraform.state`  
**TF_VAR_security_groups_state_key**: `vault/securitygroups/terraform.state`  
**TF_VAR_server_state_key**: `vault/server/terraform.state`  
**TF_VAR_storage_state_key**: `vault/storage/terraform.state`  
**TF_VAR_ui_state_key**: `vault/ui/terraform.state`  
**TF_VAR_vpc_state_key**: `vault/vpc/terraform.state`  

# Starting the Build
* In the `vault-setup` repository on github, create a new branch called `full-deploy`. This will automatically start a build.  
* In CircleCI click on `Workflows` then look for a workflow called `full-deply/full-deployment` and click on that to watch the build. The build should take about five minutes for a public repository, or fifteen minutes for a private one.  
* Once the build has succeeded, click on the node labelled `build_jumpbox`
* Expand the section labelled `Deploy Jumpbox` and scroll all the way to the bottom.
* The last line will say `jumpbox_ip = <some IP address>`. Make a note of the IP address (this is the address you'll SSH into for managing the service).

# Post Setup Steps
NOTE: these instructions are for Mac and Linux. I've never done this on Windows, but I understand it's a little more involved.  
* In a terminal, change to the directory where you saved the file from the key pair you created as part of the prerequisites.
* Enter the following in the terminal:  
```
chmod 700 <mykeypairfile>
ssh-add <mykeypairfile>
ssh -A -i <mykeypairfile> ubuntu@<jumpbox ip>
```  
* If asked if you want to add this IP address, type in `yes` and hit enter.
* In AWS, locate the vault server (Services > Compute > EC2 > Instances). This will be labelled as `<prefix>-private-server`. Select this instance.
* In the details panel, note the private IP address
* In the terminal that is logged into the jumpbox, enter the following:
```
ssh ubuntu@<private server ip>
```
* Again, enter `yes` if you're asked to add the IP address.
* Enter the following into the terminal:
```
export VAULT_ADDR='http://localhost:8200'
vault init
```
The terminal will display 5 keys and a root token  
**!!!Warning!!!  
This is the only time you will be shown this information  
DO NOT lose this information  
Store this information some place secure**  
* Enter the following into the terminal three times - using three of the five keys from the last step:
```
vault unseal <key>
```  
Your vault server is now setup

## Next Steps
* In a web browser go to the URL you selected for the ui (be sure to start the address with `https://`)
* Click the settings icon on the right (the gear icon)
* Select `Token` as the login method and click `Submit`
* Enter the root token you got from the `init` step above, and click `Login`.
* You are now ready to start managing your vault.
* Check the [Vault Documentation](https://www.vaultproject.io/docs/index.html) and [Vault-UI](https://github.com/djenriquez/vault-ui)
