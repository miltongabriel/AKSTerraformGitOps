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

1. **Terraform** builds the infrastructure in 3 independent layers:
   - the remote **state backend** (an Azure Storage Account);
   - the **AKS** cluster;
   - the **ArgoCD** installation (via Helm) inside the cluster.
2. ArgoCD is bootstrapped already pointing to a **root Application (App-of-Apps pattern)**, which reads the [`argocd/`](argocd/) folder of this very Git repository.
3. That folder holds ArgoCD `Application` manifests that, in turn, point to other folders in the repo ([`k8s/`](k8s/) and [`mySecondWebApp/`](mySecondWebApp/)), each deploying a simple static Nginx site (served from a `ConfigMap`) into its own namespace, auto-created by ArgoCD.
4. From that point on, any change pushed to Git is automatically synced into the cluster (`automated.selfHeal` + `prune`), demonstrating the full **GitOps** loop: Git is the source of truth, and ArgoCD continuously reconciles the cluster state to match it.

In short, this is a learning project covering the full pipeline: **Infrastructure as Code → managed Kubernetes cluster → declarative continuous delivery (GitOps)**.

### Project structure

```
AKSTerraformGitOps/
├── argocd/                              # ArgoCD "child" Application manifests (App-of-Apps)
│   ├── mywebapp_argocd_application.yaml     → points to k8s/, namespace "mywebapp"
│   └── mywebapp2_argocd_application.yaml    → points to mySecondWebApp/, namespace "mywebapp2"
│
├── k8s/                                 # App 1: static nginx site
│   ├── nginx-deployment.yaml                # Deployment (2 replicas, probes, limits, securityContext)
│   ├── nginx-configmap.yaml                 # index.html injected via ConfigMap
│   └── frontend-lb-service.yaml             # LoadBalancer Service
│
├── mySecondWebApp/                      # App 2: second example app managed by ArgoCD (same hardening as App 1)
│   ├── nginx-deployment.yaml
│   ├── nginx-configmap.yaml
│   └── frontend-lb-service.yaml
│
├── terraform/                           # Infrastructure as code, split into numbered "steps"
│   ├── 00-backend/                          # Resource Group + Storage Account + Container for remote tfstate
│   ├── 01-aks/                              # AKS cluster (node pool, RBAC, managed identity)
│   ├── 02-argocd/                           # ArgoCD Helm release + Git repo secret + AppProject + root Application
│   ├── profiles/                            # Per-environment variables
│   │   ├── example.tfvars / example.tfconfig    # Tracked placeholders — copy to dev.* before first use
│   │   ├── dev.tfvars                           # Input values (subscription, region, versions, etc.) — git-ignored
│   │   └── dev.tfconfig                         # Remote backend configuration (state storage account) — git-ignored
│   ├── run.sh                               # Helper: `init` + `apply` one step for a given environment
│   └── destroy.sh                           # Helper: `destroy` every step (except the backend)
│
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

### Deployment steps

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
   ./run.sh 00-backend dev   # creates the remote tfstate storage account (uses local state for this first apply)
   ./run.sh 01-aks dev       # creates the AKS cluster (using the remote backend created above)
   ./run.sh 02-argocd dev    # installs ArgoCD via Helm + creates the root Application (App-of-Apps)
   ```
   (`ENVIRONMENT=dev` can also be exported as an environment variable instead of passed as the 2nd argument.)

5. **Get cluster credentials** (the `Access_credentials` output of the `01-aks` step already prints the ready-to-use command):
   ```bash
   az aks get-credentials --resource-group rg-aksgitops-dev-westcentralus --name aks-aksgitops-dev-westcentralus
   ```

6. From here, ArgoCD takes over: it syncs the `root-app` Application → which creates the `mywebapp` and `mywebapp2` Applications → which create the `mywebapp`/`mywebapp2` namespaces and roll out the Nginx Deployments/Services automatically.

7. To **tear the environment down** (except the backend/tfstate, which has `prevent_destroy`), from `terraform/`:
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

- **Layered Terraform steps** (`00-backend` → `01-aks` → `02-argocd`) separate concerns and shrink the blast radius: destroying/recreating the app layer doesn't touch the cluster, and destroying the cluster doesn't touch the state backend.
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

