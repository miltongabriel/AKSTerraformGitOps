'use strict';

// Simple tests using only node:test + native fetch (no extra dependencies).
const { test, before, after } = require('node:test');
const assert = require('node:assert');
const app = require('./server');

let server;
let baseUrl;

before(() => {
  server = app.listen(0);
  const { port } = server.address();
  baseUrl = `http://localhost:${port}`;
});

after(() => {
  server.close();
});

test('GET /health retorna status ok', async () => {
  const res = await fetch(`${baseUrl}/health`);
  assert.strictEqual(res.status, 200);
  const body = await res.json();
  assert.deepStrictEqual(body, { status: 'ok' });
});

test('GET /api/tasks retorna lista de tasks', async () => {
  const res = await fetch(`${baseUrl}/api/tasks`);
  assert.strictEqual(res.status, 200);
  const body = await res.json();
  assert.ok(Array.isArray(body));
  assert.ok(body.length > 0);
});

test('POST /api/tasks cria uma nova task', async () => {
  const res = await fetch(`${baseUrl}/api/tasks`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ title: 'Nova task de teste' }),
  });
  assert.strictEqual(res.status, 201);
  const body = await res.json();
  assert.strictEqual(body.title, 'Nova task de teste');
});

test('POST /api/tasks sem title retorna 400', async () => {
  const res = await fetch(`${baseUrl}/api/tasks`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({}),
  });
  assert.strictEqual(res.status, 400);
});
