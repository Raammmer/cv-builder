import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/cv_data.dart';
import '../models/personal_info.dart';
import '../models/work_experience.dart';
import '../models/education.dart';
import '../models/skill.dart';
import '../models/project.dart';
import '../models/certification.dart';
import '../services/storage_service.dart';
import '../utils/sample_data.dart';

/// ViewModel responsible for managing CV state, mutations, and local persistence.
/// Follows MVVM architecture: View -> ViewModel -> Service / Model
class CvViewModel extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final _uuid = const Uuid();

  CvData _activeCv = SampleData.sampleCv;
  List<CvData> _savedCvs = [];
  bool _isLoading = false;

  // Getters exposed to the View
  CvData get activeCv => _activeCv;
  List<CvData> get savedCvs => _savedCvs;
  bool get isLoading => _isLoading;
  int get completenessScore => _activeCv.completenessScore;

  CvViewModel() {
    init();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final list = await _storageService.getAllCvs();
      if (list.isNotEmpty) {
        _savedCvs = list.map((cv) {
          if (cv.personalInfo.photoBase64.isNotEmpty) {
            final cleaned = cv.copyWith(
              personalInfo: cv.personalInfo.copyWith(photoBase64: ''),
            );
            _storageService.saveCv(cleaned);
            return cleaned;
          }
          return cv;
        }).toList();
        _activeCv = _savedCvs.first;
      } else {
        // First run: save sample CV as starting template
        _savedCvs = [SampleData.sampleCv];
        _activeCv = SampleData.sampleCv;
        await _storageService.saveCv(_activeCv);
      }
    } catch (e) {
      _activeCv = SampleData.sampleCv;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Actions invoked by the View ---

  void setActiveCv(CvData cv) {
    _activeCv = cv;
    notifyListeners();
  }

  void createNewCv({String title = 'My New Resume'}) {
    _activeCv = CvData(
      id: _uuid.v4(),
      title: title,
      personalInfo: PersonalInfo(),
      experiences: [],
      educations: [],
      skills: [],
      projects: [],
      certifications: [],
    );
    _savedCvs.insert(0, _activeCv);
    _storageService.saveCv(_activeCv);
    notifyListeners();
  }

  void loadSampleResume() {
    _activeCv = SampleData.sampleCv.copyWith(id: _uuid.v4(), title: 'Sample Tech Resume');
    _savedCvs.insert(0, _activeCv);
    _storageService.saveCv(_activeCv);
    notifyListeners();
  }

  Future<void> saveCurrentCv() async {
    final updated = _activeCv.copyWith(lastModified: DateTime.now());
    _activeCv = updated;
    final index = _savedCvs.indexWhere((c) => c.id == updated.id);
    if (index >= 0) {
      _savedCvs[index] = updated;
    } else {
      _savedCvs.add(updated);
    }
    await _storageService.saveCv(updated);
    notifyListeners();
  }

  /// Saves the current CV (or an optional source CV) as a brand new resume file.
  Future<CvData> saveAsNewCv({CvData? sourceCv, String? newTitle}) async {
    final base = sourceCv ?? _activeCv;
    final defaultTitle = base.title.endsWith('(Copy)')
        ? '${base.title} 2'
        : '${base.title} (Copy)';
    final title = (newTitle != null && newTitle.trim().isNotEmpty)
        ? newTitle.trim()
        : defaultTitle;

    final newCv = base.copyWith(
      id: _uuid.v4(),
      title: title,
      lastModified: DateTime.now(),
    );
    _savedCvs.insert(0, newCv);
    _activeCv = newCv;
    await _storageService.saveCv(newCv);
    notifyListeners();
    return newCv;
  }

  /// Duplicates an existing saved CV by its ID and saves it as a new resume.
  Future<CvData?> duplicateCv(String id, {String? newTitle}) async {
    final index = _savedCvs.indexWhere((c) => c.id == id);
    if (index == -1) return null;
    final source = _savedCvs[index];
    final defaultTitle = '${source.title} (Copy)';
    final title = (newTitle != null && newTitle.trim().isNotEmpty)
        ? newTitle.trim()
        : defaultTitle;
    final newCv = source.copyWith(
      id: _uuid.v4(),
      title: title,
      lastModified: DateTime.now(),
    );
    _savedCvs.insert(index + 1, newCv);
    _activeCv = newCv;
    await _storageService.saveCv(newCv);
    notifyListeners();
    return newCv;
  }

  Future<void> deleteCv(String id) async {
    _savedCvs.removeWhere((c) => c.id == id);
    await _storageService.deleteCv(id);
    if (_activeCv.id == id) {
      if (_savedCvs.isNotEmpty) {
        _activeCv = _savedCvs.first;
      } else {
        createNewCv();
      }
    }
    notifyListeners();
  }

  // --- Appearance & Template Mutations ---
  void setTemplate(String templateId) {
    _activeCv = _activeCv.copyWith(selectedTemplate: templateId);
    saveCurrentCv();
  }

  void setAccentColor(int colorHex) {
    _activeCv = _activeCv.copyWith(accentColorHex: colorHex);
    saveCurrentCv();
  }

  void setCvTitle(String newTitle) {
    _activeCv = _activeCv.copyWith(title: newTitle);
    saveCurrentCv();
  }

  // --- Personal Info Mutations ---
  void updatePersonalInfo(PersonalInfo info) {
    _activeCv = _activeCv.copyWith(personalInfo: info);
    saveCurrentCv();
  }

  void updateSummary(String summary) {
    _activeCv = _activeCv.copyWith(
      personalInfo: _activeCv.personalInfo.copyWith(summary: summary),
    );
    saveCurrentCv();
  }

  // --- Work Experience Mutations ---
  void addExperience(WorkExperience exp) {
    final list = List<WorkExperience>.from(_activeCv.experiences)..add(exp);
    _activeCv = _activeCv.copyWith(experiences: list);
    saveCurrentCv();
  }

  void updateExperience(WorkExperience exp) {
    final list = _activeCv.experiences.map((item) => item.id == exp.id ? exp : item).toList();
    _activeCv = _activeCv.copyWith(experiences: list);
    saveCurrentCv();
  }

  void deleteExperience(String id) {
    final list = _activeCv.experiences.where((item) => item.id != id).toList();
    _activeCv = _activeCv.copyWith(experiences: list);
    saveCurrentCv();
  }

  void addBullet(String expId, String bullet) {
    final list = _activeCv.experiences.map((exp) {
      if (exp.id == expId) {
        return exp.copyWith(bullets: List.from(exp.bullets)..add(bullet));
      }
      return exp;
    }).toList();
    _activeCv = _activeCv.copyWith(experiences: list);
    saveCurrentCv();
  }

  void updateBullet(String expId, int index, String newBullet) {
    final list = _activeCv.experiences.map((exp) {
      if (exp.id == expId && index < exp.bullets.length) {
        final b = List<String>.from(exp.bullets);
        b[index] = newBullet;
        return exp.copyWith(bullets: b);
      }
      return exp;
    }).toList();
    _activeCv = _activeCv.copyWith(experiences: list);
    saveCurrentCv();
  }

  void deleteBullet(String expId, int index) {
    final list = _activeCv.experiences.map((exp) {
      if (exp.id == expId && index < exp.bullets.length) {
        final b = List<String>.from(exp.bullets)..removeAt(index);
        return exp.copyWith(bullets: b);
      }
      return exp;
    }).toList();
    _activeCv = _activeCv.copyWith(experiences: list);
    saveCurrentCv();
  }

  // --- Education Mutations ---
  void addEducation(Education edu) {
    final list = List<Education>.from(_activeCv.educations)..add(edu);
    _activeCv = _activeCv.copyWith(educations: list);
    saveCurrentCv();
  }

  void updateEducation(Education edu) {
    final list = _activeCv.educations.map((item) => item.id == edu.id ? edu : item).toList();
    _activeCv = _activeCv.copyWith(educations: list);
    saveCurrentCv();
  }

  void deleteEducation(String id) {
    final list = _activeCv.educations.where((item) => item.id != id).toList();
    _activeCv = _activeCv.copyWith(educations: list);
    saveCurrentCv();
  }

  // --- Skills Mutations ---
  void addSkill(Skill skill) {
    final list = List<Skill>.from(_activeCv.skills)..add(skill);
    _activeCv = _activeCv.copyWith(skills: list);
    saveCurrentCv();
  }

  void deleteSkill(String id) {
    final list = _activeCv.skills.where((item) => item.id != id).toList();
    _activeCv = _activeCv.copyWith(skills: list);
    saveCurrentCv();
  }

  // --- Projects Mutations ---
  void addProject(Project proj) {
    final list = List<Project>.from(_activeCv.projects)..add(proj);
    _activeCv = _activeCv.copyWith(projects: list);
    saveCurrentCv();
  }

  void updateProject(Project proj) {
    final list = _activeCv.projects.map((item) => item.id == proj.id ? proj : item).toList();
    _activeCv = _activeCv.copyWith(projects: list);
    saveCurrentCv();
  }

  void deleteProject(String id) {
    final list = _activeCv.projects.where((item) => item.id != id).toList();
    _activeCv = _activeCv.copyWith(projects: list);
    saveCurrentCv();
  }

  // --- Certifications Mutations ---
  void addCertification(Certification cert) {
    final list = List<Certification>.from(_activeCv.certifications)..add(cert);
    _activeCv = _activeCv.copyWith(certifications: list);
    saveCurrentCv();
  }

  void deleteCertification(String id) {
    final list = _activeCv.certifications.where((item) => item.id != id).toList();
    _activeCv = _activeCv.copyWith(certifications: list);
    saveCurrentCv();
  }

  /// Imports a parsed document into the CV state
  Future<void> importCvFromDocument(CvData parsedCv, {bool saveAsNew = false}) async {
    if (saveAsNew) {
      _activeCv = parsedCv;
      _savedCvs.add(_activeCv);
      await _storageService.saveCv(_activeCv);
    } else {
      _activeCv = parsedCv.copyWith(
        id: _activeCv.id,
        selectedTemplate: _activeCv.selectedTemplate,
        accentColorHex: _activeCv.accentColorHex,
      );
      await _storageService.saveCv(_activeCv);
      final idx = _savedCvs.indexWhere((c) => c.id == _activeCv.id);
      if (idx != -1) {
        _savedCvs[idx] = _activeCv;
      } else {
        _savedCvs.add(_activeCv);
      }
    }
    notifyListeners();
  }
}
