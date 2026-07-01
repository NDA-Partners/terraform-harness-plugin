#!/usr/bin/env node
// Build de l'adaptateur Claude Code depuis core/.
// Source unique = core/ (neutre). Sortie = adapters/claude-code/{agents,skills} (commitée).
// Sans dépendance externe. Déterministe : relancer produit un diff vide.
//
// Correspondances spécifiques à Claude Code encodées ici :
//   - core/roles/*.md      -> adapters/claude-code/agents/*.md   (frontmatter CC + skills: preload depuis `needs`)
//   - core/ontologie/*     -> skills de connaissance (SKILL.md = concat des pages)
//   - core/workflow.md     -> skill d'orchestration `generer-terraform`
//
// Un futur build-cursor.mjs / build-codex.mjs produira d'autres adaptateurs depuis le même core/.

import { readFileSync, writeFileSync, mkdirSync, rmSync, readdirSync } from 'node:fs';
import { dirname, join, basename } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const CORE = join(ROOT, 'core');
const OUT = join(ROOT, 'adapters', 'claude-code');

// --- Regroupement de l'ontologie en skills de connaissance (preloadables) ---
const KNOWLEDGE_SKILLS = [
  {
    name: 'ontologie-terraform-avm',
    description:
      "Règles non négociables (constitution), fondations Terraform et usage des Azure Verified Modules. Connaissance transversale du harness Terraform.",
    sources: ['ontologie/constitution.md', 'ontologie/terraform-fondations.md', 'ontologie/avm-usage.md'],
  },
  {
    name: 'archetype-app-service-keyvault-storage',
    description:
      "Archétype App Service + Key Vault + Storage : briques AVM à mobiliser et leur câblage.",
    sources: ['ontologie/archetypes/app-service-keyvault-storage.md'],
  },
];

// --- Skill d'entrée : l'orchestration ---
const ORCHESTRATION_SKILL = {
  name: 'generer-terraform',
  description:
    "Lance le workflow complet du harness : demande d'architecture -> spec -> schéma DrawIO -> code Terraform -> vérification statique, avec validations humaines. À utiliser pour générer de l'infrastructure Terraform Azure.",
  source: 'workflow.md',
};

function parseFrontmatter(md) {
  const m = md.match(/^---\n([\s\S]*?)\n---\n?([\s\S]*)$/);
  if (!m) return { fm: {}, body: md };
  const fm = {};
  for (const line of m[1].split('\n')) {
    const mm = line.match(/^([\w-]+):\s*(.*)$/);
    if (!mm) continue;
    let v = mm[2].trim();
    if (v.startsWith('[') && v.endsWith(']')) {
      v = v.slice(1, -1).split(',').map((s) => s.trim()).filter(Boolean);
    }
    fm[mm[1]] = v;
  }
  return { fm, body: m[2] };
}

function readCore(rel) {
  return readFileSync(join(CORE, rel), 'utf8');
}

function buildAgents() {
  const dir = join(OUT, 'agents');
  rmSync(dir, { recursive: true, force: true });
  mkdirSync(dir, { recursive: true });
  const files = readdirSync(join(CORE, 'roles')).filter((f) => f.endsWith('.md')).sort();
  for (const f of files) {
    const { fm, body } = parseFrontmatter(readCore(join('roles', f)));
    const tools = Array.isArray(fm.tools) ? fm.tools.join(', ') : fm.tools;
    const needs = Array.isArray(fm.needs) ? fm.needs : fm.needs ? [fm.needs] : [];
    const head = ['---', `name: ${fm.name}`, `description: ${fm.description}`];
    if (tools) head.push(`tools: ${tools}`);
    if (needs.length) head.push(`skills: [${needs.join(', ')}]`);
    head.push('---', '');
    writeFileSync(join(dir, `${fm.name}.md`), head.join('\n') + body.trimStart());
    console.log(`agent  : ${fm.name}${needs.length ? `  (preload: ${needs.join(', ')})` : ''}`);
  }
}

function writeSkill(name, description, body) {
  const dir = join(OUT, 'skills', name);
  mkdirSync(dir, { recursive: true });
  const content = `---\nname: ${name}\ndescription: ${description}\n---\n\n${body.trim()}\n`;
  writeFileSync(join(dir, 'SKILL.md'), content);
  console.log(`skill  : ${name}`);
}

function buildSkills() {
  rmSync(join(OUT, 'skills'), { recursive: true, force: true });
  for (const s of KNOWLEDGE_SKILLS) {
    const body = s.sources.map((rel) => readCore(rel).trim()).join('\n\n---\n\n');
    writeSkill(s.name, s.description, body);
  }
  writeSkill(ORCHESTRATION_SKILL.name, ORCHESTRATION_SKILL.description, readCore(ORCHESTRATION_SKILL.source));
}

console.log('Build adaptateur Claude Code depuis core/ ...');
buildAgents();
buildSkills();
console.log('OK. Sortie : adapters/claude-code/{agents,skills}');
