CREATE EXTERNAL TABLE `bq-testbed-20190.bigtable_demo.flights`
WITH CONNECTION `bq-testbed-20190.us.my-connection`
OPTIONS(uris=["gs://bigtabledemo-2def83c9-18ba-f220-0d22-47ac6301123e/airlines_data.csv"], format="CSV")