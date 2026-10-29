import copy
import json
import tempfile
import unittest
from pathlib import Path

from validate_graph import validate_package, GraphError


class ValidatePackageTests(unittest.TestCase):
    def setUp(self):
        self.workspace = tempfile.TemporaryDirectory()
        self.root = Path(self.workspace.name)
        (self.root / 'sources').mkdir()
        (self.root / 'file-graphs').mkdir()
        self.semantic = {
            'schema': 'nerd-court-knowledge-graph/v1',
            'source_pins': [{'repository': 'oldmangrizzz/demo', 'commit': 'a' * 40}],
            'stats': {'nodes': 3, 'edges': 2},
            'nodes': [
                {'id': 'repo:demo', 'kind': 'repository', 'status': 'repository-indexed'},
                {'id': 'mod:reader', 'kind': 'module', 'repository': 'oldmangrizzz/demo', 'path': 'src/reader.py', 'status': 'file-present-not-runtime-verified'},
                {'id': 'target:ready', 'kind': 'target', 'status': 'planned'},
            ],
            'edges': [
                {'from': 'repo:demo', 'to': 'mod:reader', 'relation': 'contains'},
                {'from': 'mod:reader', 'to': 'target:ready', 'relation': 'candidate-for'},
            ],
        }
        self.inventory = {
            'schema': 'nerd-court-source-inventory/v1',
            'repository': 'oldmangrizzz/demo',
            'branch': 'main',
            'commit': 'a' * 40,
            'files': [{'path': 'src/reader.py', 'sha': 'b' * 40, 'bytes': 123}],
        }
        self.filegraph = {
            'schema': 'nerd-court-source-file-graph/v1',
            'source_repository': 'oldmangrizzz/demo',
            'source_commit': 'a' * 40,
            'counts': {'files': 1, 'folders': 1, 'nodes': 3, 'edges': 2},
            'nodes': [
                {'id': 'repo:demo', 'type': 'repository'},
                {'id': 'dir:demo:src', 'type': 'directory'},
                {'id': 'file:demo:src/reader.py', 'type': 'file', 'path': 'src/reader.py', 'sha': 'b' * 40},
            ],
            'edges': [
                {'from': 'repo:demo', 'to': 'dir:demo:src', 'type': 'contains'},
                {'from': 'dir:demo:src', 'to': 'file:demo:src/reader.py', 'type': 'contains'},
            ],
        }
        self.bridge = {
            'schema': 'nerd-court-semantic-file-bridge/v1',
            'edges': [{'from': 'mod:reader', 'to': 'file:demo:src/reader.py', 'relation': 'backed-by-source-file'}],
        }
        self.write_all()

    def tearDown(self):
        self.workspace.cleanup()

    def put(self, path, obj):
        (self.root / path).write_text(json.dumps(obj), encoding='utf-8')

    def write_all(self):
        self.put('semantic-graph.v1.json', self.semantic)
        self.put('semantic-file-bridges.v1.json', self.bridge)
        self.put('sources/demo.inventory.json', self.inventory)
        self.put('file-graphs/demo.graph.json', self.filegraph)

    def test_valid_package_has_fully_linked_source_evidence(self):
        report = validate_package(self.root)
        self.assertEqual(report['status'], 'passed')
        self.assertEqual(report['source_files'], 1)
        self.assertEqual(report['unique_nodes'], 5)
        self.assertEqual(report['total_edges'], 5)
        self.assertEqual(report['semantic_source_bridges'], 1)

    def test_rejects_dangling_semantic_reference(self):
        self.semantic['edges'][1]['to'] = 'target:not-a-node'
        self.write_all()
        with self.assertRaises(GraphError):
            validate_package(self.root)

    def test_rejects_wrong_pinned_file_hash(self):
        self.filegraph['nodes'][2]['sha'] = 'c' * 40
        self.write_all()
        with self.assertRaises(GraphError):
            validate_package(self.root)

    def test_rejects_missing_source_bridge(self):
        self.bridge['edges'] = []
        self.write_all()
        with self.assertRaises(GraphError):
            validate_package(self.root)

    def test_rejects_multiple_parents_in_source_tree(self):
        self.filegraph['edges'].append({'from': 'repo:demo', 'to': 'file:demo:src/reader.py', 'type': 'contains'})
        self.filegraph['counts']['edges'] += 1
        self.write_all()
        with self.assertRaises(GraphError):
            validate_package(self.root)

    def test_rejects_target_misrepresented_as_runtime_verified(self):
        self.semantic['nodes'][2]['status'] = 'implemented'
        self.write_all()
        with self.assertRaises(GraphError):
            validate_package(self.root)


if __name__ == '__main__':
    unittest.main()
