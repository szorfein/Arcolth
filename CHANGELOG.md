## Release 2022.09.23
* Add Brave browser.
* Add ruby gems [spior](https://github.com/szorfein/spior) and [getch](https://github.com/szorfein/getch).
* Redirect local traffic through Tor with Iptables (ipv6 disabled), can be disable with `spior --clearnet`.
* Anonymize the machine-id, use the one from [Whonix](https://github.com/Whonix/dist-base-files/blob/master/etc/machine-id).
* Anonymize the hostname set to `host`.
* Anonymize the localtime set to `UTC`.
* Mac Address Spoofing (by `NIC`).
