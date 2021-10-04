# `download_debian_keyring.sh`

## Disclaimer

**Never use the downloaded keyring blindly!**

This script downloads the public GPG keys that are used to sign the specified APT repository.
It does not guarantee that the repository found under the used URL has not been tampered with!

You should always verify the fingerprints of the downloaded keys with the fingerprints published by the owner of the repository.

## Problem

To verify APT-repositories (e.g. Debian, Ubuntu), orcharhino needs the respective Archive-Keyring.
These usually change between releases and include more than one GPG key.

This script looks at the signed `InRelease` file of the APT repository and downloads all the keys used to sign it from a keyserver.

## Script usage

Without parameters, the script will download all the keys for the latest Debian `stable` release.
The resulting GPG keyfile is sent to stdout.
Use a redirect to put it into a file:

    ./download_debian_keyring.sh > debian_stable_keyring.asc

To download a specific Debian release, specify its codename as the first parameter.

    ./download_debian_keyring.sh bullseye

Ubuntu or other APT based repositories' signing keys can be downloaded by specifying the base-url (as it is specified in the `/etc/apt/sources.list`) as a second parameter.
For instance to download the signing keys for the Ubuntu focal release use:

    ./download_debian_keyring.sh focal http://archive.ubuntu.com/ubuntu


### Verify fingerprints

As mentioned before, (manually) verifying the authenticity of the downloaded keys is an important part of the workflow.
The easiest way to do this is to check the fingerprints of the downloaded keys with the fingerprints published by the original authors.

For Debian Security repository, you could do the following:

    # download the keys
    ./download_debian_keyring.sh bullseye-security http://security.debian.org/debian > keyring.asc

    # display fingerprints
    gpg --show-keys keyring.asc
    
Now you have to find a second, trustworthy source for the fingerprints.
For Debian-Security, this could be the official keylist: <https://ftp-master.debian.org/keys.html>
