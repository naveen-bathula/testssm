if [ -z $1 ]; then
    echo -e "\nPlease call '$0 <Userid> <AWS_Account>' to run this command!\n"
    exit 1 
fi
if [ -z $2 ]; then
    echo -e "\nPlease call '$0 <Userid> <AWS_Account>' to run this command!\n"
    exit 1
fi
sudo useradd -m -s /bin/bash $1-workspace
if [ $? != 0 ]
then
    echo "Failed"
    exit 1
fi
cp /home/ubuntu/.ssh/authorized_keys /tmp/
if [ $? != 0 ]
then
    echo "Failed"
    exit 1
fi
chmod a+r /tmp/authorized_keys
sudo su {{UserName}}-workspace <<EOF
cd 
mkdir /home/{{UserName}}-workspace/.ssh/ && cp /tmp/authorized_keys /home/{{UserName}}-workspace/.ssh/
chmod 0600 /home/{{UserName}}-workspace/.ssh/authorized_keys
mkdir .aws && cp -r /home/occ-covid19/.aws/config /home/{{UserName}}-workspace/.aws/config
cat >> /home/{{UserName}}-workspace/.bashrc << EOF1
export vpc_name={{UserName}}
export s3_bucket='kube-{{UserName}}-gen3'
export KUBECONFIG='/home/{{UserName}}-workspace/Gen3Secrets/kubeconfig'
export http_proxy='http://cloud-proxy.internal.io:3128'
export https_proxy='http://cloud-proxy.internal.io:3128'
export no_proxy='localhost,127.0.0.1,localaddress,169.254.169.254,.internal.io,s3.us-east-1.amazonaws.com,logs.us-east-1.amazonaws.com'
EOF1
source /home/{{UserName}}-workspace/.bashrc
cd
export KUBECONFIG='/home/{{UserName}}-workspace/Gen3Secrets/kubeconfig'
export http_proxy='http://cloud-proxy.internal.io:3128'
export https_proxy='http://cloud-proxy.internal.io:3128'
export no_proxy='localhost,127.0.0.1,localaddress,169.254.169.254,.internal.io,s3.us-east-1.amazonaws.com,logs.us-east-1.amazonaws.com'
git clone --quiet https://github.com/uc-cdis/cloud-automation.git
cat >> /home/{{UserName}}-workspace/.bashrc << EOF2
export GEN3_HOME="/home/{{UserName}}-workspace/cloud-automation"
if [ -f /home/{{UserName}}-workspace/cloud-automation/gen3/gen3setup.sh ]; then
source /home/{{UserName}}-workspace/cloud-automation/gen3/gen3setup.sh
else
echo "Gen3 Home Setup sourcing failed."
fi
alias kubectl=g3kubectl
if which kubectl > /dev/null 2>&1; then
# Load the kubectl completion code for bash into the current shell
source <(kubectl completion bash)
else 
echo "Kubectl Bash Completion Setup Failed."
fi
complete -C '/usr/local/bin/aws_completer' aws
EOF2
source /home/{{UserName}}-workspace/.bashrc #there is an error which needs to be fixed for this to work.
cat >> /home/{{UserName}}-workspace/.aws/config << EOF3
[profile {{UserName}}]
output = json
region = us-east-1
role_session_name = gen3-adminvm
role_arn = arn:aws:iam::{{AccountID}}:role/OrganizationAccountAccessRole
credential_source = Ec2InstanceMetadata
EOF3
EOF
