# study-api

API simples em Node.js/Express, criada apenas para estudo de pipelines de CI/CD (build, testes e imagem Docker). Mantém uma lista de "tasks" em memória — sem banco de dados.

## Rodando localmente

```bash
npm install
npm start
```

A API sobe em `http://localhost:3000`.

## Testes

```bash
npm test
```

## Endpoints

| Método | Rota             | Descrição                     |
|--------|------------------|--------------------------------|
| GET    | `/health`        | Health check (liveness/readiness) |
| GET    | `/`              | Mensagem de boas-vindas        |
| GET    | `/api/tasks`     | Lista todas as tasks           |
| GET    | `/api/tasks/:id` | Retorna uma task específica    |
| POST   | `/api/tasks`     | Cria uma task (`{ "title": "..." }`) |
| DELETE | `/api/tasks/:id` | Remove uma task                |

## Docker

```bash
docker build -t study-api .
docker run -p 3000:3000 study-api
```
