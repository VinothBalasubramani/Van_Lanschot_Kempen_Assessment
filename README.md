# STRADA Downstream – Starter IaC v3

Adds:
- Private DNS for blob/dfs/queue/table + sql + keyvault
- Storage PEs for blob/dfs/queue/table
- ADF Managed VNet + Managed Private Endpoints to Storage/SQL/KV
- ADF linked services (Databricks, SQL, Storage), datasets (binary + sql table), pipeline JSON (Databricks notebook -> SQL sproc)
- Optional Policy module (disabled by default)

Update placeholders (subscription IDs, Databricks URL/IDs, Entra group object IDs) before running.
