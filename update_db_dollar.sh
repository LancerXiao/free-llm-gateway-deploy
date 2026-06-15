#!/bin/bash
# Generate SQL file with dollar-quoting to avoid quote escaping issues
export PGPASSWORD=cM5DxLwTufauqLTx30TezLKW

# Write SQL using dollar-quoting
echo "UPDATE options SET value=\$about\$" > /tmp/update_about.sql
cat /tmp/about_v4.html >> /tmp/update_about.sql
echo "\$about\$ WHERE key='About';" >> /tmp/update_about.sql
echo "SELECT length(value) FROM options WHERE key='About';" >> /tmp/update_about.sql

# Execute
psql -h 172.17.0.1 -U newapi -d newapi -f /tmp/update_about.sql
