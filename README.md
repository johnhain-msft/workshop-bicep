# Azure AI Foundry Workshop — Bicep Deployment

Infrastructure-as-Code (Bicep) templates that deploy a complete **Azure AI Foundry workshop environment** using the Azure Developer CLI (`azd`). This deployment provisions all required Azure resources, model deployments, networking, monitoring, and RBAC assignments in a single resource group.

---

## What's Included

### Azure Resources

| Resource | Description |
|----------|-------------|
| **Azure AI Foundry Account** | Cognitive Services account (`AIServices` kind) with a user-assigned managed identity |
| **Model Deployments** | `gpt-4o`, `gpt-5.2-chat`, `gpt-5.1-chat`, `gpt-5-mini`, `text-embedding-3-large` (GlobalStandard SKU) |
| **AI Foundry Projects** | N participant projects + 1 trainer project (N+1 total), each with system-assigned managed identity and Capability Hosts for Agents |
| **Azure API Management** | AI Gateway with per-project managed identity auth, rate limiting, token metrics, and Application Insights logging |
| **Azure AI Search** | Standard-tier search service with semantic search (free tier), system-assigned managed identity, and shared private link resources to Foundry and Storage |
| **Azure Storage Account** | Standard LRS, shared-key access disabled, with a `data` blob container for PDF documents |
| **Container Apps Environment + App** | Runs a Python-based MCP (Model Context Protocol) server, exposed through APIM |
| **Monitoring** | Log Analytics Workspace, Application Insights, APIM Token Usage Dashboard, and Workbook |
| **Bing Grounding** | Bing Search connection at the Foundry account level |
| **Networking** | Private endpoint module; shared private links from AI Search → Foundry and AI Search → Storage |

### Post-Provisioning Scripts

Located in `foundry-workshop/scripts/`:

- **`create_index.py`** — Creates a vector + semantic search index in AI Search
- **`create_simple_index.py`** — Creates a simple keyword search index
- **`setup_indexer_pipeline.py`** — Configures an indexer pipeline for document ingestion
- **`agents_v1/create_agents_v1.py`** — Creates AI agents using the v1 SDK
- **`agents_v2/create_agents_v2.py`** — Creates AI agents using the v2 SDK
- **`pdfs/`** — Sample PDF documents for indexing

---

## RBAC Role Assignments

The deployment configures fine-grained, least-privilege RBAC. Assignments fall into three categories: **workshop participant access**, **deployer access**, and **service-to-service identity grants**.

### Workshop Participant Group Assignments

These roles are assigned to an **Entra ID security group** (provided via the `groupPrincipalId` parameter). They are conditionally applied — only created when a group principal ID is supplied.

| Role | Scope | Purpose |
|------|-------|---------|
| **Reader** (`acdd72a7-3385-48ef-bd42-f606fba81ae7`) | Resource Group | Allows participants to view all resources in the workshop resource group |
| **Azure AI User** (`53ca6127-db72-4b80-b1b0-d745d6d5456d`) | Each AI Foundry Project (×N+1, including trainer) | Allows participants to use their assigned AI Foundry project |
| **Azure AI Account Owner** (`e47c6f54-e4a2-4754-9501-8e0985b135e1`) | AI Foundry Account | Grants participants ownership-level access to the AI Foundry account |
| **Storage Blob Data Contributor** | Storage Account | Allows participants to read/write blob data for document uploads |
| **Search Service Contributor** | AI Search Service | Allows participants to manage the search service configuration |
| **Search Index Data Contributor** | AI Search Service | Allows participants to read/write data within search indexes |

### Deployer Assignments

These roles are assigned to the **deploying user** (provided via the `deployerPrincipalId` parameter). They are conditionally applied — only created when a deployer principal ID is supplied.

| Role | Scope | Purpose |
|------|-------|---------|
| **Storage Blob Data Contributor** | Storage Account | Allows the deployer to upload documents and manage blob data |
| **Search Service Contributor** | AI Search Service | Allows the deployer to configure the search service post-deployment |
| **Search Index Data Contributor** | AI Search Service | Allows the deployer to create indexes and load data into AI Search |

