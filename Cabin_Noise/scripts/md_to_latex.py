"""Writes a LaTeX copy of every Markdown document of the project to docs/latex/, so the two never differ.

    python scripts/md_to_latex.py                    # write docs/latex/*.tex
    python scripts/md_to_latex.py --mmdc PATH        # also render new Mermaid diagrams with mermaid-cli

The .tex files compile with XeLaTeX or LuaLaTeX (Unicode text, DejaVu fonts), e.g. `tectonic docs/latex/METHOD.tex`.
Mermaid diagrams become PNGs in docs/figures/mermaid/, named by a hash of their source, so an edited diagram
needs a new render (`--mmdc`); tests/test_latex_docs.py fails if a .tex file or a diagram is out of date.
Covers the Markdown these documents use: headings, paragraphs, bold / italic / code, links, images, tables,
nested bullet and numbered lists, block quotes, rules, fenced code and Mermaid blocks.
"""
from __future__ import annotations

import argparse
import hashlib
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "docs" / "latex"
MERMAID = ROOT / "docs" / "figures" / "mermaid"
DOCS = ["README.md", "METHOD.md", "VALIDATION.md", "VERIFICATION.md", "AUDIT.md", "projectPlan.md",
        "references/SOURCES.md"]

PREAMBLE = r"""%% Generated from {src} by scripts/md_to_latex.py - edit the Markdown, then re-run the script.
%% Compile with XeLaTeX or LuaLaTeX (e.g. tectonic {name}).
\documentclass[10pt,a4paper]{{article}}
\usepackage[margin=2cm]{{geometry}}
\usepackage{{fontspec}}
\setmainfont{{DejaVuSerif.ttf}}[BoldFont=DejaVuSerif-Bold.ttf, ItalicFont=DejaVuSerif-Italic.ttf,
  BoldItalicFont=DejaVuSerif-BoldItalic.ttf, Scale=0.92]
\setmonofont{{DejaVuSansMono.ttf}}[BoldFont=DejaVuSansMono-Bold.ttf, Scale=0.85]
\usepackage{{graphicx,longtable,array,enumitem,fvextra,xcolor}}
\usepackage[hidelinks]{{hyperref}}
\usepackage{{xurl}}
\setlist{{nosep,leftmargin=1.4em}}
\setlength{{\parindent}}{{0pt}}
\setlength{{\parskip}}{{0.5em}}
\renewcommand{{\arraystretch}}{{1.2}}
\begin{{document}}
"""

MONO_MISSING = {"≪": "<<", "≫": ">>"}     # not in DejaVu Sans Mono (code blocks only)
SPECIAL = {"\\": r"\textbackslash{}", "&": r"\&", "%": r"\%", "$": r"\$", "#": r"\#", "_": r"\_",
           "{": r"\{", "}": r"\}", "~": r"\textasciitilde{}", "^": r"\textasciicircum{}"}


def esc(s: str) -> str:
    return "".join(SPECIAL.get(ch, ch) for ch in s)


def esc_code(s: str) -> str:
    """Inline code: escaped, with break points after / . _ and every 8 characters of a long word (hashes),
    so it wraps in a table cell."""
    s = re.sub(r"[0-9A-Za-z]{17,}", lambda m: "\x01".join(re.findall(".{1,8}", m.group(0))), s)
    return re.sub(r"(/|\\_|\.)", r"\1\\allowbreak{}", esc(s)).replace("\x01", r"\allowbreak{}")


