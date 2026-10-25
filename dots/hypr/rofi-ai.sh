#!/usr/bin/env bash

# Rofi AI tools menu — calls opencode with a free model in the background.
# Smart Copy (OCR/LaTeX/description), Ask Anything, Explain/Translate Selection.
# Results go to clipboard + a floating (dunst) notification preview.
# Bind: SUPER + SHIFT + SPACE (see hyprland.lua)

MODEL="opencode/deepseek-v4.1-flash-free"
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

    local out=""
    if [ -n "$img" ]; then
        out=$(cd "$HOME" && timeout "$TIMEOUT" \
            opencode run -m "$MODEL" -f "$img" --format json "$prompt" 2>/dev/null)
        [ -z "$out" ] && out=$(cd "$HOME" && timeout "$TIMEOUT" \
            opencode run --standalone -m "$MODEL" -f "$img" --format json "$prompt" 2>/dev/null)
    else
        out=$(cd "$HOME" && timeout "$TIMEOUT" \
            opencode run -m "$MODEL" --format json "$prompt" 2>/dev/null)
        [ -z "$out" ] && out=$(cd "$HOME" && timeout "$TIMEOUT" \
            opencode run --standalone -m "$MODEL" --format json "$prompt" 2>/dev/null)
    fi

    [ -z "$out" ] && return 1

    # Every run creates a one-shot session — extract its ID and delete it
    # right away so these tools leave no traces in storage.
    local sid answer
    sid=$(printf '%s\n' "$out" | head -n 1 | jq -r '.sessionID // empty' 2>/dev/null)
    answer=$(printf '%s\n' "$out" | jq -rs 'map(select(.type == "text") | .part.text) | join("")' 2>/dev/null)
    if [ -n "$sid" ]; then
        (cd "$HOME" && opencode session delete "$sid" >/dev/null 2>&1) || true
    fi

    [ -z "$answer" ] && return 1
    printf '%s' "$answer"
}

# --- Tools ------------------------------------------------------------------

smart_copy() {
    local region img
    region=$(slurp) || exit 0
    [ -z "$region" ] && exit 0

    img="/tmp/ai-ocr-$$.$RANDOM.png"
    trap 'rm -f "$img"' EXIT

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
    local body html
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
</style>
<script>
window.MathJax = { options: { skipHtmlTags: ['script','noscript','style','textarea','pre','code'] } };
</script>
<script defer src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-chtml.js"></script>
<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
  mermaid.initialize({ startOnLoad: false, theme: 'neutral' });
  mermaid.run({ querySelector: 'pre.mermaid' }).catch(() => {});
</script>
</head>
<body>
HEAD
    if [ -n "$q" ]; then
        printf '<p class="q"><strong>Q:</strong> %s</p>\n' \
            "$(printf '%s' "$q" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g')" >> "$html"
    fi
    printf '%s\n' "$body" >> "$html"
    printf '</body>\n</html>\n' >> "$html"

    setsid -f firefox --new-window "$html" >/dev/null 2>&1
    # drop the temp file once the page has loaded — no traces left behind
    (sleep 5; rm -f "$html") &
}

ask_anything() {
    local q
    q=$(rofi -dmenu -p "Ask AI" -theme-str 'window {width: 40%;}' -filter "")
    [ -z "$q" ] && exit 0

    stage "🤔 Thinking…"
    local ans
    if ! ans=$(ask_ai "$q"); then
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
