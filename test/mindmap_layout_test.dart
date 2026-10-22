import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vipmind/core/utils/mindmap_layout.dart';
import 'package:vipmind/data/models/mindmap_model.dart';
import 'package:vipmind/data/models/node_model.dart';

/// Builds a tree: root -> [childA, childB, childC], childA -> grandChild.
Map<String, NodeModel> _tree() {
  NodeModel node(String id, {List<String> children = const [], String? parent}) {
    return NodeModel(
      id: id,
      text: id,
      position: Offset.zero,
      size: const Size(160, 60),
      childrenIds: List<String>.from(children),
      parentId: parent,
    );
  }

  return <String, NodeModel>{
    'root': node('root', children: ['a', 'b', 'c']),
    'a': node('a', children: ['a1'], parent: 'root'),
    'b': node('b', parent: 'root'),
    'c': node('c', parent: 'root'),
    'a1': node('a1', parent: 'a'),
  };
}

MindmapModel _mindmap(MindmapLayout layout) {
  final nodes = _tree();
  return MindmapModel(
    id: 'map-1',
    title: 'Layout test',
    ownerId: 'user-1',
    nodes: nodes,
    rootNodeId: 'root',
    layout: layout,
  );
}

void main() {
  group('MindmapLayoutEngine — common guarantees', () {
    for (final layout in MindmapLayout.values) {
      test('${layout.name}: keeps every node, no NaN, no node lost', () {
        final mindmap = _mindmap(layout);
        final before = mindmap.nodes.keys.toSet();

        MindmapLayoutEngine.apply(layout, mindmap.nodes, mindmap.rootNodeId);

        expect(mindmap.nodes.keys.toSet(), before);
        for (final node in mindmap.nodes.values) {
          expect(node.position.dx.isFinite, isTrue,
              reason: '${node.id} has non-finite dx');
          expect(node.position.dy.isFinite, isTrue,
              reason: '${node.id} has non-finite dy');
        }
      });
    }

    test('unknown root id is a no-op instead of a crash', () {
      final nodes = _tree();
      expect(
        () => MindmapLayoutEngine.apply(MindmapLayout.radial, nodes, 'nope'),
        returnsNormally,
      );
    });

    test('a child id that points at nothing is skipped', () {
      final nodes = _tree();
      nodes['root'] = nodes['root']!.copyWith(childrenIds: ['a', 'ghost', 'b']);
      expect(
        () => MindmapLayoutEngine.apply(MindmapLayout.tree, nodes, 'root'),
        returnsNormally,
      );
      expect(nodes.containsKey('ghost'), isFalse);
    });

    test('freeform leaves user positions untouched', () {
      final nodes = _tree();
      nodes['a'] = nodes['a']!.copyWith(position: const Offset(123, 456));
      final before = {
        for (final e in nodes.entries) e.key: e.value.position,
      };

      MindmapLayoutEngine.apply(MindmapLayout.freeform, nodes, 'root');

      for (final e in nodes.entries) {
        expect(e.value.position, before[e.key], reason: '${e.key} moved');
      }
    });
  });

  group('radial layout', () {
    test('keeps the root centre where the user left it', () {
      final nodes = _tree();
      nodes['root'] = nodes['root']!.copyWith(position: const Offset(700, 250));
      final rootCentreBefore = nodes['root']!.center;

      MindmapLayoutEngine.apply(MindmapLayout.radial, nodes, 'root');

      final centreAfter = nodes['root']!.center;
      expect((centreAfter - rootCentreBefore).distance, lessThan(0.001));
    });

    test('first-level children sit on the configured radius', () {
      final nodes = _tree();
      MindmapLayoutEngine.apply(MindmapLayout.radial, nodes, 'root');

      final centre = nodes['root']!.center;
      for (final id in ['a', 'b', 'c']) {
        final distance = (nodes[id]!.center - centre).distance;
        expect(distance, closeTo(MindmapLayoutEngine.radialRootRadius, 0.001),
            reason: '$id is not on the ring');
      }
    });

    test('children are spread over distinct angles', () {
      final nodes = _tree();
      MindmapLayoutEngine.apply(MindmapLayout.radial, nodes, 'root');

      final centre = nodes['root']!.center;
      double angleOf(String id) {
        final delta = nodes[id]!.center - centre;
        return delta.direction;
      }

      final angles = ['a', 'b', 'c'].map(angleOf).toList()..sort();
      expect(angles[1] - angles[0], greaterThan(0.1));
      expect(angles[2] - angles[1], greaterThan(0.1));
    });

    test('grandchildren are closer to their parent than the first ring', () {
      final nodes = _tree();
      MindmapLayoutEngine.apply(MindmapLayout.radial, nodes, 'root');

      final rootToChild = (nodes['a']!.center - nodes['root']!.center).distance;
      final childToGrandChild =
          (nodes['a1']!.center - nodes['a']!.center).distance;

      expect(childToGrandChild, lessThan(rootToChild));
      expect(childToGrandChild,
          closeTo(rootToChild * MindmapLayoutEngine.radialRadiusFalloff, 0.001));
    });
  });

  group('tree layout', () {
    test('depth increases left to right', () {
      final nodes = _tree();
      MindmapLayoutEngine.apply(MindmapLayout.tree, nodes, 'root');

      expect(nodes['root']!.position.dx, MindmapLayoutEngine.treeStartX);
      expect(nodes['a']!.position.dx,
          MindmapLayoutEngine.treeStartX + MindmapLayoutEngine.treeHorizontalSpacing);
      expect(nodes['a1']!.position.dx,
          MindmapLayoutEngine.treeStartX + 2 * MindmapLayoutEngine.treeHorizontalSpacing);
    });

    test('siblings never overlap vertically', () {
      final nodes = _tree();
      MindmapLayoutEngine.apply(MindmapLayout.tree, nodes, 'root');

      final siblings = ['a', 'b', 'c'].map((id) => nodes[id]!).toList()
        ..sort((x, y) => x.position.dy.compareTo(y.position.dy));

      for (var i = 1; i < siblings.length; i++) {
        final previousBottom =
            siblings[i - 1].position.dy + siblings[i - 1].size.height;
        expect(siblings[i].position.dy, greaterThanOrEqualTo(previousBottom),
            reason: '${siblings[i].id} overlaps ${siblings[i - 1].id}');
      }
    });

    test('a leaf sibling and a subtree sibling get the same gap', () {
      // Regression, and the reason `_layoutChildrenAsTree` must return a bottom
      // EDGE in both branches: an earlier version added treeVerticalSpacing
      // inside the leaf branch only, which produced a 160px gap after a leaf
      // sibling and a 110px gap after a subtree sibling.
      final withSubtree = _tree();
      MindmapLayoutEngine.apply(MindmapLayout.tree, withSubtree, 'root');
      final gapAfterSubtree =
          withSubtree['b']!.position.dy - withSubtree['a']!.position.dy;

      final flat = _tree();
      flat['a'] = flat['a']!.copyWith(childrenIds: []);
      MindmapLayoutEngine.apply(MindmapLayout.tree, flat, 'root');
      final gapAfterLeaf = flat['b']!.position.dy - flat['a']!.position.dy;

      final leafBottom = flat['a']!.position.dy + flat['a']!.size.height;

      // Printed because two attempts at this assertion failed with numbers that
      // did not match either version of the engine; the geometry is cheap to log
      // and ends the guessing.
      String dump(Map<String, NodeModel> nodes, List<String> ids) => ids
          .map((id) => '$id=${nodes[id]?.position.dy}(${nodes[id]?.size.height})')
          .join(' ');
      debugPrint('TREEGAP subtree: ${dump(withSubtree, const [
        'root',
        'a',
        'a1',
        'b',
        'c'
      ])}');
      debugPrint('TREEGAP flat: ${dump(flat, const ['root', 'a', 'b', 'c'])} '
          '| gapSubtree=$gapAfterSubtree gapLeaf=$gapAfterLeaf '
          'leafBottom=$leafBottom '
          'spacing=${MindmapLayoutEngine.treeVerticalSpacing}');

      expect(gapAfterLeaf, closeTo(gapAfterSubtree, 0.001),
          reason: 'the gap must not depend on whether the sibling has children');
      expect(gapAfterLeaf - leafBottom,
          closeTo(MindmapLayoutEngine.treeVerticalSpacing, 0.001),
          reason: 'the gap is node height + the configured spacing');
    });
  });

  group('org chart layout', () {
    test('children are placed below the root', () {
      final nodes = _tree();
      MindmapLayoutEngine.apply(MindmapLayout.orgChart, nodes, 'root');

      final rootBottom =
          nodes['root']!.position.dy + nodes['root']!.size.height;
      for (final id in ['a', 'b', 'c']) {
        expect(nodes[id]!.position.dy, greaterThan(rootBottom));
      }
    });

    test('the children row is centred on the root centre', () {
      final nodes = _tree();
      MindmapLayoutEngine.apply(MindmapLayout.orgChart, nodes, 'root');

      final centres = ['a', 'b', 'c']
          .map((id) => nodes[id]!.center.dx)
          .toList()
        ..sort();
      final rowCentre = (centres.first + centres.last) / 2;

      expect(rowCentre, closeTo(MindmapLayoutEngine.orgCenterX, 0.001));
    });

    test('siblings are spaced evenly and do not overlap', () {
      final nodes = _tree();
      MindmapLayoutEngine.apply(MindmapLayout.orgChart, nodes, 'root');

      final centres = ['a', 'b', 'c'].map((id) => nodes[id]!.center.dx).toList()
        ..sort();

      final gap1 = centres[1] - centres[0];
      final gap2 = centres[2] - centres[1];
      expect(gap1, closeTo(MindmapLayoutEngine.orgHorizontalSpacing, 0.001));
      expect(gap2, closeTo(MindmapLayoutEngine.orgHorizontalSpacing, 0.001));
      // Centres are 180 apart while nodes are 160 wide, so siblings get 20px of
      // breathing room instead of overlapping.
      expect(gap1 - nodes['a']!.size.width,
          closeTo(MindmapLayoutEngine.orgHorizontalSpacing - 160, 0.001));
      expect(gap1, greaterThan(nodes['a']!.size.width * 0.9));
    });
  });

  group('applyToMindmap', () {
    test('uses the layout stored on the model', () {
      final mindmap = _mindmap(MindmapLayout.orgChart);
      MindmapLayoutEngine.applyToMindmap(mindmap);

      expect(mindmap.nodes['root']!.position.dy, MindmapLayoutEngine.orgStartY);
      expect(mindmap.nodes['a']!.position.dy,
          greaterThan(mindmap.nodes['root']!.position.dy));
    });
  });
}