class Converter:
    def __init__(self, md_path: Path):
        self.md = md_path
        self.stem = md_path.stem
        self.diagrams: list[tuple[str, Path]] = []      # (mermaid source, png path)

    # ---- inline -----------------------------------------------------------------------
    def link_target(self, url: str) -> str:
        if re.match(r"[a-z]+://", url) or url.startswith("#"):
            return url
        path, _, frag = url.partition("#")
        target = (self.md.parent / path).resolve()
        if target.suffix == ".md":                       # the LaTeX copy of a document, built to PDF
            target = OUT / (target.stem + ".pdf")
        return os.path.relpath(target, OUT).replace("\\", "/") + (f"#{frag}" if frag else "")

    def inline(self, s: str) -> str:
        keep: list[str] = []

        def hold(tex: str) -> str:
            keep.append(tex)
            return f"\x00{len(keep) - 1}\x00"

        s = re.sub(r"`([^`]+)`", lambda m: hold(r"\texttt{" + esc_code(m.group(1)) + "}"), s)
        s = re.sub(r"!\[([^\]]*)\]\(([^)\s]+)\)", lambda m: hold(
            r"\includegraphics[width=0.8\linewidth]{" + self.link_target(m.group(2)) + "}"), s)
        s = re.sub(r"\[([^\]]+)\]\(([^)\s]+)\)", lambda m: hold(
            r"\href{" + self.link_target(m.group(2)).replace("%", r"\%").replace("#", r"\#") + "}{"
            + self.inline(m.group(1)) + "}"), s)
        s = re.sub(r"https?://[^\s)>|]+", lambda m: hold(r"\url{" + m.group(0) + "}"), s)
        s = re.sub(r"<br\s*/?>", lambda m: hold(r"\newline{}"), s)
        s = esc(s)
        s = re.sub(r"\*\*(.+?)\*\*", r"\\textbf{\1}", s)
        s = re.sub(r"(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?![\w*])", r"\\emph{\1}", s)
        while "\x00" in s:
            s = re.sub(r"\x00(\d+)\x00", lambda m: keep[int(m.group(1))], s)
        return s

    # ---- blocks -----------------------------------------------------------------------
    def table(self, rows: list[str]) -> str:
        def cells(r):
            r = r.strip().strip("|")
            parts, cur, code = [], "", False
            for ch in r:
                if ch == "`":
                    code = not code
                if ch == "|" and not code:
                    parts.append(cur)
                    cur = ""
                else:
                    cur += ch
            return [c.strip() for c in parts + [cur]]

        head, body = cells(rows[0]), [cells(r) for r in rows[2:]]
        n = len(head)
        body = [(b + [""] * n)[:n] for b in body]
        width = [max(len(r[i]) for r in [head] + body) + 4 for i in range(n)]
        width = [min(w, 70) for w in width]
        total = sum(width)
        avail = 1.0 - 0.03 * n
        spec = "".join(r">{\raggedright\arraybackslash}p{%.3f\linewidth}" % (avail * w / total) for w in width)
        out = [r"{\small", r"\begin{longtable}{" + spec + "}", r"\hline",
               " & ".join(r"\textbf{" + self.inline(c) + "}" for c in head) + r" \\", r"\hline", r"\endhead"]
        out += [" & ".join(self.inline(c) for c in r) + r" \\" for r in body]
        out += [r"\hline", r"\end{longtable}}"]
        return "\n".join(out)

    def mermaid(self, src: str) -> str:
        h = hashlib.sha1(src.encode("utf-8")).hexdigest()[:10]
        png = MERMAID / f"{self.stem}-{h}.png"
        self.diagrams.append((src, png))
        rel = os.path.relpath(png, OUT).replace("\\", "/")
        return (r"\begin{center}\includegraphics[width=\linewidth,height=0.3\textheight,keepaspectratio]{"
                + rel + r"}\end{center}")

    def convert(self) -> str:
        lines = self.md.read_text(encoding="utf-8").splitlines()
        out: list[str] = []
        para: list[str] = []
        lists: list[tuple[int, str]] = []                # open lists: (indent, itemize / enumerate)
        i = 0

        def flush():
            if para:
                out.append(self.inline(" ".join(p.strip() for p in para)))
                out.append("")
                para.clear()

        def close_lists(indent=-1):
            while lists and lists[-1][0] > indent:
                out.append(r"\end{" + lists.pop()[1] + "}")
            if not lists and out and out[-1] != "":
                out.append("")

        while i < len(lines):
            ln = lines[i]
            m_fence = re.match(r"^\s*```(\w*)", ln)
            m_head = re.match(r"^(#{1,4})\s+(.*)", ln)
            m_item = re.match(r"^(\s*)([-*]|\d+\.)\s+(.*)", ln)
            if m_fence:
                flush()
                lang, block = m_fence.group(1), []
                i += 1
                while i < len(lines) and not re.match(r"^\s*```\s*$", lines[i]):
                    block.append(lines[i])
                    i += 1
                close_lists()
                if lang == "mermaid":
                    out.append(self.mermaid("\n".join(block) + "\n"))
                else:
                    out += [r"\begin{Verbatim}[breaklines,fontsize=\small,frame=single,rulecolor=\color{gray}]"]
                    out += ["".join(MONO_MISSING.get(ch, ch) for ch in b) for b in block] + [r"\end{Verbatim}"]
                out.append("")
            elif m_head:
                flush()
                close_lists()
                level, text = len(m_head.group(1)), self.inline(m_head.group(2).strip())
                cmd = {1: None, 2: "section*", 3: "subsection*", 4: "subsubsection*"}[level]
                out.append(r"{\LARGE\bfseries " + text + r"\par}\bigskip" if cmd is None else
                           "\\" + cmd + "{" + text + "}")
                out.append("")
            elif ln.lstrip().startswith("|") and i + 1 < len(lines) and re.match(r"^\s*\|[\s:|-]+\|\s*$",
                                                                                     lines[i + 1]):
                flush()
                close_lists()
                rows = []
                while i < len(lines) and lines[i].lstrip().startswith("|"):
                    rows.append(lines[i])
                    i += 1
                out += [self.table(rows), ""]
                continue
            elif m_item:
                flush()
                indent, kind = len(m_item.group(1)), "enumerate" if m_item.group(2)[0].isdigit() else "itemize"
                close_lists(indent)
                if lists and lists[-1][0] == indent and lists[-1][1] != kind:   # bullets -> numbers: new list
                    out.append(r"\end{" + lists.pop()[1] + "}")
                if not lists or lists[-1][0] < indent:
                    if not lists and out and out[-1] != "":
                        out.append("")
                    lists.append((indent, kind))
                    out.append(r"\begin{" + kind + "}")
                text = [m_item.group(3)]
                while (i + 1 < len(lines) and lines[i + 1].strip() and not re.match(r"^\s*([-*]|\d+\.)\s+",
                                                                                     lines[i + 1])
                       and not lines[i + 1].lstrip().startswith(("|", "```", "#"))
                       and len(lines[i + 1]) - len(lines[i + 1].lstrip()) > indent):
                    i += 1
                    text.append(lines[i].strip())
                out.append(r"\item " + self.inline(" ".join(text)))
            elif ln.startswith(">"):
                flush()
                close_lists()
                quote = []
                while i < len(lines) and lines[i].startswith(">"):
                    quote.append(lines[i].lstrip("> ").strip())
                    i += 1
                out += [r"\begin{quote}", self.inline(" ".join(quote)), r"\end{quote}", ""]
                continue
            elif re.match(r"^\s*(---|\*\*\*)\s*$", ln):
                flush()
                close_lists()
                out += [r"\noindent\rule{\linewidth}{0.4pt}", ""]
            elif not ln.strip():
                flush()
                if lists:                                 # a blank line ends a list unless an item follows
                    j = i + 1
                    while j < len(lines) and not lines[j].strip():
                        j += 1
                    if j >= len(lines) or not re.match(r"^\s*([-*]|\d+\.)\s+", lines[j]):
                        close_lists()
            else:
                if lists and not (len(ln) - len(ln.lstrip()) > lists[-1][0]):
                    close_lists()
                para.append(ln)
            i += 1
        flush()
        close_lists()
        name = self.stem + ".tex"
        src = self.md.relative_to(ROOT).as_posix() if ROOT in self.md.parents else self.md.name
        body = "\n".join(out).strip() + "\n"
        body = re.sub(r"\n{3,}", "\n\n", body)
        return PREAMBLE.format(src=src, name=name) + "\n" + body + "\n\\end{document}\n"