### Service-to-Service Identity Assignments

These roles are **always created** and grant managed identities the minimum permissions needed for cross-service communication.

| Role | Principal | Scope | Purpose |
|------|-----------|-------|---------|
| **Cognitive Services User** (`a97b65f3-24c7-4388-baec-2e87135dc908`) | APIM system-assigned MI | AI Foundry Account | Allows the API Management gateway to call AI Foundry models |
| **Storage Blob Data Contributor** (`ba92f5b4-2d11-453d-a403-e96b0029c9fe`) | AI Search system-assigned MI | Storage Account | Allows AI Search to read blobs for indexer-based document ingestion |
| **Search Index Data Contributor** (`8ebe5a00-799e-43f5-93ac-243d3dce84a7`) | Each AI Foundry Project MI (×N+1) | AI Search Service | Allows each project's agents to query and write to search indexes |
| **Search Service Contributor** (`7ca78c08-252a-4471-8644-bb5ff32d4ba0`) | Each AI Foundry Project MI (×N+1) | AI Search Service | Allows each project's agents to manage search service resources |
| **Cognitive Services User** (`a97b65f3-24c7-4388-baec-2e87135dc908`) | AI Search system-assigned MI | AI Foundry Account | Allows AI Search to call Foundry for integrated vectorization skillsets |
| **Cognitive Services OpenAI User** (`5e0bd9bd-7b93-4f28-af87-19fc36ad61bd`) | AI Search system-assigned MI | AI Foundry Account | Allows AI Search to invoke OpenAI embedding models for vectorization |

### Conditional Assignments (Not Triggered by Default)

The following role assignments exist in the modules but are **not activated** in the default deployment configuration:

| Role | Principal | Scope | Condition |
|------|-----------|-------|-----------|
| **Monitoring Metrics Publisher** (`3913510d-42f4-4e42-8a64-420c390055eb`) | Foundry user-assigned MI | Application Insights | Only if `managedIdentityResourceId` is provided to the monitoring module and not using an existing App Insights instance |
| **Key Vault Secrets Officer** (`b86a8fe4-44ce-4948-aee5-eccb2c155cd7`) | Foundry MI | Key Vault | Only if `keyVaultResourceId` and `keyVaultConnectionEnabled` are set |

---

## Repository Structure

```
├── foundry-workshop/           # Deployment root (azd entrypoint)
│   ├── main.bicep              # Top-level orchestrator
│   ├── main.bicepparam         # Parameter file
│   ├── workshop_search.bicep   # Search, Storage, and RBAC orchestrator
│   ├── workshop_mcp.bicep      # MCP server + Container Apps orchestrator
│   ├── azure.yaml              # Azure Developer CLI configuration
│   ├── bicepconfig.json        # Bicep linter/module configuration
│   └── scripts/                # Post-provisioning scripts and sample data
│       ├── create_index.py
│       ├── create_simple_index.py
│       ├── setup_indexer_pipeline.py
│       ├── pdfs/               # Sample PDF documents
│       ├── agents_v1/          # Agent creation (v1 SDK)
│       └── agents_v2/          # Agent creation (v2 SDK)
└── modules/                    # Reusable Bicep modules
    ├── ai/                     # AI Foundry account, projects, connections
    ├── apim/                   # API Management gateway and policies
    │   ├── v2/                 # APIM v2 inference API variant
    │   └── apim-streamable-mcp/ # Streamable MCP server API
    ├── aca/                    # Container Apps environment and app
    ├── iam/                    # Identity and role assignment modules
    ├── kv/                     # Key Vault role assignments
    ├── monitor/                # Log Analytics and Application Insights
    ├── dashboard/              # APIM monitoring dashboard and workbook
    ├── networking/             # Private endpoint module
    ├── bing/                   # Bing Grounding connection
    └── types/                  # Shared Bicep type definitions
```

---

## Prerequisites

