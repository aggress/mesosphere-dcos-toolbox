
# SMACK Stack Installer For DC/OS

Semi-automated installation of big data frameworks for DC/OS.

## Introduction

I needed to automate the installation of Confluent Platform with Kerberos and TLS for repeatable testing.

That began as a 100 line shell script, and I said to myself, once this works as a prototype, I'll rebuild in Ansible.

500 lines of shell script later.. drowning in fragile conditionals with poor validation, I scrapped it and rewrote in Ansible.

Which I should have done from the very start. So here we are.

## Features

- Deploys Confluent Platform
- Supports distinct naming of services for multi-tenancy
- Support for all DC/OS security modes
- Support for TLS and Kerberos
- Deployment of an Active Directory server on AWS for testing Kerberos integration
- Generated batch script to configured AD users, principals and keytabs
- Generated templates for JSON options file for services
- Makefile support (thank you for the tip @jrx)

## Planned Features

- Folder support
- Configurable resources for JSON options
- Janitor automation
- Deployment for all big data components on DC/OS. I will haz all the things.
- MIT Kerberos deployment as well as Active Directory
- End to end client testing - reading and writing data
- Standalone monitoring deployment integrated with dcos-metrics

## Design

Three stage design

- Parameters: Configure parameters for the cluster you're going to deploy
- Setup: Generate the JSON options and any AD configuration
- Deploy: Deploy the service

Ansible does the heavy lifting and talks over localhost directly to the DC/OS CLI which then deploys frameworks. Really, all this is doing is automating all the steps you'd need to perform manually.

## Tooling

- Ansible <3
- aws-shell
- DC/OS CLI

## Setup

Instructions below are for macOS. 

### Ansible
```
$ brew install ansible
```

### AWS shell

If you want to launch the AD server programmatically
```
$ brew install awscli
```

Add your AWS secret and key with `$ aws configure` or edit the `~/aws/credentials` directly

### Python modules for some of the more esoteric Ansible activities

If you're using brew, you may have multiple versions of Python on your system in different locations.
Ansible calls `/usr/bin/python`, so any required modules need to be installed in its context.
Why the strange param when installing boto3? https://github.com/PokemonGoF/PokemonGo-Bot/issues/245.
..Working through all the **** so you don't have to.
```
$ sudo /usr/bin/python -m easy_install pip
$ sudo /usr/bin/python -m pip install boto3 --ignore-installed six
$ sudo /usr/bin/python -m pip install boto
$ sudo /usr/bin/python -m pip install cryptography
```
## DC/OS CLI

https://docs.mesosphere.com/1.10/cli/install/#manually-installing-the-cli


## Usage

Checkout this repository 
```
$ git clone @github.com:aggress/mesosphere-dcos-toolbox.git
```
Change to the project directory
```
$ cd mesosphere-dcos-toolbox/ansible/smack_installer
```
Edit `group_vars/all` this contains a list of configuration options you must review

Edit the framework configuration section as it applies to what you deploy and the AD section if you need it for testing

Configure the DC/OS cli to attach to your target cluster 
```
$ dcos cluster setup --insecure <master_ip> --username=<username> --password=<password>
```
Test the DC/OS cli `dcos node`

Run `$ make` with no options to review the options

Run `$ make` with the option you want i.e. `$ make deploy_beta_cp_zk`

Watch Ansible do its magic

## Todo

- Docs for AD testing
- All the other things

