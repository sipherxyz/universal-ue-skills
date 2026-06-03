#!/usr/bin/env python3
"""Small GitHub helper for the S2 AI Eng Forge Review skill."""

from __future__ import annotations

import argparse
import fnmatch
import json
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


MARKER = "<!-- s2-ai-code-review -->"
DEFAULT_REPO = "sipherxyz/s2"
SKILL_DIR = Path(__file__).resolve().parents[1]
_CANDIDATE_REPO_ROOT = SKILL_DIR.parents[2] if SKILL_DIR.parents[1].name == ".codex" else None
DEFAULT_LOCAL_REPO = (
    str(_CANDIDATE_REPO_ROOT)
    if _CANDIDATE_REPO_ROOT and (_CANDIDATE_REPO_ROOT / "S2.uproject").exists()
    else "/Users/vu.truongduc/Projects/Huli/s2"
)
RULES_DIR = SKILL_DIR / "references" / "review-rules"
MANAGED_REACTIONS = {"confused", "eyes", "+1", "hooray"}
REACTION_ICONS = {
    "confused": "😕",
    "eyes": "👀",
    "+1": "👍",
    "hooray": "🎉",
}


@dataclass
class Comment:
    id: int
    body: str
    url: str


def run(args: list[str], *, text: bool = True) -> str:
    proc = subprocess.run(args, check=True, capture_output=True, text=text)
    return proc.stdout


def run_quiet(args: list[str]) -> None:
    subprocess.run(args, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, text=True)


def gh_json(args: list[str]) -> Any:
    return json.loads(run(["gh", *args]))


def repo_parts(repo: str) -> tuple[str, str]:
    owner, name = repo.split("/", 1)
    return owner, name


def fetch_pr(repo: str, pr: str) -> dict[str, Any]:
    return gh_json([
        "pr",
        "view",
        pr,
        "--repo",
        repo,
        "--json",
        "number,title,body,author,baseRefName,headRefName,headRefOid,files,commits",
    ])


def fetch_comments(repo: str, pr: str) -> list[dict[str, Any]]:
    owner, name = repo_parts(repo)
    return gh_json(["api", f"repos/{owner}/{name}/issues/{pr}/comments"])


def fetch_user_login() -> str:
    return gh_json(["api", "user"]).get("login", "")


def find_dashboard(comments: list[dict[str, Any]]) -> Comment | None:
    for comment in comments:
        body = comment.get("body") or ""
        if MARKER in body:
            return Comment(int(comment["id"]), body, comment.get("html_url", ""))
    return None


def collect(args: argparse.Namespace) -> int:
    out_dir = Path(args.out).expanduser().resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    pr = fetch_pr(args.repo, args.pr)
    comments = fetch_comments(args.repo, args.pr)
    dashboard = find_dashboard(comments)
    diff = run(["gh", "pr", "diff", args.pr, "--repo", args.repo, "--patch"])
    files = pr.get("files") or []

    (out_dir / "pr.json").write_text(json.dumps(pr, indent=2), encoding="utf-8")
    (out_dir / "comments.json").write_text(json.dumps(comments, indent=2), encoding="utf-8")
    (out_dir / "diff.patch").write_text(diff, encoding="utf-8")
    (out_dir / "previous_dashboard.md").write_text(dashboard.body if dashboard else "", encoding="utf-8")
    (out_dir / "changed_files.txt").write_text(
        "\n".join(file_info.get("path", "") for file_info in files if file_info.get("path")) + "\n",
        encoding="utf-8")

    print(f"PR #{pr['number']}: {pr['title']}")
    print(f"Head: {pr['headRefOid']}")
    print(f"Files: {len(files)}")
    for file_info in files[: args.max_files]:
        print(f"- {file_info.get('path')} (+{file_info.get('additions', 0)} -{file_info.get('deletions', 0)})")
    if len(files) > args.max_files:
        print(f"- ... {len(files) - args.max_files} more")
    print(f"Dashboard: {'existing ' + dashboard.url if dashboard else 'none'}")
    print(f"Artifacts: {out_dir}")
    return 0


def parse_frontmatter(path: Path) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        return {}
    end = text.find("\n---", 4)
    if end < 0:
        return {}
    data: dict[str, Any] = {}
    current_key = ""
    for raw_line in text[4:end].splitlines():
        line = raw_line.rstrip()
        if not line.strip():
            continue
        if line.lstrip().startswith("- ") and current_key:
            data.setdefault(current_key, []).append(line.split("- ", 1)[1].strip().strip('"'))
            continue
        if ":" in line:
            key, value = line.split(":", 1)
            current_key = key.strip()
            value = value.strip().strip('"')
            data[current_key] = value if value else []
    return data


