# Bootstrap

This folder provisions the things the CI/CD pipeline (`.github/workflows/tf-plan-approve-apply.yaml`) itself depends on: the remote Terraform state backend, the Container Registry, and the OIDC identities the pipeline authenticates as. It is deliberately **outside** `terraform/` and outside the pipeline's reach.

## Why this is separate from `terraform/`

- The pipeline's `detect-changes` job only ever looks at `terraform/**/*.tf`. Nothing here can be matrix-included or auto-applied by CI, on purpose — the pipeline should never be able to touch the resources that created its own state backend and identities (least privilege / no self-escalation).
- These steps are applied **once, manually, by an operator** with elevated Azure AD rights (able to create App Registrations, Service Principals, role assignments) via `az login` — not by a service principal.

## Steps, in order

| Step | What it creates | State |
|---|---|---|
| `00-backend` | Resource Group + Storage Account + Container for the `terraform/` remote tfstate | **Local** (unavoidable — it creates the backend everything else, including the other two steps here, then points at) |
| `01-registry` | Resource Group + Container Registry (ACR) | Remote (same backend `00-backend` just created) |
| `02-identities` | 3 GitHub Actions OIDC App Registrations: registry-push, terraform-apply, terraform-plan | Remote (same backend) |

Run them with `bootstrap/run.sh`, from this folder:

```bash
az login
./run.sh 00-backend dev
./run.sh 01-registry dev
./run.sh 02-identities dev
```

(`ENVIRONMENT=dev` can also be exported instead of passed as the 2nd argument.)

After `02-identities` finishes, copy its `github_secrets_setup` output into the corresponding GitHub Environments (`dev-plan`, `dev-apply`) as repo secrets. From that point on, `terraform/01-aks` and `terraform/02-argocd` are pipeline-managed.

## Notes

- `01-registry` and `02-identities` both `import` resources that already exist in Azure (originally created by the now-retired `setup_registry.sh` / `setup_appRegistration*.sh` scripts) instead of creating them fresh — don't re-run those scripts, they'd conflict with what Terraform now manages.
- There is intentionally **no `destroy.sh` here**. `00-backend` has `prevent_destroy`; `01-registry`/`02-identities` hold live resources feeding real GitHub Environment secrets. Tearing any of this down should stay a deliberate, manually-typed `terraform destroy` in the specific step folder — never a one-line script.
- If you ever start a brand-new environment from scratch, `00-backend` must be applied first — `01-registry` and `02-identities` both assume its storage account already exists for their remote state.
