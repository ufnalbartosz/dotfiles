const vscode = require('vscode');
const path = require('path');
const fs = require('fs');

function isTestFile(filePath) {
    return path.basename(filePath).startsWith('test_');
}

// src/foo/bar.py -> tests/foo/test_bar.py (preferred), tests/test_bar.py (fallback)
function toTestPath(srcPath, workspaceRoot) {
    const rel = path.relative(workspaceRoot, srcPath);
    const parts = rel.split(path.sep);
    const filename = parts.pop();
    const testName = 'test_' + filename;

    // Strip leading src/ segment if present
    if (parts[0] === 'src') parts.shift();

    const mirrored = path.join(workspaceRoot, 'tests', ...parts, testName);
    const flat = path.join(workspaceRoot, 'tests', testName);
    return { mirrored, flat };
}

// tests/foo/test_bar.py or tests/test_bar.py -> src/foo/bar.py
function toSrcPath(testPath, workspaceRoot) {
    const rel = path.relative(workspaceRoot, testPath);
    const parts = rel.split(path.sep); // ['tests', 'foo', 'test_bar.py']
    parts.shift(); // remove 'tests'
    const testName = parts.pop(); // 'test_bar.py'
    const srcName = testName.replace(/^test_/, '');

    // Try with mirrored path first (tests/foo -> src/foo), then bare
    const candidates = [
        path.join(workspaceRoot, 'src', ...parts, srcName),
        path.join(workspaceRoot, ...parts, srcName),
    ];
    return candidates;
}

function activate(context) {
    context.subscriptions.push(
        vscode.commands.registerCommand('test-navigator.jumpTest', async () => {
            const editor = vscode.window.activeTextEditor;
            if (!editor) return;

            const filePath = editor.document.uri.fsPath;
            const workspaceRoot = vscode.workspace.getWorkspaceFolder(editor.document.uri)?.uri.fsPath;
            if (!workspaceRoot) {
                vscode.window.showErrorMessage('Test Navigator: no workspace folder open');
                return;
            }

            let target;
            if (isTestFile(filePath)) {
                const candidates = toSrcPath(filePath, workspaceRoot);
                target = candidates.find(p => fs.existsSync(p));
            } else {
                const { mirrored, flat } = toTestPath(filePath, workspaceRoot);
                if (fs.existsSync(mirrored)) target = mirrored;
                else if (fs.existsSync(flat)) target = flat;
            }

            if (!target) {
                vscode.window.showErrorMessage('Test Navigator: no counterpart file found');
                return;
            }

            const doc = await vscode.workspace.openTextDocument(target);
            await vscode.window.showTextDocument(doc);
        })
    );

    context.subscriptions.push(
        vscode.commands.registerCommand('test-navigator.createTest', async () => {
            const editor = vscode.window.activeTextEditor;
            if (!editor) return;

            const filePath = editor.document.uri.fsPath;
            if (isTestFile(filePath)) {
                vscode.window.showErrorMessage('Test Navigator: already a test file');
                return;
            }

            const workspaceRoot = vscode.workspace.getWorkspaceFolder(editor.document.uri)?.uri.fsPath;
            if (!workspaceRoot) {
                vscode.window.showErrorMessage('Test Navigator: no workspace folder open');
                return;
            }

            const { mirrored } = toTestPath(filePath, workspaceRoot);
            if (fs.existsSync(mirrored)) {
                const doc = await vscode.workspace.openTextDocument(mirrored);
                await vscode.window.showTextDocument(doc);
                return;
            }

            fs.mkdirSync(path.dirname(mirrored), { recursive: true });
            const stub = 'import pytest\n\n\ndef test_placeholder():\n    pass\n';
            fs.writeFileSync(mirrored, stub);

            const doc = await vscode.workspace.openTextDocument(mirrored);
            await vscode.window.showTextDocument(doc);
        })
    );
}

function deactivate() {}

module.exports = { activate, deactivate };
