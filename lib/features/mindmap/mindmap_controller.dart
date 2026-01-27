import 'package:flutter/material.dart';
import '../../data/models/mindmap_model.dart';
import '../../data/repositories/mindmap_repository.dart';

class MindmapController extends ChangeNotifier {
  final MindmapRepository _repository = MindmapRepository();

  MindmapModel? _mindmap;
  bool _isLoading = false;
  String? _error;

  // Auto-save debounce
  DateTime? _lastChange;
  static const _autoSaveDelay = Duration(seconds: 2);

  MindmapModel? get mindmap => _mindmap;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMindmap(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _mindmap = await _repository.getMindmap(id);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void updateMindmap(MindmapModel mindmap) {
    _mindmap = mindmap;
    _scheduleAutoSave();
    notifyListeners();
  }

  void _scheduleAutoSave() {
    _lastChange = DateTime.now();
    Future.delayed(_autoSaveDelay, () {
      if (_lastChange != null &&
          DateTime.now().difference(_lastChange!) >= _autoSaveDelay) {
        _autoSave();
      }
    });
  }

  Future<void> _autoSave() async {
    if (_mindmap != null) {
      try {
        await _repository.saveMindmap(_mindmap!);
      } catch (e) {
        debugPrint('Auto-save failed: $e');
      }
    }
  }

  Future<void> save() async {
    if (_mindmap != null) {
      await _repository.saveMindmap(_mindmap!);
    }
  }
}
