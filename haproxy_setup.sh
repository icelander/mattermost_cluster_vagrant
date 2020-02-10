#!/bin/bash

apt-get -y install haproxy
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.orig.cfg
cp /vagrant/haproxy.cfg /etc/haproxy/haproxy.cfg

service haproxy start