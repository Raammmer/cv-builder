# CVBuilder 📄🤖
> **An Intelligent Flutter Resume Builder with an Integrated AI Career Agent**

---

## 🌟 Overview

**CVBuilder** is a high-performance cross-platform application developed in **Flutter**. It solves a core challenge job-seekers face: transforming raw career milestones into ATS-optimized, high-impact resumes.

Unlike basic resume apps, **CVBuilder integrates an autonomous AI Career Agent**. The agent acts as an intelligent career copilot, using Google's **XYZ Formula** (*"Accomplished [X], as measured by [Y], by doing [Z]"*) and semantic keyword analysis to evaluate, rewrite, and mutate resume data directly inside the application state.

---

## 🚀 Key Features

1. **Structured Resume Form Editor**:
   - Tabbed navigation across *Personal Info*, *Work Experience*, *Education*, *Skills*, and *Projects*.
   - Inline "AI Polish" tools beside individual achievements.
   - Dynamic bullet point reordering, additions, and deletions.

2. **Real-Time ATS Completeness Gauge**:
   - Dynamic circular score ring rating profile completeness (0–100%) and ATS alignment.
   - Visual feedback on missing required contact information and section gaps.

3. **Multi-Format Document Ingestion**:
   - Ingest existing resumes directly from PDF, Word DOCX, Markdown, or plain text.
   - Heuristic entity parser extracts candidate contact details, work history, and skills automatically into form fields.

4. **Conversational Career Copilot & Job Matcher**:
   - Chat with an embedded career assistant for tailored resume feedback.
   - Paste job descriptions to compute compatibility match scores and identify missing critical keywords.
   - Expandable reasoning traces explaining why improvements were recommended.

5. **Dual-Engine Architecture (Cloud & Offline Resilient)**:
   - **Online Mode**: Integrates with Google Gemini Foundation models for advanced natural language career recommendations.
   - **Offline Mode**: Built-in heuristic rule engine executes local reasoning and XYZ formatting, ensuring uninterrupted productivity without an active internet connection.

6. **Multiple Professional Resume Templates**:
   - **Modern Tech**: Accent lines, bold titles, and technical skill badges.
   - **Executive Pro**: Structured two-column layout with header banner and corporate typography.
   - **Minimalist Clean**: Balanced whitespace and subtle hairline dividers.

7. **Dynamic Color Customization**:
   - Instant customization across curated palettes: Royal Blue, Modern Teal, Emerald Green, Indigo Slate, Rose Crimson, and Midnight Dark.

8. **Vector-Quality PDF Export**:
   - Powered by the `pdf` and `printing` vector engines.
   - Generates exact A4 vector PDF documents with selectable text streams, 1-click preview, native printing, or download.

---

## 📁 Project Directory Structure

```
cv_builder/
├── lib/
│   ├── main.dart                      # App entry point
│   ├── models/                        # Resume domain models & data entities
│   │   ├── cv_data.dart               # Composite CV model & completeness score logic
│   │   ├── personal_info.dart         # Contact & summary details
│   │   ├── work_experience.dart       # Job positions & bullet points
│   │   ├── education.dart             # Academic credentials & GPA
│   │   ├── skill.dart                 # Categorized skills & ratings
│   │   ├── project.dart               # Portfolio projects & repository links
│   │   ├── certification.dart         # Certifications & licenses
│   │   └── ai_agent_message.dart      # Chat messages & tool actions
│   ├── viewmodels/                    # App state & business logic
│   │   ├── cv_viewmodel.dart          # CV state management & section mutations
│   │   └── ai_agent_viewmodel.dart    # AI copilot chat & job matcher state
│   ├── views/                         # UI screens
│   │   ├── home_screen.dart           # Dashboard with saved CVs & quick actions
│   │   ├── cv_editor_screen.dart      # Multi-tab form editor with inline AI tools
│   │   ├── cv_preview_screen.dart     # Live preview & vector PDF export
│   │   ├── ai_agent_screen.dart       # AI Career Copilot chat & ATS Job Matcher
│   │   └── settings_screen.dart       # App settings & engine configuration
│   ├── services/                      # Services & external integrations
│   │   ├── ai_agent_service.dart      # Gemini API & offline heuristic engine
│   │   ├── pdf_export_service.dart    # Vector PDF rendering engine
│   │   └── storage_service.dart       # Local persistence & session storage
│   ├── widgets/                       # Reusable UI widgets & Templates
│   │   ├── ai_action_button.dart      # AI Polish action widget
│   │   ├── score_badge.dart           # Circular score gauge
│   │   ├── section_card.dart          # Form section card container
│   │   └── templates/                 # Document template renderers
│   ├── theme/                         # Material 3 styling & color palettes
│   └── utils/                         # Constants & sample data
└── pubspec.yaml                       # Dependencies and assets configuration
```

---

## 💻 How to Run the Project

### Prerequisites
1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.10.0 or higher).
2. Ensure you have an editor (VS Code or Android Studio) and an execution target (Windows Desktop, Chrome Browser, or Android Emulator).

### Running Locally
```bash
# 1. Navigate to the project folder
cd cv_builder

# 2. Get dependencies
flutter pub get

# 3. Run on your desired platform
flutter run -d windows    # For Windows Desktop
# OR
flutter run -d chrome     # For Web Browser
# OR
flutter run -d android    # For Android Device / Emulator
```