1. **CI/CD pipeline (GitHub Actions)** — today everything is applied by hand via `run.sh`. Add a workflow that runs `terraform fmt -check`, `terraform validate` and `terraform plan` on every PR touching `terraform/`, gating `terraform apply` behind a manual approval or a merge to `main`. Pair it with a second workflow that lints the Kubernetes manifests (`kubeconform`/`kube-linter`) before ArgoCD ever sees them.
2. **IaC & container security scanning in CI** — run `tfsec`/`checkov` on the Terraform code and `trivy`/`kube-score` on the manifests, to catch issues like the `dev.tfvars` secrets exposure automatically instead of by manual review.
3. **Proper secrets management** — move `subscription_id`/`tenant_id` and the ArgoCD SSH deploy key out of local files into Azure Key Vault, consumed via the External Secrets Operator, instead of Terraform's `file()` reading a key off disk.
4. **De-duplicate the app manifests** — `k8s/` and `mySecondWebApp/` are still maintained as two separate copies (kept in sync by hand; they already drifted once). Turning them into a Helm chart (per-app `values.yaml`) or a Kustomize base + overlays would remove the copy/paste and make future changes one-line.
5. **Multi-environment promotion** — the `profiles/` pattern already supports it; add `test`/`prod` tfvars plus an ArgoCD `ApplicationSet` (or separate root apps) so a change promotes dev → test → prod through Git branches/PRs instead of one static `dev` environment.
6. **Workload Identity / Azure AD RBAC** — replace the raw kubeconfig client-certificate auth used by the Terraform `kubernetes`/`helm` providers with AKS Azure AD integration + Workload Identity, closer to production practice.

---

## 🇧🇷 Português

### O que o projeto faz

Este repositório provisiona, do zero, um ambiente Kubernetes na Azure e o transforma em um ambiente **GitOps**:

1. **Terraform** cria a infraestrutura em 3 camadas independentes:
   - o *backend* remoto de estado (Storage Account no Azure);
   - o cluster **AKS**;
   - a instalação do **ArgoCD** (via Helm) dentro do cluster.
2. O ArgoCD é inicializado já apontando para um **Application "root" (padrão App-of-Apps)**, que lê a pasta [`argocd/`](argocd/) do próprio repositório Git.
3. Essa pasta contém `Application` manifests do ArgoCD que, por sua vez, apontam para outras pastas do repositório ([`k8s/`](k8s/) e [`mySecondWebApp/`](mySecondWebApp/)), cada uma implantando um site Nginx estático simples (servido via `ConfigMap`) em seu próprio namespace, criado automaticamente pelo ArgoCD.
4. A partir daí, qualquer alteração nos manifests dentro do Git é sincronizada automaticamente no cluster (`automated.selfHeal` + `prune`), demonstrando o fluxo completo de **GitOps**: o Git é a fonte da verdade, e o ArgoCD converge o estado do cluster para o estado declarado.

Ou seja, é um projeto de aprendizado que cobre a esteira completa: **Infraestrutura como código → Cluster Kubernetes gerenciado → Entrega contínua declarativa (GitOps)**.

### Estrutura do projeto

