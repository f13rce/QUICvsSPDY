#!/bin/bash

sudo tcpdump -w /home/f13rce/net.pcap -i xenbr0 port '(80 or 443 or 6121)'
