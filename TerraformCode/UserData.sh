#!/bin/bash

# HTTPD Installtion
sudo yum install -y httpd
sudo systemctl start httpd.service
sudo systemctl enable httpd.service