- [Azure Developer CLI (`azd`)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
- [Bicep CLI](https://learn.microsoft.com/azure/azure-resource-manager/bicep/install)
- An Azure subscription with sufficient quota for the specified model deployments
- [uv](https://docs.astral.sh/uv/) for running the post-provisioning Python scripts
- (Optional - but Recommended) An Entra ID security group for workshop participants
---

## Deployment

### Required Parameters

Before deploying, configure the following `azd` environment variables before running `azd up`. At minimum you must set `PROJECTS_COUNT`:

| Variable | Required | Description |
|----------|----------|-------------|
| `PROJECTS_COUNT` | **Yes** | Number of participant projects to create (e.g., `5` for 5 participants). Each project gets its own AI Foundry project and Capability Host. A trainer project is always added automatically (N+1 total). |
| `AZURE_GROUP_PRINCIPAL_ID` | Recommended | Object ID of the Entra ID security group containing workshop participants. Enables all participant RBAC assignments (Reader, AI User, Storage, Search). Omit if you don't need group-based access. |
| `STUDENTS_INITIALS` | Optional | Comma-separated list of student initials for human-readable project names (e.g., `"jsa,adb,mba"`). If provided, the count **must** match `PROJECTS_COUNT` exactly. When omitted, projects are numbered sequentially. |
| `SUBNET_FOR_STORAGE_PE_RESOURCE_ID` | Optional | Resource ID of the subnet to use for the storage account private endpoint. If not provided, the storage account is deployed without a private endpoint and with public network access enabled. |
| `BLOB_PRIVATE_DNS_ZONE_RESOURCE_ID` | Optional | Resource ID of the private DNS zone for the storage account blob endpoint (`privatelink.blob.core.windows.net`). When provided, DNS configuration is added for the private endpoint. |

These variables are read in `main.bicepparam` and forwarded to the corresponding Bicep parameters (`projectsCount`, `groupPrincipalId`, `studentsInitials`). 

> **Note:** `AZURE_PRINCIPAL_ID` (the deployer's identity) is set automatically by `azd` from your logged-in session. You do not need to set it manually.

### Steps

```bash
cd foundry-workshop
az login
azd config set auth.useAzCliAuth true # use Azure CLI credentials


azd env set PROJECTS_COUNT 15
azd env set AZURE_GROUP_PRINCIPAL_ID 00000000-0000-0000-0000-000000000000 # your Entra group Object ID
azd env set STUDENTS_INITIALS aki,gna,sig,mus,nki,svi,cgr,kpr,asa,st1,st2,st3,st4,st5,st6 # optional

# Optional
azd env set SUBNET_FOR_STORAGE_PE_RESOURCE_ID /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/networking-rg/providers/Microsoft.Network/virtualNetworks/pe-vnet/subnets/pe-subnet
azd env set BLOB_PRIVATE_DNS_ZONE_RESOURCE_ID /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net

azd up
```

The `azure.yaml` file defines the `azd` lifecycle hooks. After infrastructure provisioning completes, a `postprovision` hook approves private endpoint connections and creates search indexes. A separate `postup` hook creates the AI agents (v1 and v2) after the full deployment finishes.

## Deployment from Cloudshell

To avoid local DNS/Networking issues, deployment can be executed from cloudshell.

1. Go to https://shell.azure.com
2. Clone this repository `git clone https://github.com/johnhain-msft/workshop_bicep.git`
3. Install uv `curl -LsSf https://astral.sh/uv/install.sh | sh`
4. Set variables
    ```bash
    azd env set PROJECTS_COUNT 15
    azd env set AZURE_GROUP_PRINCIPAL_ID 00000000-0000-0000-0000-000000000000 # your Entra group Object ID
    azd env set STUDENTS_INITIALS aki,gna,sig,mus,nki,svi,cgr,kpr,asa,st1,st2,st3,st4,st5,st6 # optional
    ```
5. Run `azd up`

---

## Disclaimer

THIS CODE-SAMPLE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.

This sample is not supported under any Microsoft standard support program or service. The script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the script be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample or documentation, even if Microsoft has been advised of the possibility of such damages, rising out of the use of or inability to use the sample script, even if Microsoft has been advised of the possibility of such damages.
