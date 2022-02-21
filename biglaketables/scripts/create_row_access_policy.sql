CREATE ROW ACCESS POLICY only_aa_filter
ON bigtable_demo.flights
GRANT TO ("user:user@abc.com")
FILTER USING (airline = "AA")