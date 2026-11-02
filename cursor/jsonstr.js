#!/usr/bin/env node
// jsonstr.js: edit a stringified-JSON value in a JSON or JSONC file as real JSON, then turn it back.
//
//   node jsonstr.js unstringify <file> <line>
//   node jsonstr.js restringify <file> <line>
//
// unstringify finds `"key": "<JSON object or array as a string>"` on <line> (1-based) and
// replaces the string with the pretty-printed JSON, under a warning comment that marks the block.
// restringify turns the marked block that contains <line> back into a one-line string.
//
// Tokens are copied as written, so numbers and escapes survive the round trip unchanged, and the
// string gets back its original layout (compact, 2 spaces, 4 spaces or tabs) when it had one.
// Run by the "Unstringify JSON" and "Restringify JSON" tasks in cursor/tasks.json.

"use strict";

const fs = require("node:fs");

const MARKER = "jsonstr:unstringified";
const MARKER_RE = /^\s*\/\/ jsonstr:unstringified ("(?:[^"\\]|\\.)*") style=(compact|2|4|tab)\b/;
// Layouts a stringified value can have, in detection order; null means compact.
const STYLES = [["compact", null], ["2", "  "], ["4", "    "], ["tab", "\t"]];
const STYLE_UNITS = new Map(STYLES);

// Tokens of text that JSON.parse has already accepted.
const JSON_TOKEN_RE = /\s+|"(?:[^"\\]|\\.)*"|[{}[\]:,]|[^\s"{}[\]:,]+/y;
// Tokens of one line of a JSONC file; the final "." takes any stray character.
const LINE_TOKEN_RE = /\s+|"(?:[^"\\]|\\.)*"|\/\/.*|\/\*.*?\*\/|[{}[\]:,]|[^\s"{}[\]:,/]+|./y;

function jsonTokens(text) {
    const tokens = [];
    JSON_TOKEN_RE.lastIndex = 0;
    for (let match; (match = JSON_TOKEN_RE.exec(text)) !== null; ) {
        if (!/^\s/.test(match[0])) tokens.push(match[0]);
    }
    return tokens;
}

function lineTokens(line) {
    const tokens = [];
    LINE_TOKEN_RE.lastIndex = 0;
    for (let match; (match = LINE_TOKEN_RE.exec(line)) !== null; ) {
        const text = match[0];
        if (/^\s/.test(text)) continue;
        const comment = text.startsWith("//") || text.startsWith("/*");
        tokens.push({ text, start: match.index, end: match.index + text.length, comment });
    }
    return tokens;
}

function isStringToken(text) {
    return text.length > 1 && text.startsWith('"');
}

// Lay out JSON tokens like JSON.stringify(value, null, unit): compact when unit is null,
// otherwise one entry per line, each line after the first prefixed with base.
function layout(tokens, unit, base = "") {
    if (unit === null) return tokens.join("");
    let out = "";
    let depth = 0;
    const newline = () => `\n${base}${unit.repeat(depth)}`;
    for (let i = 0; i < tokens.length; i++) {
        const token = tokens[i];
        if ((token === "{" && tokens[i + 1] === "}") || (token === "[" && tokens[i + 1] === "]")) {
            out += token + tokens[++i];
        } else if (token === "{" || token === "[") {
            depth++;
            out += token + newline();
        } else if (token === "}" || token === "]") {
            depth--;
            out += newline() + token;
        } else if (token === ",") {
            out += `,${newline()}`;
        } else if (token === ":") {
            out += ": ";
        } else {
            out += token;
        }
    }
    return out;
}

function detectStyle(text, tokens) {
    const style = STYLES.find(([, unit]) => layout(tokens, unit) === text);
    return style ? style[0] : null;
}

// Indent step of the file: a tab if the line uses tabs, else the smallest space indent (default 4).
function indentUnit(lines, indent) {
    if (indent.includes("\t")) return "\t";
    let smallest = 0;
    for (const line of lines) {
        const width = /^ */.exec(line)[0].length;
        if (width > 0 && width < line.length && (smallest === 0 || width < smallest)) smallest = width;
    }
    return " ".repeat(smallest || 4);
}