def build(doc: str) -> tuple[str, Path, list[tuple[str, Path]]]:
    c = Converter(ROOT / doc)
    tex = c.convert()
    return tex, OUT / (c.stem + ".tex"), c.diagrams


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--mmdc", help="mermaid-cli executable, to render diagrams whose PNG is missing")
    a = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    missing = []
    wanted = set()
    for doc in DOCS:
        tex, path, diagrams = build(doc)
        path.write_text(tex, encoding="utf-8", newline="\n")
        print(f"wrote {path.relative_to(ROOT)}")
        for src, png in diagrams:
            wanted.add(png)
            if png.exists():
                continue
            if not a.mmdc:
                missing.append(png)
                continue
            MERMAID.mkdir(parents=True, exist_ok=True)
            with tempfile.TemporaryDirectory() as tmp:          # the diagram source never lands in the repo
                mmd = Path(tmp) / "diagram.mmd"
                mmd.write_text(src, encoding="utf-8")
                subprocess.run([a.mmdc, "-i", str(mmd), "-o", str(png), "-b", "white", "-s", "2"], check=True,
                               shell=sys.platform == "win32")
            print(f"rendered {png.relative_to(ROOT)}")
    for old in MERMAID.glob("*.png") if MERMAID.exists() else []:
        if old not in wanted:                            # a diagram whose source changed or was removed
            old.unlink()
            print(f"removed {old.relative_to(ROOT)}")
    if missing:
        sys.exit("Mermaid diagrams need rendering (re-run with --mmdc): " + ", ".join(p.name for p in missing))


if __name__ == "__main__":
    main()
