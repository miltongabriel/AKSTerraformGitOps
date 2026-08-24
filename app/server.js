'use strict';

const express = require('express');

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

// Estado em memória — sem banco de dados, só para fins didáticos.
let tasks = [
  { id: 1, title: 'Aprender Docker', done: false },
  { id: 2, title: 'Aprender CI/CD', done: false },
];
let nextId = 3;

// Usado por probes de liveness/readiness no Kubernetes.
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

app.get('/', (req, res) => {
  res.json({ message: 'study-api no ar', endpoints: ['/health', '/api/tasks'] });
});

app.get('/api/tasks', (req, res) => {
  res.json(tasks);
});

app.get('/api/tasks/:id', (req, res) => {
  const task = tasks.find((t) => t.id === Number(req.params.id));
  if (!task) return res.status(404).json({ error: 'task não encontrada' });
  res.json(task);
});

app.post('/api/tasks', (req, res) => {
  const { title } = req.body || {};
  if (!title || typeof title !== 'string') {
    return res.status(400).json({ error: 'campo "title" é obrigatório' });
  }
  const task = { id: nextId++, title, done: false };
  tasks.push(task);
  res.status(201).json(task);
});

app.delete('/api/tasks/:id', (req, res) => {
  const id = Number(req.params.id);
  const before = tasks.length;
  tasks = tasks.filter((t) => t.id !== id);
  if (tasks.length === before) return res.status(404).json({ error: 'task não encontrada' });
  res.status(204).send();
});

// Só inicia o servidor se o arquivo for executado diretamente (facilita testes).
if (require.main === module) {
  app.listen(port, () => {
    console.log(`study-api ouvindo na porta ${port}`);
  });
}

module.exports = app;