function unstringify(lines, index) {
    const line = lines[index];
    const tokens = lineTokens(line).filter((token) => !token.comment);
    for (let i = 0; i + 2 < tokens.length; i++) {
        const [key, colon, value] = tokens.slice(i, i + 3);
        if (!isStringToken(key.text) || colon.text !== ":" || !isStringToken(value.text)) continue;
        let inner;
        let parsed;
        try {
            inner = JSON.parse(value.text);
            parsed = JSON.parse(inner);
        } catch {
            continue;
        }
        if (parsed === null || typeof parsed !== "object") continue;

        const innerTokens = jsonTokens(inner);
        const style = detectStyle(inner, innerTokens);
        const indent = /^\s*/.exec(line)[0];
        const body = layout(innerTokens, indentUnit(lines, indent), indent);
        const marker =
            `${indent}// ${MARKER} ${key.text} style=${style ?? "compact"}. WARNING: this value is a ` +
            `JSON string in the real file. Run "Restringify JSON" (Alt+Shift+Cmd+J) before you use or commit this file.`;
        const replaced = line.slice(0, value.start) + body + line.slice(value.end);
        lines.splice(index, 1, marker, ...replaced.split("\n"));

        let message = `jsonstr: unstringified ${key.text} on line ${index + 1}.`;
        if (style === null) {
            message += " Its whitespace was not compact or a 2-space, 4-space or tab layout, so Restringify will write it compact.";
        }
        return message;
    }
    throw new Error(`line ${index + 1} has no "key": "<JSON object or array as a string>" value`);
}

// The block under the marker on lines[markerIndex]: the key line and the bracket that closes it.
function findBlock(lines, markerIndex) {
    const [, keyText, style] = MARKER_RE.exec(lines[markerIndex]);
    const keyIndex = markerIndex + 1;
    const keyTokens = keyIndex < lines.length ? lineTokens(lines[keyIndex]) : [];
    let open = null;
    for (let i = 0; i + 2 < keyTokens.length; i++) {
        const [key, colon, bracket] = keyTokens.slice(i, i + 3);
        if (key.text === keyText && colon.text === ":" && (bracket.text === "{" || bracket.text === "[")) open = bracket;
    }
    if (open === null) {
        throw new Error(`line ${keyIndex + 1} has no ${keyText}: { or [ under the jsonstr comment on line ${markerIndex + 1}`);
    }

    let depth = 0;
    for (let lineIndex = keyIndex; lineIndex < lines.length; lineIndex++) {
        for (const token of lineTokens(lines[lineIndex])) {
            if (lineIndex === keyIndex && token.start < open.start) continue;
            if (token.comment) {
                throw new Error(
                    `line ${lineIndex + 1}: comment inside the ${keyText} block. ` +
                        "Restringify the inner blocks first, or remove the comment.",
                );
            }
            if (token.text === "{" || token.text === "[") depth++;
            if (token.text === "}" || token.text === "]") depth--;
            if (depth === 0) return { keyText, style, keyIndex, open, closeIndex: lineIndex, close: token };
        }
    }
    throw new Error(`the ${keyText} block that starts on line ${keyIndex + 1} has no closing bracket`);
}

function restringify(lines, index) {
    for (let markerIndex = index; markerIndex >= 0; markerIndex--) {
        if (!MARKER_RE.test(lines[markerIndex])) continue;
        const block = findBlock(lines, markerIndex);
        if (block.closeIndex < index) continue; // That block ends above the cursor line.

        const { keyText, keyIndex, open, closeIndex, close } = block;
        const source =
            keyIndex === closeIndex
                ? lines[keyIndex].slice(open.start, close.end)
                : [lines[keyIndex].slice(open.start), ...lines.slice(keyIndex + 1, closeIndex), lines[closeIndex].slice(0, close.end)].join("\n");
        try {
            JSON.parse(source);
        } catch (error) {
            throw new Error(`the ${keyText} block on lines ${keyIndex + 1}-${closeIndex + 1} is not valid JSON: ${error.message}`);
        }
        const inner = layout(jsonTokens(source), STYLE_UNITS.get(block.style));
        const joined = lines[keyIndex].slice(0, open.start) + JSON.stringify(inner) + lines[closeIndex].slice(close.end);
        lines.splice(markerIndex, closeIndex - markerIndex + 1, joined);
        return `jsonstr: restringified ${keyText} (lines ${markerIndex + 1}-${closeIndex + 1}).`;
    }
    throw new Error(`line ${index + 1} is not inside an unstringified block (no "// ${MARKER}" comment above it)`);
}

function main(args) {
    const [mode, file, lineArg] = args;
    const line = Number(lineArg);
    if (args.length !== 3 || !["unstringify", "restringify"].includes(mode) || !Number.isInteger(line) || line < 1) {
        console.error("usage: jsonstr.js unstringify|restringify <file> <line>");
        return 2;
    }
    let text = fs.readFileSync(file, "utf8");
    const bom = text.startsWith("﻿") ? "﻿" : "";
    text = text.slice(bom.length);
    const eol = text.includes("\r\n") ? "\r\n" : "\n";
    const lines = text.split(/\r?\n/);
    if (line > lines.length) throw new Error(`${file} has only ${lines.length} lines`);

    const message = mode === "unstringify" ? unstringify(lines, line - 1) : restringify(lines, line - 1);
    fs.writeFileSync(file, bom + lines.join(eol));
    console.log(message);
    return 0;
}

try {
    process.exitCode = main(process.argv.slice(2));
} catch (error) {
    console.error(`jsonstr: ${error.message}`);
    process.exitCode = 1;
}