def rule_files() -> list[Path]:
    if not RULES_DIR.exists():
        return []
    return sorted(path for path in RULES_DIR.glob("*.md") if not path.name.startswith("_"))


def changed_files(args: argparse.Namespace) -> list[str]:
    if args.artifacts:
        pr_json = Path(args.artifacts).expanduser().resolve() / "pr.json"
        if pr_json.exists():
            pr = json.loads(pr_json.read_text(encoding="utf-8"))
            return [item["path"] for item in pr.get("files", [])]
    pr = fetch_pr(args.repo, args.pr)
    return [item["path"] for item in pr.get("files", [])]


def rules(args: argparse.Namespace) -> int:
    files = changed_files(args)
    selected: list[tuple[Path, str]] = []
    for path in rule_files():
        meta = parse_frontmatter(path)
        globs = meta.get("globs") or []
        if isinstance(globs, str):
            globs = [globs]
        if meta.get("always") == "true":
            selected.append((path, "always"))
            continue
        matches = sorted({file for file in files for pattern in globs if fnmatch.fnmatch(file, pattern)})
        if matches:
            reason = ", ".join(matches[:3])
            if len(matches) > 3:
                reason += f", +{len(matches) - 3} more"
            selected.append((path, reason))

    if args.paths_only:
        for path, _reason in selected:
            print(path)
        return 0

    output_lines = ["Rule files to read:"]
    if selected:
        for path, reason in selected:
            output_lines.append(f"- {path} ({reason})")
    else:
        output_lines.append("- None")

    output = "\n".join(output_lines)
    print(output)
    if args.artifacts:
        out_path = Path(args.artifacts).expanduser().resolve() / "rule_files.txt"
        out_path.write_text(output + "\n", encoding="utf-8")
        json_path = Path(args.artifacts).expanduser().resolve() / "selected_rules.json"
        json_path.write_text(
            json.dumps(
                [{"path": str(path), "reason": reason} for path, reason in selected],
                indent=2),
            encoding="utf-8")
    return 0


def sparse_checkout_paths(files: list[str]) -> list[str]:
    keep: set[str] = set()
    for file_path in files:
        if not file_path or file_path.endswith("/"):
            continue
        keep.add(file_path)
        if file_path.endswith((".h", ".hpp", ".cpp", ".cxx", ".cs", ".Build.cs", ".Target.cs", ".uplugin", ".uproject", ".md", ".json", ".ini")):
            parent = str(Path(file_path).parent)
            if parent and parent != ".":
                keep.add(parent + "/*")
    return sorted(keep)


def checkout(args: argparse.Namespace) -> int:
    artifacts = Path(args.artifacts).expanduser().resolve() if args.artifacts else None
    pr = json.loads((artifacts / "pr.json").read_text(encoding="utf-8")) if artifacts and (artifacts / "pr.json").exists() else fetch_pr(args.repo, args.pr)
    files = [item["path"] for item in pr.get("files", []) if item.get("path")]
    head = pr["headRefOid"]
    local_repo = Path(args.local_repo).expanduser().resolve()
    worktree = Path(args.worktree or f"/tmp/s2-pr-{args.pr}-wt").expanduser().resolve()
    tmp_ref = f"refs/tmp/s2-ai-review-{args.pr}"

    if worktree.exists():
        if not args.force:
            print(f"Worktree already exists: {worktree}")
            print("Pass --force to recreate it.")
            return 2
        run_quiet(["git", "-C", str(local_repo), "worktree", "remove", "--force", str(worktree)])
        if worktree.exists():
            shutil.rmtree(worktree)

    run(["git", "-C", str(local_repo), "fetch", "origin", f"pull/{args.pr}/head:{tmp_ref}"])
    run(["git", "-C", str(local_repo), "worktree", "add", "--no-checkout", str(worktree), tmp_ref])
    run(["git", "-C", str(worktree), "sparse-checkout", "init", "--no-cone"])
    sparse_paths = sparse_checkout_paths(files)
    if sparse_paths:
        subprocess.run(
            ["git", "-C", str(worktree), "sparse-checkout", "set", "--stdin"],
            input="\n".join(sparse_paths) + "\n",
            text=True,
            check=True)
    run(["git", "-C", str(worktree), "checkout"])

    if artifacts:
        (artifacts / "worktree_path.txt").write_text(str(worktree) + "\n", encoding="utf-8")

    print(f"Worktree: {worktree}")
    print(f"Head: {head}")
    print(f"Sparse paths: {len(sparse_paths)}")
    return 0


