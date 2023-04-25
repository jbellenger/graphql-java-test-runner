# At the time this dockerfile was created, superset didn't have official tagged releases.
# We use a fresh-ish git-sha for stability. We should periodically update this sha as needed.
# FROM apache/superset:4b3e507e8b22b2d25e9a79c1feb03fceaefbd464
FROM apache/superset
# Switching to root to install the required packages
USER root
# Example: installing the MySQL driver to connect to the metadata database
# if you prefer Postgres, you may want to use `psycopg2-binary` instead
RUN pip install mysqlclient
# Example: installing a driver to connect to Redshift
# Find which driver you need based on the analytics database
# you want to connect to here:
# https://superset.apache.org/installation.html#database-dependencies
RUN pip install sqlalchemy-bigquery
# Switching back to using the `superset` user
USER superset


