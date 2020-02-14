# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

 - [ ] Test job servers
 - [ ] Test LDAP server 
 - [ ] Add Network Architecture Diagram
 - [ ] Add PostgreSQL cluster
 - [ ] Configurable Hostname
 - [ ] Run on AWS
 - [ ] Add `mitmproxy` w/ `har_dump.py` and `tcpdump` to log traffic

## v0.0.2 - 2020-02-14 (prerelease)
### Fixed:
 - Calling the master setup script helps...
 - Now using passed MySQL root password in master_setup.sh

## v0.0.1 - 2020-02-10 (prerelease)
### Added:
 - [x] Set Environment Variables
 - [x] Auto-config the DB
 - [x] Switch from SMB to NFS
 - [x] Add HAProxy w/ stats