```
AKSTerraformGitOps/
├── argocd/                              # Manifests das Applications "filhas" do ArgoCD (App-of-Apps)
│   ├── mywebapp_argocd_application.yaml     → aponta para k8s/, namespace "mywebapp"
│   └── mywebapp2_argocd_application.yaml    → aponta para mySecondWebApp/, namespace "mywebapp2"
│
├── k8s/                                 # App 1: nginx estático
│   ├── nginx-deployment.yaml                # Deployment (2 réplicas, probes, limits, securityContext)
│   ├── nginx-configmap.yaml                 # index.html injetado via ConfigMap
│   └── frontend-lb-service.yaml             # Service tipo LoadBalancer
│
├── mySecondWebApp/                      # App 2: segundo exemplo de app gerenciado pelo ArgoCD (mesmo hardening do App 1)
│   ├── nginx-deployment.yaml
│   ├── nginx-configmap.yaml
│   └── frontend-lb-service.yaml
│
├── terraform/                           # Infraestrutura como código, em "steps" numerados
│   ├── 00-backend/                          # Resource Group + Storage Account + Container p/ o tfstate remoto
│   ├── 01-aks/                              # Cluster AKS (node pool, RBAC, identidade gerenciada)
│   ├── 02-argocd/                           # Helm release do ArgoCD + secret do repo Git + AppProject + Application "root"
│   ├── profiles/                            # Variáveis por ambiente
│   │   ├── example.tfvars / example.tfconfig    # Templates versionados — copiar para dev.* antes do primeiro uso
│   │   ├── dev.tfvars                           # Valores de entrada (subscription, região, versões, etc.) — git-ignorado
│   │   └── dev.tfconfig                         # Configuração do backend remoto (storage account do state) — git-ignorado
│   ├── run.sh                               # Helper: `init` + `apply` de um step para um ambiente
│   └── destroy.sh                           # Helper: `destroy` de todos os steps (exceto o backend)
│
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

### Passos para deploy

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
   ./run.sh 00-backend dev   # cria o storage account remoto do tfstate (state local nesse primeiro apply)
   ./run.sh 01-aks dev       # cria o cluster AKS (usa o backend remoto criado acima)
   ./run.sh 02-argocd dev    # instala o ArgoCD via Helm + cria a Application "root" (App-of-Apps)
   ```
   (`ENVIRONMENT=dev` também pode ser exportado como variável de ambiente em vez de passado como 2º argumento.)

5. **Obter as credenciais do cluster** (o output `Access_credentials` do step `01-aks` já traz o comando pronto):
   ```bash
   az aks get-credentials --resource-group rg-aksgitops-dev-westcentralus --name aks-aksgitops-dev-westcentralus
   ```

6. A partir daqui o ArgoCD assume: ele sincroniza a Application `root-app` → que cria as Applications `mywebapp` e `mywebapp2` → que criam os namespaces `mywebapp`/`mywebapp2` e sobem os Deployments/Services do Nginx automaticamente.

7. Para **destruir o ambiente** (exceto o backend/tfstate, que tem `prevent_destroy`), a partir de `terraform/`:
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

- **Terraform em camadas/steps** (`00-backend` → `01-aks` → `02-argocd`) separa responsabilidades e reduz o "raio de explosão": destruir/recriar a aplicação não afeta o cluster, e destruir o cluster não afeta o backend do state.
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

1. **Pipeline de CI/CD (GitHub Actions)** — hoje tudo é aplicado manualmente via `run.sh`. Adicionar um workflow que rode `terraform fmt -check`, `terraform validate` e `terraform plan` em todo PR que mexa em `terraform/`, deixando o `terraform apply` condicionado a uma aprovação manual ou ao merge na `main`. Complementar com um segundo workflow que faça lint dos manifests Kubernetes (`kubeconform`/`kube-linter`) antes de chegarem ao ArgoCD.
2. **Scan de segurança de IaC e containers no CI** — rodar `tfsec`/`checkov` no código Terraform e `trivy`/`kube-score` nos manifests, para pegar automaticamente problemas como a exposição de segredos no `dev.tfvars`, em vez de depender de revisão manual.
3. **Gestão de segredos de verdade** — tirar `subscription_id`/`tenant_id` e a chave SSH do ArgoCD de arquivos locais e mover para o Azure Key Vault, consumidos via External Secrets Operator, em vez do Terraform ler a chave do disco com `file()`.
4. **Eliminar duplicação dos manifests** — `k8s/` e `mySecondWebApp/` ainda são mantidas como duas cópias separadas (sincronizadas manualmente; já divergiram uma vez). Transformá-las em um Helm chart (com `values.yaml` por app) ou em uma base + overlays do Kustomize eliminaria o copy/paste e tornaria mudanças futuras questão de uma linha.
5. **Promoção multi-ambiente** — o padrão `profiles/` já suporta isso; adicionar tfvars de `test`/`prod` e um `ApplicationSet` do ArgoCD (ou root apps separadas) para que uma mudança seja promovida dev → test → prod via branches/PRs no Git, em vez de um único ambiente `dev` estático.
6. **Workload Identity / Azure AD RBAC** — trocar a autenticação por certificado de cliente via kubeconfig usada pelos providers `kubernetes`/`helm` do Terraform pela integração Azure AD do AKS + Workload Identity, mais próximo de uma prática de produção.
