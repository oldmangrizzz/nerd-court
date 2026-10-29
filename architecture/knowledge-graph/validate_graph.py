"""Validate the source-backed Nerd Court/UATU architecture graph package.

This validates metadata, references, snapshot integrity, and declared status only.
It does NOT run, verify, or audit the behavior of any original application.
"""
from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path


class GraphError(ValueError):
    """The knowledge graph's recorded facts are internally inconsistent."""


def _read(path: Path) -> dict:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (FileNotFoundError, OSError, json.JSONDecodeError) as exc:
        raise GraphError(f"Cannot read graph JSON {path}: {exc}") from exc
    if not isinstance(data, dict):
        raise GraphError(f"Graph document must be an object: {path}")
    return data


def _unique_ids(nodes: list, label: str) -> set[str]:
    identifiers = [node.get("id") for node in nodes]
    if any(not isinstance(item, str) or not item for item in identifiers):
        raise GraphError(f"Empty or invalid node ID in {label}")
    if len(identifiers) != len(set(identifiers)):
        raise GraphError(f"Duplicate node ID in {label}")
    return set(identifiers)


def _check_edges(edges: list, ids: set[str], label: str) -> None:
    for edge in edges:
        if edge.get("from") not in ids or edge.get("to") not in ids:
            raise GraphError(f"Dangling edge in {label}: {edge}")


