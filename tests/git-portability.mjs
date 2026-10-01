// Real Git contract on each native platform, with no shell authority.
import assert from 'node:assert/strict';
import {mkdtemp,mkdir,writeFile,rm,access} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join,resolve} from 'node:path';
import {execFileSync,spawnSync} from 'node:child_process';
const binary=process.env.KUJO_BIN;
assert.ok(binary,'Set KUJO_BIN to the native runtime');
const root=resolve('.'),directory=await mkdtemp(join(tmpdir(),'shipcheck portability '));
const repo=join(directory,"café repo's & $(touch PWNED)");
try {
 await mkdir(repo);
 const git=(...args)=>execFileSync('git',['-C',repo,...args],{encoding:'utf8'});
 git('init','-q');git('-c','user.name=Fixture','-c','user.email=fixture@example.invalid','commit','--allow-empty','-qm','portable fixture commit');
 git('config','color.ui','always');
 await writeFile(join(repo,'README.md'),'# Fixture\n\nInstall\nUsage\n');
 await writeFile(join(repo,'VERSION'),'1.2.3\n');await writeFile(join(repo,'CHANGELOG.md'),'Changes\n');
 await mkdir(join(repo,'tests'));await writeFile(join(repo,'tests','fixture.txt'),'test\n');
 for(const interpreter of [false,true]) {
  const run=(command,target=repo)=>spawnSync(binary,['run',join(root,'shipcheck.kujo'),'--untrusted','--allow-fs-read','--allow-process-exec','--allow-env-read',...(interpreter?['--interpreter']:[]),'--',command,'--dir',target,...(command==='release-note'?[]:['--format','json'])],{cwd:directory,env:{...process.env,KUJO_MODULE_PATH:root},encoding:'utf8',timeout:30000,maxBuffer:2*1024*1024});
  const scan=run('scan');assert.equal(scan.status,0,scan.stdout+scan.stderr);
  const data=JSON.parse(scan.stdout);assert.equal(data.summary.total_checks,16);
  assert.equal(data.checks.find(c=>c.name==='git-repo').passed,1);assert.equal(data.summary.gate_passed,1);
  assert.ok(data.summary.warnings>0);assert.equal(run('gate').status,0);
  const notes=run('release-note');assert.equal(notes.status,0,notes.stderr);
  assert.ok(notes.stdout.includes('portable fixture commit'));assert.ok(notes.stdout.includes('v1.2.3'));assert.ok(!notes.stdout.includes('\x1b'));
  const missing=run('gate',directory);assert.equal(missing.status,1,missing.stdout+missing.stderr);
  const failed=JSON.parse(missing.stdout);assert.equal(failed.checks.find(c=>c.name==='git-repo').passed,0);assert.equal(failed.summary.gate_passed,0);
  const outsideNotes=run('release-note',directory);assert.equal(outsideNotes.status,0);assert.ok(!outsideNotes.stdout.includes('## Recent Commits'));
  await assert.rejects(access(join(directory,'PWNED')));
 }
 console.log('PASS: VM and interpreter Git detection, release history, literal paths, warning-only and failing gates without shell authority');
} finally {await rm(directory,{recursive:true,force:true});}
