![Rubocop](https://github.com/ATIX-AG/orcharhino-scripts/actions/workflows/ruby.yml/badge.svg)

# orcharhino-scripts

Utility scripts for the orcharhino-server.
Might also work on foreman-/katello-servers.

[orcharhino](https://orcharhino.com/en/) by [ATIX AG](https://atix.de/en/)


## Use at your own risk
We try to consider all possible side-effects, while writing these scripts.
Errors are always an option, though.
So please follow these rules:

1) Create snapshots and/or backups of your system before running scripts that actively change data.
1) Read the script's documentation (README.md and/or run the script with `--help`), first.

If an error occurs, please report it here or even better fix it and create a new PR (see [Contribute](README.md#Contribute)).


# Scripts
See README.md in the respective folders for more information about usage and applicablility of a certain script.

* [`find_missing_candlepin_product_contents.rb`](find_missing_candlepin_product_contents/README.md) (see [1931027](https://bugzilla.redhat.com/show_bug.cgi?id=1931027))
* [`download_debian_keyring.sh`](download_debian_keyring/README.md) (see [Content Menu > Content Credentials](https://docs.orcharhino.com/or/docs/sources/management_ui/the_content_menu/content_credentials.html))


# Contribute
Feel free to adapt these scripts to your personal needs.
But please also consider creating PRs here so the scripts here may become more versatile.