def cleanup(args: argparse.Namespace) -> int:
    worktree: Path | None = None
    if args.worktree:
        worktree = Path(args.worktree).expanduser().resolve()
    elif args.artifacts:
        path_file = Path(args.artifacts).expanduser().resolve() / "worktree_path.txt"
        if path_file.exists():
            worktree = Path(path_file.read_text(encoding="utf-8").strip()).expanduser().resolve()

    if worktree and worktree.exists():
        run_quiet(["git", "-C", str(Path(args.local_repo).expanduser().resolve()), "worktree", "remove", "--force", str(worktree)])

    if args.pr:
        tmp_ref = f"refs/tmp/s2-ai-review-{args.pr}"
        run_quiet(["git", "-C", str(Path(args.local_repo).expanduser().resolve()), "update-ref", "-d", tmp_ref])

    print("Cleanup complete")
    return 0


def severity_rank(level: str) -> int:
    return {"P0": 0, "P1": 1, "P2": 2, "P3": 3}.get(level.upper(), 9)


def severity_label(level: str) -> str:
    labels = {
        "P0": "🚨 P0",
        "P1": "⚠️ P1",
        "P2": "🟡 P2",
        "P3": "💡 P3",
    }
    return labels.get(level.upper(), level)


def status_line(active: list[dict[str, Any]]) -> str:
    if not active:
        return "Looks Good"
    return "Needs Attention"


def desired_reaction(active: list[dict[str, Any]]) -> str:
    levels = {(finding.get("level") or "").upper() for finding in active}
    if "P0" in levels:
        return "confused"
    if "P1" in levels:
        return "eyes"
    if "P2" in levels or "P3" in levels:
        return "+1"
    return "hooray"


def reaction_for_body(body: str) -> str:
    active_counts: dict[str, int] = {}
    for level in ("P0", "P1", "P2", "P3"):
        match = re.search(rf"\|\s*[^|\n]*{level}\s*\|\s*(\d+)\s*\|", body)
        active_counts[level] = int(match.group(1)) if match else 0

    if active_counts.get("P0", 0) > 0:
        return "confused"
    if active_counts.get("P1", 0) > 0:
        return "eyes"
    if active_counts.get("P2", 0) > 0 or active_counts.get("P3", 0) > 0:
        return "+1"
    return "hooray"


def extract_rows(body: str, section: str) -> dict[str, dict[str, str]]:
    start = body.find(section)
    if start < 0:
        return {}
    next_section = body.find("\n**", start + len(section))
    chunk = body[start: next_section if next_section >= 0 else len(body)]
    rows: dict[str, dict[str, str]] = {}
    for line in chunk.splitlines():
        if line.startswith("|"):
            if "---" in line or "Key" in line:
                continue
            cells = [cell.strip() for cell in line.strip("|").split("|")]
            if len(cells) < 4:
                continue
            key_match = re.search(r"`([^`]+)`", cells[-1])
            if not key_match:
                continue
            rows[key_match.group(1)] = {
                "level": cells[0],
                "location": cells[1],
                "finding": cells[2],
                "key": key_match.group(1),
            }
            continue

        if line.startswith("- "):
            key_matches = re.findall(r"`([^`]+)`", line)
            key = key_matches[-1] if key_matches else ""
            level_match = re.search(r"(P[0-3])", line)
            location_match = re.search(r"(\[`[^`]+`\]\([^)]+\))", line)
            title_match = re.search(r"· \*\*(.+)\*\*$", line)
            if not key:
                continue
            rows[key] = {
                "level": level_match.group(1) if level_match else "",
                "location": location_match.group(1) if location_match else "",
                "finding": title_match.group(1) if title_match else "",
                "key": key,
            }
    return rows


def load_findings(path: str) -> dict[str, Any]:
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    data.setdefault("findings", [])
    data.setdefault("focus", [])
    return data


