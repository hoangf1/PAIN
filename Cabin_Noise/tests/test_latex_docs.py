"""The LaTeX copies in docs/latex/ match their Markdown documents (scripts/md_to_latex.py)."""
import importlib.util
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("md_to_latex", ROOT / "scripts" / "md_to_latex.py")
md_to_latex = importlib.util.module_from_spec(spec)
spec.loader.exec_module(md_to_latex)


def test_every_markdown_document_is_converted():
    out = subprocess.run(["git", "ls-files", "*.md"], cwd=ROOT, capture_output=True, text=True)
    if out.returncode:
        pytest.skip("not a git checkout")
    assert set(out.stdout.split()) == set(md_to_latex.DOCS)


@pytest.mark.parametrize("doc", md_to_latex.DOCS)
def test_latex_copy_is_up_to_date(doc):
    tex, path, diagrams = md_to_latex.build(doc)
    assert path.exists() and path.read_text(encoding="utf-8") == tex, \
        f"{path.name} is out of date: run python scripts/md_to_latex.py"
    missing = [png.name for _, png in diagrams if not png.exists()]
    assert not missing, f"Mermaid diagrams not rendered (python scripts/md_to_latex.py --mmdc ...): {missing}"


def test_conversion_of_markdown_constructs(tmp_path):
    md = tmp_path / "x.md"
    md.write_text("# T\n\nA **b** *c* `p_q/r` 50 % & $1 #2 [L](https://e.org)\n\n| h1 | h2 |\n|---|---|\n"
                  "| `a|b` | 2<br/>3 |\n\n- one\n  - two\n1. three\n", encoding="utf-8")
    tex = md_to_latex.Converter(md).convert()
    assert r"\textbf{b} \emph{c} \texttt{p\_\allowbreak{}q/\allowbreak{}r} 50 \% \& \$1 \#2 " \
           r"\href{https://e.org}{L}" in tex
    assert r"\texttt{a|b} & 2\newline{}3 \\" in tex                      # a pipe inside code stays in its cell
    assert tex.count(r"\begin{itemize}") == 2 and tex.count(r"\begin{enumerate}") == 1
    assert tex.count(r"\begin{") == tex.count(r"\end{")
