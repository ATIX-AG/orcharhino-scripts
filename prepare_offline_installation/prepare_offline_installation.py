#!/usr/bin/env python3

# simplify your orcharhino Server offline installation by generating commands based on a list of repositories

import sys

###################################################################
# adapt list of repositories
repositories = [
    "Insert list from ATIX Service Portal:",
    "https://atixservice.zendesk.com/hc/de/articles/4414413251346",
]
###################################################################

bash_preamble = """#!/bin/bash
set -e

"""
repo_path = sys.argv[1]

# create repo file
repo_file = "/tmp/orcharhino.repo"
repo_file_content = ""
skeleton = """
[REPO_ID]
name=REPO_ID
baseurl=file://REPO_PATH
enabled=1
gpgcheck=0
"""
for repository in repositories:
    repo_file_content += skeleton.replace("REPO_ID", repository).replace("REPO_PATH", repo_path + repository)
with open(repo_file, "w") as f:
    f.write(repo_file_content)

# create bash script to enable repositories
enable_repos_content = ""
enable_repos_file = "/tmp/enable_repositories.sh"
for repository in repositories:
    enable_repos_content += "subscription-manager repos --enable=" + repository + "\n"
with open(enable_repos_file, "w") as f:
    f.write(bash_preamble)
    f.write(enable_repos_content)

# create bash script to synchronize repositories
sync_repos_content = ""
sync_repos_file = "/tmp/synchronize_repositories.sh"
for repository in repositories:
    sync_repos_content += "reposync -l -m --repoid=" + repository + " --download-metadata --download_path=" + repo_path + "\n"
with open(sync_repos_file, "w") as f:
    f.write(bash_preamble)
    f.write(sync_repos_content)

# create bash script to create file repositories
file_repos_content = ""
file_repos_file = "/tmp/create_file_repositories.sh"
for repository in repositories:
    file_repos_content += "cd " + repo_path + repository + " && createrepo -v " + repo_path + repository + " -g comps.xml" + "\n"
with open(file_repos_file, "w") as f:
    f.write(bash_preamble)
    f.write(file_repos_content)