def validate_package(root: str | Path) -> dict:
    """Validate linked semantic graph and pinned source-tree graph artifacts.

    Returns machine-readable counts only when all checks succeed.
    """
    root = Path(root)
    semantic = _read(root / "semantic-graph.v1.json")
    bridges = _read(root / "semantic-file-bridges.v1.json")
    sem_nodes = semantic.get("nodes", [])
    sem_edges = semantic.get("edges", [])
    sem_ids = _unique_ids(sem_nodes, "semantic graph")
    _check_edges(sem_edges, sem_ids, "semantic graph")
    stats = semantic.get("stats", {})
    if stats.get("nodes") != len(sem_nodes) or stats.get("edges") != len(sem_edges):
        raise GraphError("Semantic graph declared totals do not match its contents")

    module_nodes = [node for node in sem_nodes if node.get("kind") == "module"]
    if any(n.get("status") != "file-present-not-runtime-verified" for n in module_nodes):
        raise GraphError("Source-present modules cannot be claimed runtime-verified")
    if any(n.get("status") != "planned" for n in sem_nodes if n.get("kind") in ("target", "test")):
        raise GraphError("Unimplemented target or acceptance test claimed as complete")

    pins = semantic.get("source_pins", [])
    pinned_by_repo = {pin.get("repository"): pin.get("commit") for pin in pins}
    if len(pinned_by_repo) != len(pins):
        raise GraphError("Duplicate repository pin")

    total_files = total_folders = total_tree_nodes = total_tree_edges = 0
    ids_all = set(sem_ids)
    actual_file_ids: set[str] = set()
    all_inventoried_files: dict[tuple[str, str], str] = {}
    seen_names: set[str] = set()

    for inventory_path in sorted((root / "sources").glob("*.inventory.json")):
        name = inventory_path.name.removesuffix(".inventory.json")
        if name in seen_names:
            raise GraphError(f"Repeated inventory for {name}")
        seen_names.add(name)
        inventory = _read(inventory_path)
        file_graph = _read(root / "file-graphs" / f"{name}.graph.json")
        repository = inventory.get("repository")
        snapshot_sha = inventory.get("commit")
        if pinned_by_repo.get(repository) != snapshot_sha:
            raise GraphError(f"Unpinned or conflicting source inventory: {name}")
        if file_graph.get("source_repository") != repository or file_graph.get("source_commit") != snapshot_sha:
            raise GraphError(f"File graph built from a different source snapshot: {name}")
        files = inventory.get("files", [])
        file_by_path = {entry.get("path"): entry.get("sha") for entry in files}
        if len(file_by_path) != len(files):
            raise GraphError(f"Repeated tracked path in inventory: {name}")
        file_nodes = file_graph.get("nodes", [])
        tree_edges = file_graph.get("edges", [])
        local_ids = _unique_ids(file_nodes, f"file graph {name}")
        root_id = f"repo:{name}"
        if root_id not in local_ids or root_id not in sem_ids:
            raise GraphError(f"Unlinked repository root: {name}")
        if root_id not in [n["id"] for n in file_nodes if n.get("type") == "repository"]:
            raise GraphError(f"Repository node has wrong type: {name}")
        _check_edges(tree_edges, local_ids, f"file graph {name}")
        if len(tree_edges) != len(file_nodes) - 1:
            raise GraphError(f"File graph is not a tree: {name}")
        incoming = Counter(e["to"] for e in tree_edges)
        if incoming[root_id] or any(incoming[nid] != 1 for nid in local_ids - {root_id}):
            raise GraphError(f"Source tree node has zero/multiple parents: {name}")
        if any(e.get("type") != "contains" for e in tree_edges):
            raise GraphError(f"Unexpected relationship in source tree: {name}")
        observed_files = [n for n in file_nodes if n.get("type") == "file"]
        observed_folders = [n for n in file_nodes if n.get("type") == "directory"]
        if len(observed_files) != len(files):
            raise GraphError(f"Missing/extra file node: {name}")
        for node in observed_files:
            expected_id = f"file:{name}:{node.get('path')}"
            if node["id"] != expected_id or file_by_path.get(node.get("path")) != node.get("sha"):
                raise GraphError(f"File path or git blob SHA mismatch: {name}/{node.get('path')}")
            actual_file_ids.add(node["id"])
        for path, sha in file_by_path.items():
            all_inventoried_files[(repository, path)] = sha
        count = file_graph.get("counts", {})
        if (count.get("files"), count.get("folders"), count.get("nodes"), count.get("edges")) != (
            len(observed_files), len(observed_folders), len(file_nodes), len(tree_edges)
        ):
            raise GraphError(f"File graph metadata counts incorrect: {name}")
        ids_all.update(local_ids)
        total_files += len(files)
        total_folders += len(observed_folders)
        total_tree_nodes += len(file_nodes)
        total_tree_edges += len(tree_edges)

    if set(pinned_by_repo) != {f"oldmangrizzz/{name}" for name in seen_names}:
        raise GraphError("Not every repository pin has exactly one inventory")

    bridge_edges = bridges.get("edges", [])
    _check_edges(bridge_edges, ids_all, "semantic-file bridges")
    by_module = Counter(e.get("from") for e in bridge_edges)
    if len(bridge_edges) != len(module_nodes) or any(by_module[node["id"]] != 1 for node in module_nodes):
        raise GraphError("Each reviewed source module needs exactly one source-file bridge")
    for e in bridge_edges:
        if e.get("relation") != "backed-by-source-file" or e.get("to") not in actual_file_ids:
            raise GraphError(f"Invalid source bridge: {e}")
    for node in module_nodes:
        full_repo, path = node.get("repository"), node.get("path")
        if (full_repo, path) not in all_inventoried_files:
            raise GraphError(f"Module points outside pinned sources: {node['id']}")
        name = full_repo.split("/")[-1]
        if f"file:{name}:{path}" not in {e["to"] for e in bridge_edges if e["from"] == node["id"]}:
            raise GraphError(f"Module-to-file bridge disagrees with exact source path: {node['id']}")

    return {
        "status": "passed", "scope": "metadata-integrity-only; no source code execution",
        "repositories": len(seen_names), "source_files": total_files,
        "folders": total_folders, "semantic_nodes": len(sem_nodes), "semantic_edges": len(sem_edges),
        "source_file_nodes": total_tree_nodes, "source_tree_edges": total_tree_edges,
        "semantic_source_bridges": len(bridge_edges), "unique_nodes": len(ids_all),
        "total_edges": len(sem_edges) + total_tree_edges + len(bridge_edges),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", nargs="?", default=".", help="Knowledge graph root folder")
    args = parser.parse_args()
    try:
        result = validate_package(args.root)
    except GraphError as error:
        parser.exit(1, f"Graph validation FAILED: {error}\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