def link_for(repo: str, head: str, finding: dict[str, Any]) -> str:
    path = finding["path"]
    line = finding.get("line")
    label = f"{Path(path).name}:{line}" if line else Path(path).name
    suffix = f"#L{line}" if line else ""
    return f"[`{label}`](https://github.com/{repo}/blob/{head}/{path}{suffix})"


def render_finding_item(repo: str, head: str, finding: dict[str, Any]) -> list[str]:
    title = finding["title"]
    body = finding.get("body") or title
    return [
        f"- {severity_label(finding['level'])} · {link_for(repo, head, finding)} · `{finding['key']}` · **{title}**",
        "",
        f"  {body}",
    ]


def sync_reaction(repo: str, comment_id: int, body: str) -> str:
    owner, name = repo_parts(repo)
    desired = reaction_for_body(body)
    login = fetch_user_login()
    reactions = gh_json([
        "api",
        f"repos/{owner}/{name}/issues/comments/{comment_id}/reactions",
        "-H",
        "Accept: application/vnd.github+json",
    ])

    has_desired = False
    for reaction in reactions:
        if reaction.get("content") not in MANAGED_REACTIONS:
            continue
        if reaction.get("user", {}).get("login") != login:
            continue
        if reaction.get("content") == desired:
            has_desired = True
            continue
        run([
            "gh",
            "api",
            f"repos/{owner}/{name}/issues/comments/{comment_id}/reactions/{reaction['id']}",
            "-X",
            "DELETE",
            "-H",
            "Accept: application/vnd.github+json",
        ])

    if not has_desired:
        gh_json([
            "api",
            f"repos/{owner}/{name}/issues/comments/{comment_id}/reactions",
            "-X",
            "POST",
            "-H",
            "Accept: application/vnd.github+json",
            "-f",
            f"content={desired}",
        ])
    return desired


def normalize_finding(finding: dict[str, Any]) -> dict[str, Any]:
    level = (finding.get("level") or "P2").upper()
    key = finding.get("key")
    if not key:
        slug = re.sub(r"[^a-zA-Z0-9]+", "-", f"{finding.get('path', '')}-{finding.get('title', '')}").strip("-")
        key = f"{level}:{slug[:80]}"
    return {
        **finding,
        "level": level,
        "key": key,
        "title": finding.get("title") or finding.get("finding") or "Review finding",
    }


def render(args: argparse.Namespace) -> int:
    data = load_findings(args.findings)
    pr = fetch_pr(args.repo, args.pr)
    comments = fetch_comments(args.repo, args.pr)
    previous = find_dashboard(comments)
    previous_body = previous.body if previous else ""
    previous_active = extract_rows(previous_body, "**Active Findings**")
    previous_resolved = extract_rows(previous_body, "**Resolved Since Last Review**")

    head = data.get("head") or pr["headRefOid"]
    active = [normalize_finding(f) for f in data["findings"]]
    active.sort(key=lambda f: (severity_rank(f["level"]), f.get("path", ""), f.get("line") or 0))
    active_keys = {f["key"] for f in active}

    resolved: list[dict[str, Any]] = []
    for key, row in previous_active.items():
        if key not in active_keys:
            resolved.append({
                "level": row["level"].replace("🚨 ", "").replace("⚠️ ", "").replace("🟡 ", "").replace("💡 ", ""),
                "key": key,
                "location": row["location"],
                "title": data.get("resolved", {}).get(key) or row["finding"],
            })
    for key, row in previous_resolved.items():
        if key not in active_keys and key not in {r["key"] for r in resolved}:
            resolved.append({
                "level": row["level"].replace("✅ ", ""),
                "key": key,
                "location": row["location"],
                "title": row["finding"],
            })

    status = status_line(active)
    counts = {
        "P0": sum(1 for f in active if f["level"] == "P0"),
        "P1": sum(1 for f in active if f["level"] == "P1"),
        "P2": sum(1 for f in active if f["level"] == "P2"),
        "P3": sum(1 for f in active if f["level"] == "P3"),
        "R0": sum(1 for f in resolved if "P0" in f["level"]),
        "R1": sum(1 for f in resolved if "P1" in f["level"]),
        "R2": sum(1 for f in resolved if "P2" in f["level"]),
        "R3": sum(1 for f in resolved if "P3" in f["level"]),
    }

    lines = [
        f"## 🤖 AI Eng Forge Review #{pr['number']}",
        "",
        f"{REACTION_ICONS[desired_reaction(active)]} **{status}** · PR #{pr['number']}",
        "",
    ]
    if active:
        lines.append(f"Updated review for head `{head}`. This dashboard is the single source of truth for AI Eng Forge Review findings on this PR.")
    else:
        lines.append(f"Updated review for head `{head}`. I reviewed the readable code changes and did not find remaining blocking code-review issues.")
    lines.extend([
        "",
        "| Level | Active | Resolved |",
        "| --- | ---: | ---: |",
        f"| 🚨 Critical / P0 | {counts['P0']} | {counts['R0']} |",
        f"| ⚠️ Warning / P1 | {counts['P1']} | {counts['R1']} |",
        f"| 🟡 Note / P2 | {counts['P2']} | {counts['R2']} |",
        f"| 💡 Suggestion / P3 | {counts['P3']} | {counts['R3']} |",
        "",
        "**Active Findings**",
    ])
    if active:
        for finding in active:
            lines.extend(render_finding_item(args.repo, head, finding))
    else:
        lines.append("- None.")

    lines.extend(["", "**Resolved Since Last Review**"])
    if resolved:
        for item in resolved:
            lines.append(f"- ✅ **{item['level']}** · {item['location']} · `{item['key']}` · **{item['title']}**")
    else:
        lines.append("- None.")

    focus = data.get("focus") or ["Readable code changes", "Regression and runtime risk", "Single-comment dashboard workflow"]
    lines.extend(["", "**Review focus**"])
    lines.extend(f"- {item}" for item in focus)

    lines.extend(["", MARKER, ""])
    body = "\n".join(lines)
    if args.out:
        Path(args.out).write_text(body, encoding="utf-8")
        print(args.out)
    else:
        print(body)
    return 0


