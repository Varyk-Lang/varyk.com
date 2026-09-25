#!/usr/bin/env bash
# Write a Markdown copy of every published page beside its HTML, and /llms.txt.
#
# Runs after `zola build`. Reads content/**/*.md, strips the TOML front matter
# and HTML comments, and writes public/<path>/index.md. Draft pages are skipped.
# Content must not use shortcodes: they would leak into the copies unexpanded.
# Also fails the build if the home page figure drifts from the borrowing example.
#
# Needs only bash and POSIX tools (awk, sed, grep, find, sort, cmp).
set -euo pipefail
cd "$(dirname "$0")/.."

CONTENT=content
PUBLIC=public
fail() { echo "agents.sh: $*" >&2; exit 1; }

tmp=$(mktemp -d "${TMPDIR:-/tmp}/varyk-agents.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

# Site-map order and grouping for llms.txt. "Blog" is every page under /blog/, newest first;
# anything not listed goes under "Other".
GROUP_NAMES=("Docs" "Project" "Blog" "Policies")
GROUP_URLS=(
  "/ /why/ /install/ /learn/ /learn/getting-started/ /learn/reference/ /learn/examples/"
  "/tools/ /design/ /design/roadmap/ /community/ /blog/"
  ""
  "/security/ /license/ /privacy/"
)

# toml_get KEY: the value of a top-level string key in the TOML on stdin (before the first [table]).
toml_get() {
  awk -v key="$1" '
    /^[ \t]*\[/ { exit }
    {
      line = $0
      sub(/^[ \t]+/, "", line)
      if (index(line, key) != 1) next
      rest = substr(line, length(key) + 1)
      if (rest !~ /^[ \t]*=/) next
      sub(/^[ \t]*=[ \t]*/, "", rest)
      if (substr(rest, 1, 1) == "\"") {
        v = ""
        for (i = 2; i <= length(rest); i++) {
          c = substr(rest, i, 1)
          if (c == "\\") { i++; v = v substr(rest, i, 1); continue }
          if (c == "\"") break
          v = v c
        }
        print v
      } else {
        sub(/[ \t]*(#.*)?$/, "", rest)
        print rest
      }
      exit
    }'
}

# 1. The home page figure is a marked-up copy of the borrowing example; it must match it exactly.
check_figure() {  # NAME LANG HEADING
  awk -v heading="### $3" -v fence="\`\`\`$2" '
    state == 0 && $0 == heading { state = 1; next }
    state == 1 { if ($0 == "") { state = 2; next } state = 0 }
    state == 2 { if ($0 == fence) { state = 3; next } state = 0 }
    state == 3 { if ($0 == "```") exit; print }
  ' "$CONTENT/learn/examples.md" > "$tmp/want"
  awk -v open="<pre data-copy=\"$1\"" '
    { text = text $0 "\n" }
    END {
      s = index(text, open); if (!s) exit 1
      text = substr(text, s + length(open))
      e = index(text, ">"); if (!e) exit 1                  # the rest of the <pre> tag, attributes included
      text = substr(text, e + 1)
      s = index(text, ">"); if (!s || substr(text, 1, 5) != "<code") exit 1
      text = substr(text, s + 1)
      e = index(text, "</code></pre>"); if (!e) exit 1
      text = substr(text, 1, e - 1)
      gsub(/<\/?mark>/, "", text)
      gsub(/&lt;/, "<", text); gsub(/&gt;/, ">", text); gsub(/&quot;/, "\"", text); gsub(/&#39;/, "'"'"'", text)
      gsub(/&amp;/, "\\&", text)
      printf "%s\n", text
    }' "$PUBLIC/index.html" > "$tmp/got" || fail "cannot find $1 in the built home page"
  [ -s "$tmp/want" ] || fail "cannot find $1 in $CONTENT/learn/examples.md"
  cmp -s "$tmp/want" "$tmp/got" || fail "the home page copy of $1 differs from $CONTENT/learn/examples.md"
}
check_figure borrowing.vr varyk borrowing.vr
check_figure borrowing.rs rust "generated Rust"

# The home template splits the rendered Markdown on "<h2" and "<h3" to build the numbered
# sections, so the counts must agree and the content must not contain those tags literally.
home_md="$CONTENT/_index.md"
h2_count=$(grep -c '^## ' "$home_md" || true)
band_count=$(grep -c '^\[\[extra\.bands\]\]' "$home_md" || true)
section_count=$(grep -c '<section class="band ' "$PUBLIC/index.html" || true)
if [ "$h2_count" != "$band_count" ] || [ "$h2_count" != "$section_count" ]; then
  fail "home page has $h2_count '##' headings, $band_count [[extra.bands]] entries, and $section_count rendered sections; they must match"
fi
if grep -qiE '<h[23][ >]' "$home_md"; then
  fail "$home_md must not contain a literal <h2 or <h3 tag; use ## and ### headings"
fi

# 2. A Markdown copy of every page.
: > "$tmp/pages"
while IFS= read -r md; do
  [ "$(head -n 1 "$md")" = "+++" ] || fail "$md has no front matter"
  end=$(awk 'NR > 1 && $0 == "+++" { print NR; exit }' "$md")
  [ -n "$end" ] || fail "$md has no front matter"
  sed -n "2,$((end - 1))p" "$md" > "$tmp/fm"
  tail -n "+$((end + 1))" "$md" > "$tmp/body"

  [ "$(toml_get draft < "$tmp/fm")" = "true" ] && continue
  if grep -Eq '\{[{%][[:space:]]*[A-Za-z0-9_]+\(' "$tmp/body"; then
    fail "$md uses a shortcode; the Markdown copy would leak it"
  fi

  rel=${md#"$CONTENT"/}
  dir=$(dirname "$rel"); [ "$dir" = "." ] && dir=""
  base=$(basename "$rel" .md)
  path=$dir; [ "$base" = "_index" ] || path=${dir:+$dir/}$base
  url="/${path:+$path/}"
  out="$PUBLIC/${path}"
  [ -f "$out/index.html" ] || fail "$md was not built at $url"

  title=$(toml_get title < "$tmp/fm")
  desc=$(toml_get description < "$tmp/fm")
  # Every page needs both: they become the copy's heading and the llms.txt entry.
  [ -n "$title" ] || fail "$md has no title in its front matter"
  [ -n "$desc" ] || fail "$md has no description in its front matter"
  # Strip HTML comments (with trailing spaces and one newline) and surrounding whitespace.
  awk -v title="$title" '
    { text = text $0 "\n" }
    END {
      out = ""
      while ((s = index(text, "<!--")) > 0) {
        out = out substr(text, 1, s - 1)
        rest = substr(text, s + 4)
        e = index(rest, "-->")
        if (!e) { out = out substr(text, s); text = ""; break }
        text = substr(rest, e + 3)
        sub(/^[ \t]*/, "", text)
        if (substr(text, 1, 1) == "\n") text = substr(text, 2)
      }
      out = out text
      sub(/^[ \t\r\n]+/, "", out)
      sub(/[ \t\r\n]+$/, "", out)
      printf "# %s\n\n%s\n", title, out
    }' "$tmp/body" > "$out/index.md"
  printf '%s\t%s\t%s\t%s\n' "$url" "$title" "$desc" "$(toml_get date < "$tmp/fm")" >> "$tmp/pages"
done < <(find "$CONTENT" -name '*.md' | LC_ALL=C sort)

# 3. llms.txt.
site_base=$(toml_get base_url < config.toml); site_base=${site_base%/}
site_desc=$(toml_get description < config.toml)
entry() { awk -F '\t' -v u="$1" -v b="$site_base" '$1 == u { printf "- [%s](%s%sindex.md): %s\n", $2, b, $1, $3 }' "$tmp/pages"; }
{
  printf '# Varyk\n\n> %s\n\n' "$site_desc"
  printf '%s\n' "Varyk is pre-0.1: syntax, diagnostic codes, and command-line flags may change until a 0.1 release. Every page below is also available as Markdown at the linked address."
  : > "$tmp/listed"
  for i in "${!GROUP_NAMES[@]}"; do
    lines=""
    urls=${GROUP_URLS[$i]}
    if [ "${GROUP_NAMES[$i]}" = "Blog" ]; then
      # Posts by date, newest first (ISO dates sort lexically), then by path.
      urls=$(awk -F '\t' '$1 ~ /^\/blog\/./' "$tmp/pages" | LC_ALL=C sort -t "$(printf '\t')" -k4,4r -k1,1 | cut -f 1)
    fi
    for u in $urls; do
      e=$(entry "$u")
      [ -n "$e" ] || continue
      lines="$lines$e"$'\n'
      echo "$u" >> "$tmp/listed"
    done
    # Each group is preceded by a blank line; entries end with a newline, so the file ends with exactly one.
    [ -n "$lines" ] && printf '\n## %s\n\n%s' "${GROUP_NAMES[$i]}" "$lines"
  done
  rest=$(cut -f 1 "$tmp/pages" | grep -vxF -f "$tmp/listed" | LC_ALL=C sort || true)
  if [ -n "$rest" ]; then
    printf '\n## Other\n\n'
    while IFS= read -r u; do entry "$u"; done <<< "$rest"
  fi
} > "$PUBLIC/llms.txt"

echo "agents.sh: wrote $(wc -l < "$tmp/pages" | tr -d ' ') Markdown copies and llms.txt"
