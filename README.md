# AKS Terraform GitOps

Study lab / laboratório de estudo: **Terraform (IaC) + AKS (Azure Kubernetes Service) + ArgoCD (GitOps)**.

[![Terraform](https://img.shields.io/badge/Terraform-844FBA?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Microsoft Azure](https://img.shields.io/badge/Microsoft%20Azure-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)](https://azure.microsoft.com/)
[![AKS](https://img.shields.io/badge/AKS-0078D4?style=for-the-badge&logo=kubernetes&logoColor=white)](https://azure.microsoft.com/en-us/products/kubernetes-service)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Argo CD](https://img.shields.io/badge/Argo%20CD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white)](https://argo-cd.readthedocs.io/)
[![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white)](https://helm.sh/)
[![NGINX](https://img.shields.io/badge/NGINX-009639?style=for-the-badge&logo=nginx&logoColor=white)](https://nginx.org/)
[![GitOps](https://img.shields.io/badge/GitOps-1a1a1a?style=for-the-badge&logo=git&logoColor=white)](https://opengitops.dev/)
[![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)

> 🇬🇧 [English](#-english) · 🇧🇷 [Português](#-português)

---

## 🇬🇧 English

### What the project does

This repository provisions a full Kubernetes environment on Azure from scratch and turns it into a **GitOps**-driven environment:

1. **Terraform** builds the infrastructure: a one-time manual **bootstrap** layer (remote state backend, Container Registry, CI/CD identities — see [`bootstrap/`](bootstrap/)) followed by 2 pipeline-managed layers:
   - the **AKS** cluster;
   - the **ArgoCD** installation (via Helm) inside the cluster.
2. ArgoCD is bootstrapped already pointing to a **root Application (App-of-Apps pattern)**, which reads the [`argocd/`](argocd/) folder of this very Git repository.
3. That folder holds ArgoCD `Application` manifests that, in turn, point to other folders in the repo ([`k8s/`](k8s/) and [`mySecondWebApp/`](mySecondWebApp/)), each deploying a simple static Nginx site (served from a `ConfigMap`) into its own namespace, auto-created by ArgoCD.
4. From that point on, any change pushed to Git is automatically synced into the cluster (`automated.selfHeal` + `prune`), demonstrating the full **GitOps** loop: Git is the source of truth, and ArgoCD continuously reconciles the cluster state to match it.

In short, this is a learning project covering the full pipeline: **Infrastructure as Code → managed Kubernetes cluster → declarative continuous delivery (GitOps)**.

### Project structure

```
AKSTerraformGitOps/
├── app/                                 # "study-api": Node.js API, containerized and pushed to ACR by build-push-app.yml
│   ├── server.js
│   ├── test.js
│   ├── Dockerfile
│   └── package.json
│
├── k8s/                                 # study-api manifests — the path ArgoCD's root Application syncs directly
│   ├── deployment.yaml                      # Deployment (2 replicas, probes, resource limits)
│   └── service.yaml                         # LoadBalancer Service
│
├── bootstrap/                           # One-time manual setup, outside the CI/CD pipeline's reach (see bootstrap/README.md)
│   ├── 00-backend/                          # Resource Group + Storage Account + Container for remote tfstate (local state — unavoidable)
│   ├── 01-registry/                         # Resource Group + Container Registry (ACR)
│   ├── 02-identities/                       # 3 GitHub Actions OIDC App Registrations (registry-push, terraform-apply, terraform-plan)
│   └── run.sh                               # Helper: `init` + `apply` one bootstrap step for a given environment
│
├── terraform/                           # Infrastructure as code, split into numbered "steps", pipeline-managed
│   ├── 01-aks/                              # AKS cluster (node pool, RBAC, managed identity)
│   ├── 02-argocd/                           # ArgoCD Helm release + Git repo secret + AppProject + root Application (syncs k8s/ directly)
│   ├── profiles/                            # Per-environment variables
│   │   ├── example.tfvars / example.tfconfig    # Tracked placeholders — copy to dev.* before first use
│   │   ├── dev.tfvars                           # Input values (subscription, region, versions, etc.) — git-ignored
│   │   └── dev.tfconfig                         # Remote backend configuration (state storage account) — git-ignored
│   ├── run.sh                               # Helper: `init` + `apply` one step for a given environment
│   └── destroy.sh                           # Helper: `destroy` every step
│
├── .github/workflows/                   # CI/CD: build-push-app.yml (build+push image), ci.yml (app/ tests + k8s/ lint), tf-plan-approve-apply.yaml (terraform/ plan+apply)
├── argocd-ssh-key / argocd-ssh-key.pub  # SSH keypair ArgoCD uses to read this repo (git-ignored)
└── .gitignore
```

### Requirements

- An **Azure** account/subscription with permission to create a Resource Group, Storage Account and AKS.
- [Azure CLI](https://learn.microsoft.com/cli/azure/) (`az login` configured).
- [Terraform](https://developer.hashicorp.com/terraform) `>= 1.15.8`.
- `kubectl` (to inspect the cluster and ArgoCD).
- `git` + a Bash-compatible shell to run `run.sh`/`destroy.sh` (on Windows, Git Bash).
- A remote Git repo (e.g. GitHub) with a read-only **Deploy Key** so ArgoCD can clone this repository over SSH.
- For Bootstrap below: an Azure AD account with rights to create App Registrations, Service Principals, and role assignments (not just subscription-level Contributor).

### Bootstrap: one-time manual setup

Before the pipeline-managed `terraform/` steps below can run, someone has to create the things the pipeline itself depends on: the remote state backend, the Container Registry, and the OIDC identities the CI/CD workflows authenticate as. This lives in [`bootstrap/`](bootstrap/), deliberately **outside** `terraform/` — the pipeline's `detect-changes` job only scans `terraform/**/*.tf`, so it can never see or apply this folder (least privilege: the pipeline shouldn't be able to touch the resources that created its own backend and identities). Run it once, by hand, with an Azure AD account that can create Resource Groups, Storage Accounts, App Registrations, and role assignments:

```bash
az login
cd bootstrap
./run.sh 00-backend dev     # creates the remote tfstate storage account (local state for this one apply — unavoidable)
./run.sh 01-registry dev    # creates the Resource Group + Container Registry (ACR)
./run.sh 02-identities dev  # creates the 3 GitHub Actions OIDC App Registrations
```

Then copy the `github_secrets_setup` output from `02-identities` into the corresponding GitHub Environments (`dev-plan`, `dev-apply`) as repo secrets. See [`bootstrap/README.md`](bootstrap/README.md) for details and destroy warnings. From this point on, `terraform/01-aks` and `terraform/02-argocd` are handed off to `tf-plan-approve-apply.yaml` (plan on push to `main`, manual-approval gate before apply).

### Deployment steps

> Assumes Bootstrap above has already been completed.

1. **Generate the SSH key ArgoCD will use to read the repository**, and register it as a read-only *Deploy Key* on the GitHub repo:
   ```bash
   ssh-keygen -t ed25519 -f argocd-ssh-key -N ""
   ```

2. **Create your environment's variable files from the tracked templates**, then fill them in:
   ```bash
   cp terraform/profiles/example.tfvars terraform/profiles/dev.tfvars
   cp terraform/profiles/example.tfconfig terraform/profiles/dev.tfconfig
   ```
   Edit [`terraform/profiles/dev.tfvars`](terraform/profiles/dev.tfvars) (subscription/tenant id, region, AKS version, VM size, repo URL, etc.) and [`terraform/profiles/dev.tfconfig`](terraform/profiles/dev.tfconfig) (Terraform remote backend settings).
   > ⚠️ `dev.tfvars`/`dev.tfconfig` are already covered by `.gitignore` (only the `example.*` templates are tracked), so they won't be committed. They still hold `subscription_id`/`tenant_id` in plaintext on disk, though — treat them like any other local credential (e.g. `TF_VAR_*` env vars are an alternative for extra safety).

3. **Log in to Azure**:
   ```bash
   az login
   ```

4. **Apply the Terraform steps, in order**, from the `terraform/` folder:
   ```bash
   ./run.sh 01-aks dev       # creates the AKS cluster (using the remote backend created during Bootstrap)
   ./run.sh 02-argocd dev    # installs ArgoCD via Helm + creates the root Application (App-of-Apps)
   ```
   (`ENVIRONMENT=dev` can also be exported as an environment variable instead of passed as the 2nd argument.)

5. **Get cluster credentials** (the `Access_credentials` output of the `01-aks` step already prints the ready-to-use command):
   ```bash
   az aks get-credentials --resource-group rg-aksgitops-dev-westcentralus --name aks-aksgitops-dev-westcentralus
   ```

6. From here, ArgoCD takes over: it syncs the `root-app` Application → which creates the `mywebapp` and `mywebapp2` Applications → which create the `mywebapp`/`mywebapp2` namespaces and roll out the Nginx Deployments/Services automatically.

7. To **tear the environment down** (the `bootstrap/` layer is untouched — no `destroy.sh` there, by design), from `terraform/`:
   ```bash
   ./destroy.sh dev
   ```

### How to access ArgoCD

The ArgoCD Helm chart was installed with the server in `insecure` mode (no TLS) and **without** a public LoadBalancer (that option is commented out in [`terraform/02-argocd/argocd.tf`](terraform/02-argocd/argocd.tf)), so the default access path is via port-forward:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

Then open **http://localhost:8080**.

Username: `admin`. Initial password (auto-generated by the chart):

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

> It's recommended to change the `admin` password after the first login (`argocd account update-password`), since it stays in the secret until changed.

### What we learned from this project

- **Layered Terraform steps** (manual `bootstrap/00-backend` → `01-registry` → `02-identities`, then pipeline-managed `terraform/01-aks` → `02-argocd`) separate concerns and shrink the blast radius: destroying/recreating the app layer doesn't touch the cluster, and destroying the cluster doesn't touch the state backend.
- **Structural least privilege for CI/CD**: `bootstrap/` sits outside `terraform/` on purpose, so the pipeline's OIDC identity — itself created inside `bootstrap/02-identities` — can never see or apply the folder that created its own backend and identities, and separate GitHub Environments (`dev-plan`/`dev-apply`) keep the read-only plan identity's secrets apart from the apply identity's.
- **Protected remote backend**: the state's Storage Account and Container use `prevent_destroy`, blob versioning, and delete retention — guarding against accidental state loss.
- **ArgoCD's App-of-Apps pattern**: a single root `Application` manages other `Applications` via Git, fully declaratively — even the Git repository registration in ArgoCD is done through Terraform (a `kubernetes_secret_v1` holding the SSH key), with no manual `argocd repo add` step.
- **Dedicated `AppProject`**: `root-app`, `mywebapp` and `mywebapp2` all belong to a project created by Terraform (named after `argocd_project_name`) instead of ArgoCD's built-in `default` project, scoping which repo/namespaces the apps are allowed to touch.
- **GitOps in practice**: `syncPolicy.automated` with `selfHeal` + `prune` + `CreateNamespace=true` makes the cluster self-converge to whatever is in Git, automatically reverting manual edits made directly against the cluster.
- **Terraform bootstrapping the Kubernetes platform it just created**: the `kubernetes`/`helm`/`kubectl` providers in the `02-argocd` step authenticate using the `data "azurerm_kubernetes_cluster"` data source from the previous step — wiring infrastructure and platform together without manually exporting a kubeconfig.
- **Pod security best practices (and trade-offs)**: `resources.requests/limits`, `readinessProbe`/`livenessProbe`, and a `securityContext` dropping all capabilities — but the repo's commit history shows restrictions like `runAsNonRoot` and a read-only volume had to be walked back to let the stock `nginx` image `chown` its files at startup, a practical reminder that over-hardening can break container images that weren't built to run as non-root.
- **Per-environment profiles** (`profiles/dev.tfvars` + `dev.tfconfig`) let the same Terraform code be reused across multiple environments (dev/test/prod) just by swapping the variables file.
- **Watch out for "almost public" secrets**: `subscription_id`/`tenant_id` aren't critical secrets on their own, but the project is a good reminder to never leave that kind of data hardcoded in tracked files.

### Next enhancements

Ideas to take this lab further, roughly in suggested order:

1. **Lint/scan `bootstrap/` too** — it's intentionally excluded from `tf-plan-approve-apply.yaml` for least-privilege reasons, but a separate, non-privileged, read-only workflow could still run `terraform fmt -check`/`terraform validate` (and `tfsec`/`checkov`, see below) against it in CI.
2. **IaC & container security scanning in CI** — run `tfsec`/`checkov` on the `terraform/` code and `trivy`/`kube-score` on the manifests, to catch issues like the `dev.tfvars` secrets exposure automatically instead of by manual review.
3. **Proper secrets management** — move `subscription_id`/`tenant_id` and the ArgoCD SSH deploy key out of local files into Azure Key Vault, consumed via the External Secrets Operator, instead of Terraform's `file()` reading a key off disk.
4. **De-duplicate the app manifests** — `k8s/` and `mySecondWebApp/` are still maintained as two separate copies (kept in sync by hand; they already drifted once). Turning them into a Helm chart (per-app `values.yaml`) or a Kustomize base + overlays would remove the copy/paste and make future changes one-line.
5. **Multi-environment promotion** — the `profiles/` pattern already supports it; add `test`/`prod` tfvars plus an ArgoCD `ApplicationSet` (or separate root apps) so a change promotes dev → test → prod through Git branches/PRs instead of one static `dev` environment.
6. **Workload Identity / Azure AD RBAC** — replace the raw kubeconfig client-certificate auth used by the Terraform `kubernetes`/`helm` providers with AKS Azure AD integration + Workload Identity, closer to production practice.

---

## 🇧🇷 Português

### O que o projeto faz

Este repositório provisiona, do zero, um ambiente Kubernetes na Azure e o transforma em um ambiente **GitOps**:

1. **Terraform** cria a infraestrutura: uma camada de **bootstrap** manual e única (backend remoto de estado, Container Registry, identidades do CI/CD — veja [`bootstrap/`](bootstrap/)) seguida de 2 camadas gerenciadas pelo pipeline:
   - o cluster **AKS**;
   - a instalação do **ArgoCD** (via Helm) dentro do cluster.
2. O ArgoCD é inicializado já apontando para um **Application "root" (padrão App-of-Apps)**, que lê a pasta [`argocd/`](argocd/) do próprio repositório Git.
3. Essa pasta contém `Application` manifests do ArgoCD que, por sua vez, apontam para outras pastas do repositório ([`k8s/`](k8s/) e [`mySecondWebApp/`](mySecondWebApp/)), cada uma implantando um site Nginx estático simples (servido via `ConfigMap`) em seu próprio namespace, criado automaticamente pelo ArgoCD.
4. A partir daí, qualquer alteração nos manifests dentro do Git é sincronizada automaticamente no cluster (`automated.selfHeal` + `prune`), demonstrando o fluxo completo de **GitOps**: o Git é a fonte da verdade, e o ArgoCD converge o estado do cluster para o estado declarado.

Ou seja, é um projeto de aprendizado que cobre a esteira completa: **Infraestrutura como código → Cluster Kubernetes gerenciado → Entrega contínua declarativa (GitOps)**.

### Estrutura do projeto

```
AKSTerraformGitOps/
├── app/                                 # "study-api": API em Node.js, containerizada e enviada ao ACR pelo build-push-app.yml
│   ├── server.js
│   ├── test.js
│   ├── Dockerfile
│   └── package.json
│
├── k8s/                                 # Manifests do study-api — o caminho que a Application "root" do ArgoCD sincroniza direto
│   ├── deployment.yaml                      # Deployment (2 réplicas, probes, limites de recursos)
│   └── service.yaml                         # Service tipo LoadBalancer
│
├── bootstrap/                           # Configuração manual única, fora do alcance do pipeline de CI/CD (veja bootstrap/README.md)
│   ├── 00-backend/                          # Resource Group + Storage Account + Container p/ o tfstate remoto (state local — inevitável)
│   ├── 01-registry/                         # Resource Group + Container Registry (ACR)
│   ├── 02-identities/                       # 3 App Registrations OIDC do GitHub Actions (registry-push, terraform-apply, terraform-plan)
│   └── run.sh                               # Helper: `init` + `apply` de um step de bootstrap para um ambiente
│
├── terraform/                           # Infraestrutura como código, em "steps" numerados, gerenciada pelo pipeline
│   ├── 01-aks/                              # Cluster AKS (node pool, RBAC, identidade gerenciada)
│   ├── 02-argocd/                           # Helm release do ArgoCD + secret do repo Git + AppProject + Application "root" (sincroniza k8s/ direto)
│   ├── profiles/                            # Variáveis por ambiente
│   │   ├── example.tfvars / example.tfconfig    # Templates versionados — copiar para dev.* antes do primeiro uso
│   │   ├── dev.tfvars                           # Valores de entrada (subscription, região, versões, etc.) — git-ignorado
│   │   └── dev.tfconfig                         # Configuração do backend remoto (storage account do state) — git-ignorado
│   ├── run.sh                               # Helper: `init` + `apply` de um step para um ambiente
│   └── destroy.sh                           # Helper: `destroy` de todos os steps
│
├── .github/workflows/                   # CI/CD: build-push-app.yml (build+push da imagem), ci.yml (testes do app/ + lint do k8s/), tf-plan-approve-apply.yaml (plan+apply do terraform/)
├── argocd-ssh-key / argocd-ssh-key.pub  # Par de chaves SSH usado pelo ArgoCD p/ ler este repositório (git-ignoradas)
└── .gitignore
```

### Requisitos

- Conta e assinatura na **Azure**, com permissão para criar Resource Group, Storage Account e AKS.
- [Azure CLI](https://learn.microsoft.com/cli/azure/) (`az login` configurado).
- [Terraform](https://developer.hashicorp.com/terraform) `>= 1.15.8`.
- `kubectl` (para inspecionar o cluster e o ArgoCD).
- `git` + um shell compatível com Bash para rodar `run.sh`/`destroy.sh` (no Windows, Git Bash).
- Um repositório Git remoto (ex. GitHub) com uma **chave de deploy (Deploy Key)** somente leitura, para o ArgoCD conseguir clonar este repositório via SSH.
- Para o Bootstrap abaixo: uma conta Azure AD com permissão para criar App Registrations, Service Principals e role assignments (não basta Contributor no nível da subscription).

### Bootstrap: configuração manual única

Antes dos steps gerenciados pelo pipeline em `terraform/` conseguirem rodar, alguém precisa criar aquilo de que o próprio pipeline depende: o backend remoto de estado, o Container Registry e as identidades OIDC que os workflows de CI/CD usam para autenticar. Isso vive em [`bootstrap/`](bootstrap/), deliberadamente **fora** de `terraform/` — o job `detect-changes` do pipeline só varre `terraform/**/*.tf`, então nunca consegue enxergar ou aplicar essa pasta (least privilege: o pipeline não deveria conseguir tocar nos recursos que criaram o próprio backend e as próprias identidades). Rode uma vez, manualmente, com uma conta Azure AD que possa criar Resource Groups, Storage Accounts, App Registrations e role assignments:

```bash
az login
cd bootstrap
./run.sh 00-backend dev     # cria o storage account remoto do tfstate (state local nesse apply — inevitável)
./run.sh 01-registry dev    # cria o Resource Group + Container Registry (ACR)
./run.sh 02-identities dev  # cria os 3 App Registrations OIDC do GitHub Actions
```

Depois copie o output `github_secrets_setup` de `02-identities` para os GitHub Environments correspondentes (`dev-plan`, `dev-apply`) como secrets do repositório. Veja [`bootstrap/README.md`](bootstrap/README.md) para detalhes e avisos sobre destruição. A partir daqui, `terraform/01-aks` e `terraform/02-argocd` ficam a cargo do `tf-plan-approve-apply.yaml` (plan a cada push na `main`, com aprovação manual antes do apply).

### Passos para deploy

> Pressupõe que o Bootstrap acima já foi concluído.

1. **Gerar a chave SSH que o ArgoCD usará para ler o repositório** e cadastrá-la como *Deploy Key* (read-only) no repositório no GitHub:
   ```bash
   ssh-keygen -t ed25519 -f argocd-ssh-key -N ""
   ```

2. **Criar os arquivos de variáveis do ambiente a partir dos templates versionados**, depois preenchê-los:
   ```bash
   cp terraform/profiles/example.tfvars terraform/profiles/dev.tfvars
   cp terraform/profiles/example.tfconfig terraform/profiles/dev.tfconfig
   ```
   Editar [`terraform/profiles/dev.tfvars`](terraform/profiles/dev.tfvars) (subscription/tenant id, região, versão do AKS, tamanho de VM, URL do repositório, etc.) e [`terraform/profiles/dev.tfconfig`](terraform/profiles/dev.tfconfig) (dados do backend remoto do Terraform).
   > ⚠️ `dev.tfvars`/`dev.tfconfig` já estão cobertos pelo `.gitignore` (só os templates `example.*` são versionados), então não serão commitados. Ainda assim guardam `subscription_id`/`tenant_id` em texto plano no disco — trate-os como qualquer outra credencial local (variáveis `TF_VAR_*` são uma alternativa para segurança extra).

3. **Login na Azure**:
   ```bash
   az login
   ```

4. **Aplicar os steps do Terraform, em ordem**, a partir da pasta `terraform/`:
   ```bash
   ./run.sh 01-aks dev       # cria o cluster AKS (usa o backend remoto criado no Bootstrap)
   ./run.sh 02-argocd dev    # instala o ArgoCD via Helm + cria a Application "root" (App-of-Apps)
   ```
   (`ENVIRONMENT=dev` também pode ser exportado como variável de ambiente em vez de passado como 2º argumento.)

5. **Obter as credenciais do cluster** (o output `Access_credentials` do step `01-aks` já traz o comando pronto):
   ```bash
   az aks get-credentials --resource-group rg-aksgitops-dev-westcentralus --name aks-aksgitops-dev-westcentralus
   ```

6. A partir daqui o ArgoCD assume: ele sincroniza a Application `root-app` → que cria as Applications `mywebapp` e `mywebapp2` → que criam os namespaces `mywebapp`/`mywebapp2` e sobem os Deployments/Services do Nginx automaticamente.

7. Para **destruir o ambiente** (a camada `bootstrap/` não é afetada — não existe `destroy.sh` lá, de propósito), a partir de `terraform/`:
   ```bash
   ./destroy.sh dev
   ```

### Como acessar o ArgoCD

O chart do ArgoCD foi instalado com o servidor em modo `insecure` (sem TLS) e **sem** LoadBalancer exposto publicamente (essa opção está comentada em [`terraform/02-argocd/argocd.tf`](terraform/02-argocd/argocd.tf)), então o acesso padrão é via port-forward:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

Depois acesse **http://localhost:8080**.

Usuário: `admin`. Senha inicial (gerada automaticamente pelo chart):

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

> Recomendado trocar a senha do `admin` após o primeiro login (`argocd account update-password`), já que ela fica no secret até ser alterada.

### O que aprendemos com esse projeto

- **Terraform em camadas/steps** (`bootstrap/00-backend` → `01-registry` → `02-identities` manuais, depois `terraform/01-aks` → `02-argocd` gerenciados pelo pipeline) separa responsabilidades e reduz o "raio de explosão": destruir/recriar a aplicação não afeta o cluster, e destruir o cluster não afeta o backend do state.
- **Least privilege estrutural para o CI/CD**: `bootstrap/` fica fora de `terraform/` de propósito, para que a identidade OIDC do pipeline — criada dentro de `bootstrap/02-identities` — nunca consiga enxergar ou aplicar a pasta que criou o próprio backend e as próprias identidades; GitHub Environments separados (`dev-plan`/`dev-apply`) mantêm os secrets da identidade read-only de plan separados dos da identidade de apply.
- **Backend remoto com proteção**: o Storage Account e o Container do tfstate usam `prevent_destroy`, versionamento de blobs e retenção de exclusão — evitando perda acidental do state.
- **Padrão App-of-Apps do ArgoCD**: uma única `Application` "root" gerenciando outras `Applications` via Git, tudo declarativo — inclusive o próprio cadastro do repositório Git no ArgoCD é feito via Terraform (`kubernetes_secret_v1` com a chave SSH), sem passos manuais de `argocd repo add`.
- **`AppProject` dedicado**: `root-app`, `mywebapp` e `mywebapp2` pertencem a um projeto criado pelo Terraform (nomeado a partir de `argocd_project_name`) em vez do projeto `default` embutido do ArgoCD, restringindo repositório/namespaces que as apps podem tocar.
- **GitOps na prática**: `syncPolicy.automated` com `selfHeal` + `prune` + `CreateNamespace=true` faz o cluster convergir sozinho para o que está no Git, e reverte automaticamente edições manuais feitas diretamente no cluster.
- **Terraform provisionando o próprio Kubernetes**: os providers `kubernetes`/`helm`/`kubectl` do step `02-argocd` se autenticam usando o `data "azurerm_kubernetes_cluster"` do step anterior — ou seja, infraestrutura e plataforma são conectadas sem exportar kubeconfig manualmente.
- **Boas práticas (e trade-offs) de segurança em Pods**: `resources.requests/limits`, `readinessProbe`/`livenessProbe`, e `securityContext` com `drop: [ALL]` — mas o histórico do repo mostra que restrições como `runAsNonRoot` e volume `readOnly` tiveram que ser recuadas para permitir que a imagem `nginx` fizesse `chown` na inicialização, um lembrete prático de como *hardening* excessivo pode quebrar imagens de container não preparadas para rodar como não-root.
- **Perfis por ambiente** (`profiles/dev.tfvars` + `dev.tfconfig`) permitem reaproveitar o mesmo código Terraform para múltiplos ambientes (dev/test/prod) só trocando o arquivo de variáveis.
- **Cuidado com segredos "quase públicos"**: `subscription_id`/`tenant_id` não são segredos críticos por si só, mas o projeto reforça o hábito de nunca deixar esse tipo de dado hardcoded em arquivos versionados.

### Próximas melhorias

Ideias para evoluir esse laboratório, em ordem sugerida:

1. **Lint/scan também no `bootstrap/`** — ele é excluído de propósito do `tf-plan-approve-apply.yaml` por motivos de least privilege, mas um workflow separado, sem privilégios e somente leitura, poderia rodar `terraform fmt -check`/`terraform validate` (e `tfsec`/`checkov`, ver abaixo) contra ele no CI.
2. **Scan de segurança de IaC e containers no CI** — rodar `tfsec`/`checkov` no código de `terraform/` e `trivy`/`kube-score` nos manifests, para pegar automaticamente problemas como a exposição de segredos no `dev.tfvars`, em vez de depender de revisão manual.
3. **Gestão de segredos de verdade** — tirar `subscription_id`/`tenant_id` e a chave SSH do ArgoCD de arquivos locais e mover para o Azure Key Vault, consumidos via External Secrets Operator, em vez do Terraform ler a chave do disco com `file()`.
4. **Eliminar duplicação dos manifests** — `k8s/` e `mySecondWebApp/` ainda são mantidas como duas cópias separadas (sincronizadas manualmente; já divergiram uma vez). Transformá-las em um Helm chart (com `values.yaml` por app) ou em uma base + overlays do Kustomize eliminaria o copy/paste e tornaria mudanças futuras questão de uma linha.
5. **Promoção multi-ambiente** — o padrão `profiles/` já suporta isso; adicionar tfvars de `test`/`prod` e um `ApplicationSet` do ArgoCD (ou root apps separadas) para que uma mudança seja promovida dev → test → prod via branches/PRs no Git, em vez de um único ambiente `dev` estático.
6. **Workload Identity / Azure AD RBAC** — trocar a autenticação por certificado de cliente via kubeconfig usada pelos providers `kubernetes`/`helm` do Terraform pela integração Azure AD do AKS + Workload Identity, mais próximo de uma prática de produção.
