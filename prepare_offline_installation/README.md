# `prepare_orcharhino_offline_installation.py`

## Problem

To install orcharhino Server in a disconnected network environment, you need to synchronize all necessary repositories from ATIX first and provide them as file-repositories.
The list of repository URLs depends on your operating system.

## Solution

Run a small python script to generate a list of commands based on a list of repositories.

    # ./prepare_offline_installation/prepare_offline_installation.py /media/my_disk/my_repos/
