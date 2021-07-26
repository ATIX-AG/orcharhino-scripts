# `find_missing_candlepin_product_contents.rb`

## Problem

It sometimes happens that association between a Product and Content is lost in
candlepin.
This results in Entitlement-certificates being generated that do not include
the content repository.

This can be determined by looking closer at the entitlement-certificate using
the `rct`-tool:

    rct cat-cert <entitlement-cert>

## Script usage

Running the script without any parameters on the command line analyzes
the candlepin-database and compares it to the content of the katello-database.
If missing connections are found, the script will write SQL-INSERT commands
on STDOUT that recreate the associations.

Adding `--repair` will automatically apply the SQL-INSERTs to solve the problem
in the candlepin-database.

After fixing the database, restart candlepin (tomcat.service) and run
`subscription-manager refresh` on the hosts where the problem has occured.
