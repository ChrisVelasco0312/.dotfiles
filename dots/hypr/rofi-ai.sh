#!/usr/bin/env bash

# Rofi AI tools menu — calls opencode with a free model in the background.
# Smart Copy (OCR/LaTeX/description), Ask Anything, Explain/Translate Selection.
# Results go to clipboard + a floating (dunst) notification preview.
# Bind: SUPER + SHIFT + SPACE (see hyprland.lua)

MODEL="opencode/deepseek-v4.1-flash-free"
# Paid twin — used automatically when the free quota is exhausted (429 free-limit).
FALLBACK_MODEL="opencode-go/deepseek-v4.1-flash"
TIMEOUT=60
TAG="rofi-ai"

# --- Notifications ----------------------------------------------------------

stage() {
    notify-send -h "string:x-dunst-stack-tag:$TAG" "AI Tools" "$1"
}

fail() {
    notify-send -u critical -h "string:x-dunst-stack-tag:$TAG" "AI Tools" "$1"
}

deliver() {
    local text="$1"
    printf '%s' "$text" | wl-copy
    local preview="${text:0:200}"
    [ "${#text}" -gt 200 ] && preview="${preview}…"
    notify-send -h "string:x-dunst-stack-tag:$TAG" "AI Tools ✅" \
        "$preview

📋 Copied to clipboard"
}

# --- opencode runner --------------------------------------------------------
# ask_ai [image_path] "prompt"  → prints answer text, returns 1 on failure.

ask_ai() {
    local img="" prompt
    if [ -n "${1-}" ] && [ -f "${1-}" ]; then
        img="$1"; prompt="$2"
    else
        prompt="$1"
    fi

    # Force markdown LaTeX on every call — models drift to \(..\) / \[..\] or
    # bare brackets, which pandoc's gfm does not parse as math (renders raw).
    prompt="${prompt}

Formatting rules (mandatory): all math MUST use markdown LaTeX delimiters — inline as \$...\$ and display as \$\$...\$\$. Never use \\(..\\), \\[..\\], or bare [ ] brackets for math."

    # Try the free model first (service, then --standalone), then the paid
    # fallback the same way. A failed call surfaces as empty output (service
    # down) or JSON with no text parts (e.g. 429 free-limit) — both fall
    # through to the next attempt.
    local out="" answer="" sid m mode
    for m in "$MODEL" "$FALLBACK_MODEL"; do
        if [ "$m" = "$FALLBACK_MODEL" ]; then
            stage "⚡ Free quota exhausted — switching to paid model…"
        fi
        for mode in "" "--standalone"; do
            if [ -n "$img" ]; then
                out=$(cd "$HOME" && timeout "$TIMEOUT" \
                    opencode run $mode -m "$m" -f "$img" --format json "$prompt" 2>/dev/null)
            else
                out=$(cd "$HOME" && timeout "$TIMEOUT" \
                    opencode run $mode -m "$m" --format json "$prompt" 2>/dev/null)
            fi
            [ -z "$out" ] && continue

            # Every run creates a one-shot session — extract its ID and delete
            # it right away so these tools leave no traces in storage.
            sid=$(printf '%s\n' "$out" | head -n 1 | jq -r '.sessionID // empty' 2>/dev/null)
            answer=$(printf '%s\n' "$out" | jq -rs 'map(select(.type == "text") | .part.text) | join("")' 2>/dev/null)
            if [ -n "$sid" ]; then
                (cd "$HOME" && opencode session delete "$sid" >/dev/null 2>&1) || true
            fi

            if [ -n "$answer" ]; then
                printf '%s' "$answer"
                return 0
            fi
        done
    done
    return 1
}

# --- Tools ------------------------------------------------------------------

smart_copy() {
    local region img
    region=$(slurp) || exit 0
    [ -z "$region" ] && exit 0

    img="/tmp/ai-ocr-$$.$RANDOM.png"
    trap "rm -f $img" EXIT

    stage "📸 Capturing…"
    if ! grim -g "$region" "$img"; then
        fail "Screenshot failed"
        exit 1
    fi

    stage "🤔 Reading image…"
    local ans
    if ! ans=$(ask_ai "$img" "Transcribe all visible text in this image exactly as written. Rules: render math using LaTeX (inline as \$...\$, display as \$\$...\$\$). If the image shows a diagram, pick the Mermaid type that matches its structure — do NOT default to flowchart: sequence of actors/messages over time → sequenceDiagram; classes with attributes/methods and inheritance → classDiagram; lifecycle/states with transitions → stateDiagram-v2; entities with keys and relationships → erDiagram; hierarchy/tree or org chart → flowchart TD; concept map with radial branches → mindmap; schedule with dates/durations → gantt; audience/opinion breakdown → pie; ordered steps/scores → journey; time periods → timeline; commit/branch history → gitGraph; generic nodes and edges → flowchart LR. Emit exactly one \`\`\`mermaid code block (ONLY the block, no commentary), transcribing all labels/names into it faithfully — never invent a diagram for plain text or photos. If there is no text and no diagram, describe the image in one short sentence. If there is nothing to transcribe, convert, or describe, reply with exactly: NONE"); then
        fail "Model call failed"
        exit 1
    fi

    if [ "$ans" = "NONE" ] || [ -z "$ans" ]; then
        stage "Nothing to copy — no text or content found"
        exit 0
    fi

    deliver "$ans"
}

