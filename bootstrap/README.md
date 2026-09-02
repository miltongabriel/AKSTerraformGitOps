# Bootstrap

This folder provisions the things the CI/CD pipeline (`.github/workflows/tf-plan-approve-apply.yaml`) itself depends on: the remote Terraform state backend, the Container Registry, the Key Vault holding the ArgoCD SSH deploy key, and the OIDC identities the pipeline authenticates as. It is deliberately **outside** `terraform/` and outside the pipeline's reach.

## Why this is separate from `terraform/`

- The pipeline's `detect-changes` job only ever looks at `terraform/**/*.tf`. Nothing here can be matrix-included or auto-applied by CI, on purpose — the pipeline should never be able to touch the resources that created its own state backend, secrets, and identities (least privilege / no self-escalation).
- These steps are applied **once, manually, by an operator** with elevated Azure AD rights (able to create App Registrations, Service Principals, role assignments) via `az login` — not by a service principal.

## Steps, in order

| Step | What it creates | State |
|---|---|---|
| `00-backend` | Resource Group + Storage Account + Container for the `terraform/` remote tfstate | **Local** (unavoidable — it creates the backend everything else, including the other steps here, then points at) |
| `01-registry` | Resource Group + Container Registry (ACR) | Remote (same backend `00-backend` just created) |
| `02-keyvault` | Key Vault + the ArgoCD SSH deploy key, seeded from a local file | Remote (same backend) |
| `90-identities` | 3 GitHub Actions OIDC App Registrations: registry-push, terraform-apply, terraform-plan — including read access (`Key Vault Secrets User`) to the `02-keyvault` vault, and both `"Azure Kubernetes Service RBAC Cluster Admin"` (Kubernetes RBAC) and `"Azure Kubernetes Service Cluster User Role"` (ARM, needed to fetch a kubeconfig at all) on the AKS cluster's resource group for terraform-apply/terraform-plan | Remote (same backend) |

`90-identities` is deliberately **last**: it grants roles onto resources created by every earlier step (the RG, the ACR, the tfstate storage account, and now the Key Vault), so those resources need to exist before it runs.

Since `terraform/01-aks` runs with `local_account_disabled = true`, `90-identities` also manages **your own** cluster access: `operator_access.tf` grants `"Azure Kubernetes Service RBAC Cluster Admin"` to every Azure AD object ID listed in the `operator_aad_object_ids` variable (empty by default). Add your own object ID there before applying `terraform/01-aks`, or `az aks get-credentials`/`kubectl` stop working for you until fixed manually (your ARM/Portal access is unaffected either way).

Run them with `bootstrap/run.sh`, from this folder:

```bash
az login
./run.sh 00-backend dev
./run.sh 01-registry dev
./run.sh 02-keyvault dev
./run.sh 90-identities dev
```

(`ENVIRONMENT=dev` can also be exported instead of passed as the 2nd argument.)

`02-keyvault` needs the ArgoCD SSH private key to already exist locally at `argocd_project_ssh_private_key_path` (see the "Generate the SSH key" step in the root [README.md](../README.md)) — it reads that file once, via `file()`, to seed the Key Vault secret. From that point on, `terraform/02-argocd` never touches the local file again; it reads the secret straight from Key Vault.

To **rotate** the key later: generate a new keypair, register the new public key as the GitHub Deploy Key, then either re-run `./run.sh 02-keyvault dev` (pointing `argocd_project_ssh_private_key_path` at the new private key) or `az keyvault secret set` directly against the vault — then let the pipeline re-apply `terraform/02-argocd` to roll the new value into the cluster.

After `90-identities` finishes, copy its `github_secrets_setup` output into the corresponding GitHub Environments (`dev-plan`, `dev-apply`) as repo secrets. From that point on, `terraform/01-aks` and `terraform/02-argocd` are pipeline-managed.

## Notes

- There is intentionally **no `destroy.sh` here**. `00-backend` has `prevent_destroy`; `01-registry`/`02-keyvault`/`90-identities` hold live resources feeding real GitHub Environment secrets and the ArgoCD deploy key. Tearing any of this down should stay a deliberate, manually-typed `terraform destroy` in the specific step folder — never a one-line script.
- If you ever start a brand-new environment from scratch, `00-backend` must be applied first — `01-registry`, `02-keyvault`, and `90-identities` all assume its storage account already exists for their remote state.
