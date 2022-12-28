# docker-nat-net script

Script to create iptables NAT rules to change output IP of docker bridge subnet.

*/etc/docker-nat-net.ini*

```ini
br-proxy,192.168.10.11
br-web,192.168.10.12
br-media,192.168.10.13
```