preview_browser() {
    local ans="$1" q="${2-}"
    local body html esc_md
    # Normalize alternate math delimiters before pandoc: gfm only understands
    # $..$/$$..$$, and markdown eats the backslash of \[..\], leaving raw text.
    ans=$(printf '%s' "$ans" | sed -E 's/\\\[/\$\$/g; s/\\\]/\$\$/g; s/\\\(/\$/g; s/\\\)/\$/g')
    body=$(printf '%s\n' "$ans" | pandoc -f gfm+tex_math_dollars -t html --mathjax 2>/dev/null)
    if [ -z "$body" ]; then
        body="<pre>$(printf '%s' "$ans" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g')</pre>"
    fi

    html="/tmp/ai-answer-$$.$RANDOM.html"
    cat > "$html" <<'HEAD'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>AI Answer</title>
<style>
  body { font: 16px/1.65 system-ui, sans-serif; max-width: 860px; margin: 2rem auto;
         padding: 0 1.5rem; color: #1c1c1c; background: #fcfcfd; }
  .q { color: #666; border-bottom: 1px solid #e3e5e8; padding-bottom: .8rem; margin-bottom: 1.4rem; }
  pre { background: #f1f2f4; padding: .9rem 1rem; border-radius: 8px; overflow-x: auto; }
  code { font-family: ui-monospace, "JetBrains Mono", monospace; font-size: .92em; }
  :not(pre) > code { background: #eceef1; padding: .1em .35em; border-radius: 4px; }
  table { border-collapse: collapse; margin: 1em 0; }
  th, td { border: 1px solid #ccd0d5; padding: .4em .75em; }
  th { background: #f1f2f4; }
  blockquote { border-left: 4px solid #d5d8dc; margin-left: 0; padding-left: 1em; color: #555; }
  h1, h2, h3 { line-height: 1.25; margin-top: 1.4em; }
  img { max-width: 100%; }
  .mermaid { text-align: center; margin: 1.2em 0; }
  .bar { display: flex; gap: .5rem; justify-content: flex-end; margin-bottom: 1rem; }
  .btn { font: 13px system-ui, sans-serif; padding: .4rem .75rem; border: 1px solid #ccd0d5;
         border-radius: 6px; background: #fff; color: #333; cursor: pointer; }
  .btn:hover { background: #f1f2f4; }
  .btn:disabled { opacity: .7; cursor: default; }
  @media print { .no-print { display: none; } body { max-width: none; margin: 0; padding: 1cm; } }
</style>
<script>
window.MathJax = { options: { skipHtmlTags: ['script','noscript','style','textarea','pre','code'] } };
</script>
<script defer src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-chtml.js"></script>
<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
  mermaid.initialize({ startOnLoad: false, theme: 'neutral' });
  // pandoc wraps mermaid blocks in <code> and escapes --&gt; entities, which
  // breaks mermaid.run()'s innerHTML parsing — render from raw text instead.
  const blocks = document.querySelectorAll('pre.mermaid');
  for (let i = 0; i < blocks.length; i++) {
    const el = blocks[i];
    try {
      const { svg } = await mermaid.render('mmd-' + i, el.textContent);
      const wrap = document.createElement('div');
      wrap.className = 'mermaid';
      wrap.innerHTML = svg;
      el.replaceWith(wrap);
    } catch (e) {
      el.insertAdjacentHTML('beforebegin',
        '<p style="color:#b00">mermaid: ' + String(e.message || e) + '</p>');
    }
  }
</script>
</head>
<body>
HEAD
    esc_md=$(printf '%s' "$ans" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g')

    cat >> "$html" <<'TOOLS'
<div class="bar no-print">
  <button class="btn" onclick="window.print()" title="Open the print dialog — choose “Save as PDF”">⎙ Export PDF</button>
  <button class="btn" onclick="dlMd()" title="Download the markdown source as a .md file">⤓ Export Markdown</button>
  <button class="btn" onclick="copyMd(this)" title="Copy the markdown source to the clipboard">⧉ Copy Markdown</button>
</div>
TOOLS
    if [ -n "$q" ]; then
        printf '<p class="q"><strong>Q:</strong> %s</p>\n' \
            "$(printf '%s' "$q" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g')" >> "$html"
    fi
    printf '%s\n' "$body" >> "$html"
    # raw markdown source embedded in the page — export/copy work even after
    # the temp file is deleted, because everything lives in the DOM.
    printf '<textarea id="md-src" hidden>\n%s</textarea>\n' "$esc_md" >> "$html"
    cat >> "$html" <<'TOOLS'
<script>
function mdSrc() { return document.getElementById('md-src').value.replace(/^\n+/, ''); }
function flash(btn, msg) {
  var t = btn.textContent;
  btn.textContent = msg; btn.disabled = true;
  setTimeout(function () { btn.textContent = t; btn.disabled = false; }, 1500);
}
function copyMd(btn) {
  var text = mdSrc();
  function fallback() {
    var ta = document.createElement('textarea');
    ta.value = text; document.body.appendChild(ta); ta.select();
    try { document.execCommand('copy'); } catch (e) {}
    ta.remove(); flash(btn, '✓ Copied');
  }
  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(text).then(function () { flash(btn, '✓ Copied'); }, fallback);
  } else { fallback(); }
}
function dlMd() {
  var blob = new Blob([mdSrc()], { type: 'text/markdown;charset=utf-8' });
  var a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = 'ai-answer.md';
  document.body.appendChild(a); a.click(); a.remove();
  setTimeout(function () { URL.revokeObjectURL(a.href); }, 2000);
}
</script>
</body>
</html>
TOOLS

    setsid -f firefox --new-window "$html" >/dev/null 2>&1
    # drop the temp file once the page has loaded — export/copy still work
    # from the DOM afterwards, so no traces are left behind
    (sleep 10; rm -f "$html") &
}

ask_anything() {
    local q
    q=$(rofi -dmenu -p "Ask AI" -theme-str 'window {width: 40%; height: 10ch;}' -filter "")
    [ -z "$q" ] && exit 0

    # Optional context: screenshot, clipboard image, or clipboard text.
    local ctx_opts="󰍶  No context
󰆞  Screenshot region
󰥶  Image from clipboard
󰅍  Text selection (clipboard)"
    local ctx
    ctx=$(echo "$ctx_opts" | rofi -dmenu -p "Add context?" \
        -theme-str 'configuration { font: "JetBrainsMono Nerd Font 13"; }' \
        -theme-str 'window {width: 25%;}')
    [ -z "$ctx" ] && exit 0

    local img="" prompt="$q"
    case "$ctx" in
        *Screenshot*)
            local region
            region=$(slurp) || exit 0
            [ -z "$region" ] && exit 0
            img="/tmp/ai-ctx-$$.$RANDOM.png"
            trap "rm -f $img" EXIT
            stage "📸 Capturing…"
            grim -g "$region" "$img" || { fail "Screenshot failed"; exit 1; }
            prompt="Use the attached screenshot as context. Question: $q"
            ;;
        *Image*clipboard*)
            img="/tmp/ai-ctx-$$.$RANDOM.png"
            trap "rm -f $img" EXIT
            if ! wl-paste -t image/png > "$img" 2>/dev/null || [ ! -s "$img" ]; then
                fail "No image in clipboard"
                exit 1
            fi
            prompt="Use the attached image as context. Question: $q"
            ;;
        *Text*selection*)
            local sel
            sel=$(wl-paste 2>/dev/null)
            if [ -z "$sel" ]; then
                fail "Clipboard is empty"
                exit 1
            fi
            prompt="Context from clipboard:
$sel

Question: $q"
            ;;
    esac

    stage "🤔 Thinking…"
    local ans
    if [ -n "$img" ]; then
        ans=$(ask_ai "$img" "$prompt")
    else
        ans=$(ask_ai "$prompt")
    fi
    if [ -z "$ans" ]; then
        fail "Model call failed"
        exit 1
    fi

    # Preview in the browser: renders math, mermaid, tables — easy to copy from.
    stage "✅ Answer opened in Firefox"
    preview_browser "$ans" "$q"
}

explain_selection() {
    local sel
    sel=$(wl-paste 2>/dev/null)
    if [ -z "$sel" ]; then
        fail "Clipboard is empty"
        exit 1
    fi

    stage "🤔 Explaining…"
    local ans
    if ! ans=$(ask_ai "Explain the following text clearly and concisely. Keep the original language and any code or formatting intact:

$sel"); then
        fail "Model call failed"
        exit 1
    fi

    stage "✅ Answer opened in Firefox"
    preview_browser "$ans" "Explain: ${sel:0:200}"
}

translate_selection() {
    local sel
    sel=$(wl-paste 2>/dev/null)
    if [ -z "$sel" ]; then
        fail "Clipboard is empty"
        exit 1
    fi

    stage "🌍 Translating…"
    local ans
    if ! ans=$(ask_ai "Auto-detect the language of the following text and translate it to English. If it is already in English, translate it to Brazilian Portuguese. Output only the translation:

$sel"); then
        fail "Model call failed"
        exit 1
    fi

    stage "✅ Translation opened in Firefox"
    preview_browser "$ans" "Translate: ${sel:0:200}"
}

# --- Menu -------------------------------------------------------------------

OPTIONS="󱄺  Smart Copy (OCR)
󰌵  Ask Anything
󰂽  Explain Selection
󰗊  Translate Selection"

selected=$(echo "$OPTIONS" | rofi -dmenu -p "  AI Tools" \
    -theme-str 'configuration { font: "JetBrainsMono Nerd Font 13"; }' \
    -theme-str 'window {width: 25%; height: 25ch;}')

case "$selected" in
    *Smart*)   smart_copy ;;
    *Ask*)     ask_anything ;;
    *Explain*) explain_selection ;;
    *Translate*) translate_selection ;;
    *) exit 0 ;;
esac
