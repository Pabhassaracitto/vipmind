import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vipmind/core/utils/firestore_converters.dart';
import 'package:vipmind/data/models/mindmap_model.dart';
import 'package:vipmind/data/models/template_model.dart';

/// The bundled template catalog is a shipped asset: if it is malformed the
/// Templates screen shows an error to every user. It used to be a 0-byte file.
void main() {
  late List<dynamic> raw;

  setUpAll(() {
    final file = File('assets/templates/default_templates.json');
    expect(file.existsSync(), isTrue,
        reason: 'assets/templates/default_templates.json must exist');
    expect(file.lengthSync(), greaterThan(0),
        reason: 'the template catalog must not be empty');
    raw = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  });

  test('catalog is a non-empty JSON array', () {
    expect(raw, isNotEmpty);
  });

  test('every entry parses into a TemplateModel with sane values', () {
    for (final item in raw) {
      final template = TemplateModel.fromJson(firestoreMap(item));

      expect(template.id, isNotEmpty);
      expect(template.name, isNotEmpty);
      expect(template.description, isNotEmpty);
      expect(template.nodes, isNotEmpty, reason: '${template.id} has no nodes');
      expect(template.rootNodeId, isNotEmpty);
      expect(template.nodes.containsKey(template.rootNodeId), isTrue,
          reason: '${template.id}: rootNodeId is not in nodes');
      expect(template.category, isIn(TemplateCategory.values));
      expect(template.layout, isIn(MindmapLayout.values));
      expect(template.style, isIn(MindmapStyle.values));
    }
  });

  test('ids are unique across the catalog', () {
    final ids = raw.map((e) => firestoreMap(e)['id']).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('every child id and parent id resolves to a real node', () {
    for (final item in raw) {
      final template = TemplateModel.fromJson(firestoreMap(item));
      for (final node in template.nodes.values) {
        for (final childId in node.childrenIds) {
          expect(template.nodes.containsKey(childId), isTrue,
              reason: '${template.id}: dangling child $childId');
        }
        if (node.parentId != null) {
          expect(template.nodes.containsKey(node.parentId), isTrue,
              reason: '${template.id}: dangling parent ${node.parentId}');
        }
      }
    }
  });

  test('the root of every template is reachable and at depth 0', () {
    for (final item in raw) {
      final template = TemplateModel.fromJson(firestoreMap(item));
      expect(template.nodes[template.rootNodeId]!.depth, 0,
          reason: '${template.id}: root is not depth 0');
    }
  });

  group('TemplateModel.createMindmap', () {
    late TemplateModel template;

    setUp(() {
      template = TemplateModel.fromJson(firestoreMap(raw.first));
    });

    test('copies every node with brand new ids', () {
      final map = template.createMindmap(title: 'My plan', ownerId: 'user-1');

      expect(map.nodes.length, template.nodes.length);
      expect(map.title, 'My plan');
      expect(map.ownerId, 'user-1');
      expect(map.templateId, template.id);

      final templateIds = template.nodes.keys.toSet();
      for (final id in map.nodes.keys) {
        expect(templateIds.contains(id), isFalse,
            reason: 'template node id leaked into the new map');
      }
    });

    test('re-links children/parents to the new ids', () {
      final map = template.createMindmap(title: 't', ownerId: 'o');
      final root = map.rootNode!;

      expect(root.childrenIds, isNotEmpty);
      for (final childId in root.childrenIds) {
        final child = map.nodes[childId];
        expect(child, isNotNull, reason: 'child $childId missing');
        expect(child!.parentId, root.id);
      }
    });

    test('recomputes depth so the map is not flat', () {
      final map = template.createMindmap(title: 't', ownerId: 'o');

      expect(map.rootNode!.depth, 0);
      for (final childId in map.rootNode!.childrenIds) {
        expect(map.nodes[childId]!.depth, 1,
            reason: 'first-level node kept the template depth');
      }
    });

    test('two maps from the same template share no ids', () {
      final a = template.createMindmap(title: 'a', ownerId: 'o');
      final b = template.createMindmap(title: 'b', ownerId: 'o');

      expect(a.id, isNot(b.id));
      expect(a.nodes.keys.toSet().intersection(b.nodes.keys.toSet()), isEmpty);
    });

    test('the produced map is JSON-encodable (it goes straight to Firestore)', () {
      final map = template.createMindmap(title: 't', ownerId: 'o');
      expect(() => jsonEncode(map.toJson()), returnsNormally);
    });
  });
}