def post(args: argparse.Namespace) -> int:
    body = Path(args.body).read_text(encoding="utf-8")
    owner, name = repo_parts(args.repo)
    comments = fetch_comments(args.repo, args.pr)
    dashboard = find_dashboard(comments)
    if dashboard:
        result = gh_json([
            "api",
            f"repos/{owner}/{name}/issues/comments/{dashboard.id}",
            "-X",
            "PATCH",
            "-f",
            f"body={body}",
        ])
        print(f"Updated {result['html_url']}")
    else:
        result = gh_json([
            "api",
            f"repos/{owner}/{name}/issues/{args.pr}/comments",
            "-f",
            f"body={body}",
        ])
        print(f"Created {result['html_url']}")
    reaction = sync_reaction(args.repo, int(result["id"]), body)
    print(f"Reaction: {reaction}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="AI Eng Forge Review GitHub dashboard helper")
    parser.add_argument("--repo", default=DEFAULT_REPO)
    sub = parser.add_subparsers(dest="command", required=True)

    collect_parser = sub.add_parser("collect")
    collect_parser.add_argument("pr")
    collect_parser.add_argument("--out", required=True)
    collect_parser.add_argument("--max-files", type=int, default=30)
    collect_parser.set_defaults(func=collect)

    rules_parser = sub.add_parser("rules")
    rules_parser.add_argument("pr")
    rules_parser.add_argument("--artifacts")
    rules_parser.add_argument("--paths-only", action="store_true")
    rules_parser.set_defaults(func=rules)

    checkout_parser = sub.add_parser("checkout")
    checkout_parser.add_argument("pr")
    checkout_parser.add_argument("--artifacts")
    checkout_parser.add_argument("--local-repo", default=DEFAULT_LOCAL_REPO)
    checkout_parser.add_argument("--worktree")
    checkout_parser.add_argument("--force", action="store_true")
    checkout_parser.set_defaults(func=checkout)

    cleanup_parser = sub.add_parser("cleanup")
    cleanup_parser.add_argument("pr", nargs="?")
    cleanup_parser.add_argument("--artifacts")
    cleanup_parser.add_argument("--local-repo", default=DEFAULT_LOCAL_REPO)
    cleanup_parser.add_argument("--worktree")
    cleanup_parser.set_defaults(func=cleanup)

    render_parser = sub.add_parser("render")
    render_parser.add_argument("pr")
    render_parser.add_argument("--findings", required=True)
    render_parser.add_argument("--out")
    render_parser.set_defaults(func=render)

    post_parser = sub.add_parser("post")
    post_parser.add_argument("pr")
    post_parser.add_argument("--body", required=True)
    post_parser.set_defaults(func=post)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
