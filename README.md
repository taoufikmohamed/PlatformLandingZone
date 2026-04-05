# Platform Landing Zone

Terraform-based Azure Platform Landing Zone with modular governance, networking, security, subscriptions, and monitoring.

## Deployment Profiles

Use profile tfvars files to control cost and architecture depth per environment:

- Free tier profile: `environments/dev/free-tier.tfvars`
- Balanced profile: `environments/test/balanced.tfvars`
- Full platform profile (permission-safe): `environments/prod/full-platform.tfvars`
- Full platform + governance profile: `environments/prod/full-platform-governance.tfvars`

Run Terraform with a selected profile:

```powershell
terraform plan -var-file="environments/dev/free-tier.tfvars"
terraform apply -var-file="environments/dev/free-tier.tfvars"
```

```powershell
terraform plan -var-file="environments/test/balanced.tfvars"
terraform apply -var-file="environments/test/balanced.tfvars"
```

```powershell
terraform plan -var-file="environments/prod/full-platform.tfvars"
terraform apply -var-file="environments/prod/full-platform.tfvars" -auto-approve
```

```powershell
terraform plan -var-file="environments/prod/full-platform-governance.tfvars"
terraform apply -var-file="environments/prod/full-platform-governance.tfvars" -auto-approve
terraform plan -var-file="environments/prod/full-platform-governance.tfvars"
terraform apply -var-file="environments/prod/full-platform-governance.tfvars" -auto-approve
```

Notes:

- Keep `billing_scope_id` empty unless your tenant supports subscription vending.
- Full profile enables higher-cost controls (Firewall, Bastion, DDoS) by default.
- Management groups and MG-scoped policies in the governance profile require tenant-root management group write permissions.
- Use the permission-safe full profile when those tenant permissions are not available.
- Free profile is optimized for low cost and fast validation/apply.

## Project Structure

```text
PlatformLandingZone/
|-- main.tf
|-- providers.tf
|-- variables.tf
|-- terraform.tfvars
|-- outputs.tf
|-- environments/
|   |-- dev/
|   |-- test/
|   |-- prod/
|-- modules/
|   |-- management-groups/
|   |-- subscriptions/
|   |-- networking/
|   |-- security/
|   |-- policies/
|   |-- monitoring/
|-- scripts/
|   |-- deploy.ps1
|-- docs/
|   |-- diagrams/
|       |-- project-structure.mmd
|       |-- project-structure.svg
|       |-- azure-architecture.mmd
|       |-- azure-architecture.svg
```

## Diagram: Project Structure

![Project Structure](docs/diagrams/project-structure.svg)

```mermaid
flowchart TB
  Root[PlatformLandingZone]

  Root --> A[main.tf]
  Root --> B[providers.tf]
  Root --> C[variables.tf]
  Root --> D[terraform.tfvars]
  Root --> E[outputs.tf]

  Root --> Env[environments]
  Env --> EnvDev[dev]
  Env --> EnvTest[test]
  Env --> EnvProd[prod]

  Root --> Mods[modules]
  Mods --> MG[management-groups]
  Mods --> SUB[subscriptions]
  Mods --> NET[networking]
  Mods --> SEC[security]
  Mods --> POL[policies]
  Mods --> MON[monitoring]

  MG --> MGf[main.tf / variables.tf]
  SUB --> SUBf[main.tf / variables.tf]
  NET --> NETf[main.tf / variables.tf]
  SEC --> SECf[main.tf / variables.tf]
  POL --> POLf[main.tf / variables.tf]
  MON --> MONf[main.tf / variables.tf]

  Root --> Scripts[scripts]
  Scripts --> DeployPS[deploy.ps1]
```

## Diagram: Azure Architecture

![Azure Architecture](docs/diagrams/azure-architecture.svg)

```mermaid
flowchart LR
  Tenant[Azure Tenant] --> MGRoot[Management Group Hierarchy]

  MGRoot --> MGPlatform[Platform MG]
  MGRoot --> MGLZ[Landing Zones MG]
  MGRoot --> MGSandbox[Sandbox MG]
  MGRoot --> MGDecom[Decommissioned MG]

  MGPlatform --> MGIdentity[Identity MG]
  MGPlatform --> MGManagement[Management MG]
  MGPlatform --> MGConnectivity[Connectivity MG]
  MGLZ --> MGCorp[Corp MG]
  MGLZ --> MGOnline[Online MG]

  SUBConn[(Connectivity Subscription)]
  SUBMgmt[(Management Subscription)]
  SUBId[(Identity Subscription)]
  SUBCorp[(Corp Subscription)]
  SUBOnline[(Online Subscription)]

  MGConnectivity --> SUBConn
  MGManagement --> SUBMgmt
  MGIdentity --> SUBId
  MGCorp --> SUBCorp
  MGOnline --> SUBOnline

  subgraph Connectivity[Connectivity Services]
    HubVNet[Hub VNet]
    Firewall[Azure Firewall]
    Bastion[Azure Bastion]
    DDoS[DDoS Plan optional]
  end

  subgraph Workloads[Workload VNets]
    CorpSpoke[Corp Spoke VNet]
    OnlineSpoke[Online Spoke VNet]
    Peer[Hub-Spoke Peering]
  end

  subgraph Security[Security Services]
    KeyVault[Key Vault]
    Secrets[Secrets and Access Policies]
  end

  subgraph Monitoring[Observability]
    LAW[Log Analytics Workspace]
    AppI[Application Insights]
    Alerts[Monitor Alerts and Action Group]
  end

  subgraph Governance[Governance]
    Policies[Azure Policies]
    AllowedLoc[Allowed Locations]
    AllowedSku[Allowed VM SKUs]
  end

  SUBConn --> Connectivity
  SUBMgmt --> Security
  SUBMgmt --> Monitoring

  HubVNet --> CorpSpoke
  HubVNet --> OnlineSpoke
  Peer --> HubVNet
  Peer --> CorpSpoke
  Peer --> OnlineSpoke

  Firewall --> HubVNet
  Bastion --> HubVNet
  DDoS --> HubVNet

  KeyVault --> Secrets
  LAW --> AppI
  LAW --> Alerts

  MGRoot --> Policies
  Policies --> AllowedLoc
  Policies --> AllowedSku
```
