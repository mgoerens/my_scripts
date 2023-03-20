# Stop and rm crc

```
crc stop
crc remove
```

# Download latest

```
wget https://developers.redhat.com/content-gateway/file/pub/openshift-v4/clients/crc/2.15.0/crc-linux-amd64.tar.xz
xz -d crc-linux-amd64.tar.xz
tar -xvf crc-linux-amd64.tar
mv crc-linux-2.15.0-amd64/crc ~/bin/crc 
rm crc-linux-amd64.tar 
rm crc-linux-2.15.0-amd64/ -rf
```

# clean old

```
rm /home/mgoerens/.crc/cache/crc_libvirt_4.11.13_amd64.crcbundle
rm /home/mgoerens/.crc/cache/crc_libvirt_4.11.13_amd64 -rf
```

# Setup

```
crc setup
crc start -p ~/.crc/mgoerens_pullsecret 
```

