---
name: asd-ste100
description: Use when asked to explain, simplify, summarize or translate text in ASD-STE100, "Simplified Technical English", "80% ASD-STE100" or "aircraft manual English", when text from the user must be easy to read and cannot be misread, or when an explanation should be delivered as a self-contained HTML page.
---

# ASD-STE100 explanations and HTML pages

Source: Andrej Karpathy's X post of 2 Oct 2026. Reading model output will take more of our time. His ladder, each step "even better" than the last: (1) writing in ASD-STE100, (2) diagrams, (3) HTML pages, (4) explainer videos. This skill covers steps 1 and 3, plus translation into step 1.

**Default mode is 80%** (Karpathy's own softening). Use full strict STE only when the user says "strict" or "100%". Full STE drops facts from text with many domain terms.

## Writing rules (80% mode)

- One idea per sentence. Instructions at most 20 words, descriptions at most 25. Paragraphs at most 6 sentences.
- Active voice. Simple tenses. No contractions, no semicolons, no dropped words, no Latin abbreviations (e.g., i.e., etc.).
- One word per meaning: pick "start" and never rotate with "begin" or "initiate". Prefer plain verbs: "use", "stop", "before".
- Noun clusters at most 3 words. No phrasal-verb slang ("spin up", "kick off").
- Procedures: command first, one action per sentence. Put WARNING or CAUTION before the step, command first, then the risk.

## Keep exactly as written

- Identifiers, code, paths, numbers, units, versions, product and domain terms. Do not replace a domain term with simpler words.
- Hedges and conditions: "possibly", "not verified", "only", "unless". Never turn a possibility into a fact. Shorter and wrong is a failure.
- If a simpler phrasing loses precision, keep the longer phrasing and add one line at the end: `Kept as-is: <what and why>`.

## Translation

Translate the meaning into English STE directly, not word by word. For a legal or official term with no clean English match, keep the original in brackets, so the user can say it on the phone or find it in a search: `tax office (Urząd Skarbowy)`. Do not add facts that are not in the source. If the target language is not English, apply the sentence rules only (short, active, one term per concept) and say that STE vocabulary does not apply.

## HTML page

Use when the user says "in HTML", "as a page", "explainer", or asks to understand a system, trade-off or calculation.

1. One self-contained `.html` file. Inline CSS and JS. No CDN, no network. Works offline, on mobile, with keyboard-accessible controls.
2. Text on the page follows the rules above.
3. Let the reader change one assumption and see the result. Show the formulas. List the assumptions visibly on the page.
4. Save to the path the user names, else `./explainer-<topic>.html`, then run `open` on it. Tell the user the path.
5. Say in one line that the page checks its own model, not the real system.

## Output

Return the rewritten text alone: no preamble, no mode announcement, no change summary. Show a before/after table or the rules applied only when the user asks.

## Not for

Marketing copy, creative writing, or text published in the user's own voice. STE is flat on purpose. Do not claim certified STE compliance: the official ~900-word dictionary is not applied.
