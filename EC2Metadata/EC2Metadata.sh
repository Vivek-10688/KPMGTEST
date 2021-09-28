#!/bin/bash
function print_help() {
    echo "Usage: ec2-metadata <option>
Options:
--all                     Show all metadata information for current host.
-a/--ami-id               The AMI ID of current instance
-b/--block-device-mapping Show Virtual Devices.
-i/--instance-id          The ID of this instance
-t/--instance-type        The type of instance to launch.
-h/--local-hostname       The local hostname of the instance.
-o/--local-ipv4           Public / Private IP.
-z/--availability-zone    The Availability Zone Information Of Current Instance.
-p/--public-hostname      The Public Hostname Of The Instance.
-v/--public-ipv4          Public IP Address
-s/--security-groups      Security Groups Information Of Current Instance
-d/--user-data            User-Data Information Of Current Instance."
}

#check some basic configurations before running the code
function chk_config() {
    #check if run inside an ec2-instance
    x=$(curl -s http://169.254.169.254/)
    if [ $? -gt 0 ]; then
        echo '[ERROR] Command Not Valid Outside Of EC2 instance. Please Run This Command Within A Running EC2 Instance.'
        exit 1
    fi
}

#print standard metric
function print_normal_metric() {
    metric_path=$2
    echo -n $1": "
    RESPONSE=$(curl -fs http://169.254.169.254/latest/${metric_path}/)
    if [ $? == 0 ]; then
        echo $RESPONSE
    else
        echo not available
    fi
}

#print block-device-mapping
function print_block-device-mapping() {
    echo 'block-device-mapping: '
    x=$(curl -fs http://169.254.169.254/latest/meta-data/block-device-mapping/)
    if [ $? -eq 0 ]; then
        for i in $x; do
            echo -e '\t' $i: $(curl -s http://169.254.169.254/latest/meta-data/block-device-mapping/$i)
        done
    else
        echo not available
    fi
}

function print_all() {
    print_normal_metric ami-id meta-data/ami-id
    print_block-device-mapping
    print_normal_metric instance-id meta-data/instance-id
    print_normal_metric instance-type meta-data/instance-type
    print_normal_metric local-hostname meta-data/local-hostname
    print_normal_metric local-ipv4 meta-data/local-ipv4
    print_normal_metric placement meta-data/placement/availability-zone
    print_normal_metric public-hostname meta-data/public-hostname
    print_normal_metric public-ipv4 meta-data/public-ipv4
    print_normal_metric security-groups meta-data/security-groups
    print_normal_metric user-data user-data
}

#check if run inside an EC2 instance
chk_config

#command called in default mode
if [ "$#" -eq 0 ]; then
    print_all
fi

#start processing command line arguments
while [ "$1" != "" ]; do
    case $1 in
    -a | --ami-id)
        print_normal_metric ami-id meta-data/ami-id
        ;;
    -b | --block-device-mapping)
        print_block-device-mapping
        ;;
    -i | --instance-id)
        print_normal_metric instance-id meta-data/instance-id
        ;;
    -t | --instance-type)
        print_normal_metric instance-type meta-data/instance-type
        ;;
    -h | --local-hostname)
        print_normal_metric local-hostname meta-data/local-hostname
        ;;
    -o | --local-ipv4)
        print_normal_metric local-ipv4 meta-data/local-ipv4
        ;;
    -z | --availability-zone)
        print_normal_metric placement meta-data/placement/availability-zone
        ;;
    -p | --public-hostname)
        print_normal_metric public-hostname meta-data/public-hostname
        ;;
    -v | --public-ipv4)
        print_normal_metric public-ipv4 meta-data/public-ipv4
        ;;
    -r | --ramdisk-id)
        print_normal_metric ramdisk-id /meta-data/ramdisk-id
        ;;
    -s | --security-groups)
        print_normal_metric security-groups meta-data/security-groups
        ;;
    -d | --user-data)
        print_normal_metric user-data user-data
        ;;
    -h | --help)
        print_help
        exit
        ;;
    --all)
        print_all
        exit
        ;;
    *)
        print_help
        exit 1
        ;;
    esac
    shift
done
