import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vipmind/core/utils/firestore_converters.dart';
import 'package:vipmind/data/models/anki_card_model.dart';
import 'package:vipmind/data/models/audio_note_model.dart';
import 'package:vipmind/data/models/connection_model.dart';
import 'package:vipmind/data/models/mindmap_model.dart';
import 'package:vipmind/data/models/node_model.dart';
import 'package:vipmind/data/models/template_model.dart';
import 'package:vipmind/data/models/user_model.dart';

/// Regression tests for the bug that made saved mindmaps unreadable:
///
/// `MindmapRepository.saveMindmap()` writes `FieldValue.serverTimestamp()`, so
/// Firestore returns a **Timestamp**, while every model used to read dates with
/// `DateTime.parse(...)`. Reading any saved map threw
/// `type 'Timestamp' is not a subtype of type 'String'`. The same class of bug
/// hit every double (Firestore returns `int` for whole numbers) and every
/// string list (`List<dynamic>` cannot be cast to `List<String>`).
void main() {
  group('firestore converters', () {
    test('dates accept Timestamp, ISO string, millis and null', () {
      final date = DateTime.utc(2026, 10, 22, 8, 30);

      expect(firestoreDate(Timestamp.fromDate(date)), date);
      expect(firestoreDate(date.toIso8601String()), date);
      expect(firestoreDate(date.millisecondsSinceEpoch), date);
      expect(firestoreDate(null), isNull);
      expect(firestoreDate(''), isNull);
      expect(firestoreDate('not a date'), isNull);
      expect(firestoreDateOr('not a date', date), date);
      expect(firestoreDateOr(null, date), date);
    });

    test('numbers accept int where a double is expected (and back)', () {
      expect(firestoreDouble(3), 3.0);
      expect(firestoreDouble(3.5), 3.5);
      expect(firestoreDouble(null, fallback: 2.0), 2.0);
      expect(firestoreDouble('1.25'), 1.25);
      expect(firestoreInt(3.0), 3);
      expect(firestoreInt(3.6), 4);
      expect(firestoreInt(null, fallback: 7), 7);
    });

    test('maps and lists survive the dynamic types Firestore returns', () {
      expect(firestoreMap({'a': 1}), {'a': 1});
      expect(firestoreMap(<Object, Object>{1: 'x'}), {'1': 'x'});
      expect(firestoreMap(null), isEmpty);
      expect(firestoreMapList([{'a': 1}, {'b': 2}]), [
        {'a': 1},
        {'b': 2}
      ]);
      expect(firestoreMapList('nope'), isEmpty);
      expect(firestoreStringList(['a', 2, true]), ['a', '2', 'true']);
      expect(firestoreStringList(null), isEmpty);
    });

    test('enums fall back instead of throwing on bad indexes', () {
      expect(firestoreEnum(1, NodeShape.values), NodeShape.ellipse);
      expect(firestoreEnum(99, NodeShape.values, fallback: NodeShape.diamond),
          NodeShape.diamond);
      expect(firestoreEnum(null, NodeType.values, fallback: NodeType.task),
          NodeType.task);
    });

    test('colours fall back to the brand blue', () {
      expect(firestoreColorValue(0xFF06D6A0), 0xFF06D6A0);
      expect(firestoreColorValue(null), 0xFF4A6FA5);
      expect(firestoreColorValue('4278638240'), 0xFF06D6A0);
    });
  });

  group('NodeModel', () {
    final reference = NodeModel(
      id: 'node-1',
      text: 'Central idea',
      description: 'with a description',
      position: const Offset(120, 80),
      size: const Size(180, 70),
      color: const Color(0xFF06D6A0),
      textColor: const Color(0xFFFFFFFF),
      shape: NodeShape.ellipse,
      type: NodeType.task,
      childrenIds: ['c1', 'c2'],
      parentId: 'p1',
      depth: 2,
      isExpanded: false,
      isAnkiCard: true,
      ankiFront: 'front',
      ankiBack: 'back',
      ankiInterval: 6,
      ankiNextReview: DateTime.utc(2026, 11, 1),
    );

    test('round-trips through JSON', () {
      final restored = NodeModel.fromJson(reference.toJson());

      expect(restored.id, reference.id);
      expect(restored.text, reference.text);
      expect(restored.description, reference.description);
      expect(restored.position, reference.position);
      expect(restored.size, reference.size);
      expect(restored.color.value, reference.color.value);
      expect(restored.shape, reference.shape);
      expect(restored.type, reference.type);
      expect(restored.childrenIds, reference.childrenIds);
      expect(restored.parentId, reference.parentId);
      expect(restored.depth, reference.depth);
      expect(restored.isExpanded, reference.isExpanded);
      expect(restored.isAnkiCard, isTrue);
      expect(restored.ankiInterval, 6);
      expect(restored.ankiNextReview, DateTime.utc(2026, 11, 1));
    });

    test('reads Firestore-shaped payloads (ints, Timestamps, dynamic lists)', () {
      final node = NodeModel.fromJson(<String, dynamic>{
        'id': 'node-2',
        'text': 'From Firestore',
        // Whole numbers come back as int from Firestore.
        'positionX': 10,
        'positionY': 20,
        'width': 150,
        'height': 60,
        'color': 4283068325,
        'textColor': -1,
        'shape': 0,
        'type': 3,
        'childrenIds': <dynamic>['a', 'b'],
        'depth': 1,
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 28)),
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 10, 22)),
        'audioNote': <String, dynamic>{
          'id': 'audio-1',
          'durationMs': 1500,
          'createdAt': Timestamp.fromDate(DateTime.utc(2026, 5, 5)),
        },
      });

      expect(node.position, const Offset(10, 20));
      expect(node.size, const Size(150, 60));
      expect(node.color.value, 0xFF4A6FA5);
      expect(node.textColor.value, 0xFFFFFFFF);
      expect(node.shape, NodeShape.rectangle);
      expect(node.type, NodeType.note);
      expect(node.childrenIds, ['a', 'b']);
      expect(node.createdAt, DateTime.utc(2026, 1, 28));
      expect(node.updatedAt, DateTime.utc(2026, 10, 22));
      expect(node.audioNote, isNotNull);
      expect(node.audioNote!.duration, const Duration(milliseconds: 1500));
    });

    test('toJson output is JSON-encodable (Firestore requirement)', () {
      expect(() => jsonEncode(reference.toJson()), returnsNormally);
    });
  });

  group('MindmapModel', () {
    test('reads a saved document whose dates are Firestore Timestamps', () {
      final map = MindmapModel.fromJson(<String, dynamic>{
        'id': 'map-1',
        'title': 'Saved map',
        'ownerId': 'user-1',
        'rootNodeId': 'root',
        'layout': 2,
        'style': 3,
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 2, 1)),
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 2, 2)),
        'collaboratorIds': <dynamic>['user-2'],
        'tags': <dynamic>['study'],
        'isFavorite': true,
        'nodes': <String, dynamic>{
          'root': <String, dynamic>{
            'id': 'root',
            'text': 'Root',
            'positionX': 0,
            'positionY': 0,
            'width': 180,
            'height': 80,
            'color': 4283068325,
            'textColor': 4294967295,
            'shape': 1,
            'type': 0,
            'childrenIds': <dynamic>['leaf'],
            'createdAt': Timestamp.fromDate(DateTime.utc(2026, 2, 1)),
            'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 2, 1)),
          },
        },
        'connections': <dynamic>[
          <String, dynamic>{
            'id': 'conn-1',
            'fromNodeId': 'root',
            'toNodeId': 'leaf',
            'color': 4278638240,
            'strokeWidth': 3,
            'style': 1,
            'type': 0,
          }
        ],
      });

      expect(map.title, 'Saved map');
      expect(map.createdAt, DateTime.utc(2026, 2, 1));
      expect(map.updatedAt, DateTime.utc(2026, 2, 2));
      expect(map.layout, MindmapLayout.orgChart);
      expect(map.style, MindmapStyle.colorful);
      expect(map.isFavorite, isTrue);
      expect(map.collaboratorIds, ['user-2']);
      expect(map.tags, ['study']);
      expect(map.nodes.keys, ['root']);
      expect(map.rootNode?.text, 'Root');
      expect(map.connections.single.strokeWidth, 3.0);
      expect(map.connections.single.color.value, 0xFF06D6A0);
    });

    test('round-trips through JSON', () {
      final original = MindmapModel.createNew(
        title: 'Round trip',
        ownerId: 'user-1',
        rootText: 'Start here',
      );
      original.connections.add(
        ConnectionModel(
          id: 'conn-1',
          fromNodeId: original.rootNodeId,
          toNodeId: original.rootNodeId,
        ),
      );

      final restored = MindmapModel.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.rootNodeId, original.rootNodeId);
      expect(restored.rootNode?.text, 'Start here');
      expect(restored.connections, hasLength(1));
    });

    test('createNew builds a usable single-node map', () {
      final map = MindmapModel.createNew(title: 't', ownerId: 'o');

      expect(map.nodes, hasLength(1));
      expect(map.rootNode, isNotNull);
      expect(map.rootNode!.text, 'Central Idea');
      expect(map.rootNodeId, map.rootNode!.id);
    });

    test('removeNode also removes descendants and their connections', () {
      final map = MindmapModel.createNew(title: 't', ownerId: 'o');
      final rootId = map.rootNodeId;

      final child = NodeModel(
        id: 'child',
        text: 'child',
        position: const Offset(200, 200),
      );
      final grandChild = NodeModel(
        id: 'grand',
        text: 'grand',
        position: const Offset(400, 200),
      );

      map.addNode(child, parentId: rootId);
      map.addNode(grandChild, parentId: 'child');
      map.connections.add(
        ConnectionModel(id: 'c1', fromNodeId: 'child', toNodeId: 'grand'),
      );

      expect(map.nodes, hasLength(3));

      map.removeNode('child');

      expect(map.nodes.keys, [rootId]);
      expect(map.connections, isEmpty);
      expect(map.nodes[rootId]!.childrenIds, isEmpty);
    });
  });

  group('other models', () {
    test('ConnectionModel defaults and round trip', () {
      final json = <String, dynamic>{
        'id': 'c',
        'fromNodeId': 'a',
        'toNodeId': 'b',
        // Missing colour/width/style → must fall back, not throw.
      };
      final connection = ConnectionModel.fromJson(json);

      expect(connection.color.value, 0xFF4A6FA5);
      expect(connection.strokeWidth, 2.0);
      expect(connection.style, ConnectionStyle.curved);
      expect(connection.type, ConnectionType.parent);
      expect(connection.copyWith(label: 'x').label, 'x');
    });

    test('AudioNoteModel reads millis as int or double', () {
      final note = AudioNoteModel.fromJson(<String, dynamic>{
        'id': 'a1',
        'durationMs': 2500.0,
        'createdAt': '2026-10-22T00:00:00.000Z',
      });
      expect(note.duration, const Duration(milliseconds: 2500));
      expect(note.createdAt.year, 2026);
    });

    test('UserModel reads stats that Firestore may return as doubles', () {
      final user = UserModel.fromJson(<String, dynamic>{
        'id': 'u1',
        'name': 'Nguyen',
        'email': 'n@example.com',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 3, 3)),
        'stats': <String, dynamic>{'maps': 4.0, 'nodes': 120},
      });

      expect(user.stats['maps'], 4);
      expect(user.stats['nodes'], 120);
      expect(user.createdAt, DateTime.utc(2026, 3, 3));
      expect(user.settings, isEmpty);
    });

    test('AnkiCardModel keeps SM-2 fields', () {
      final card = AnkiCardModel.fromJson(<String, dynamic>{
        'id': 'card-1',
        'front': 'What is 2+2?',
        'back': '4',
        'interval': 6,
        'easeFactor': 2.36,
        'repetitions': 2,
        'createdAt': '2026-10-01T00:00:00.000Z',
        'nextReview': '2026-10-22T00:00:00.000Z',
      });

      expect(card.easeFactor, closeTo(2.36, 0.0001));
      expect(card.interval, 6);
      expect(card.isDue, isTrue);
    });

    test('TemplateModel tolerates missing optional fields', () {
      final template = TemplateModel.fromJson(<String, dynamic>{
        'id': 'tpl',
        'name': 'Blank',
        'creatorId': 'system',
        'category': 99, // out of range → must not throw
        'createdAt': '2026-01-01T00:00:00.000Z',
      });

      expect(template.category, TemplateCategory.custom);
      expect(template.nodes, isEmpty);
      expect(template.rating, 0.0);
      expect(template.description, isEmpty);
    });
  });
}
