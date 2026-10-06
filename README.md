# CVBuilder 📄🤖
> **An Intelligent Flutter Resume Builder with an Integrated AI Career Agent**

---

## 🌟 Overview

**CVBuilder** is a high-performance cross-platform application developed in **Flutter** that strictly follows the **MVVM (Model-View-ViewModel)** architectural pattern. It solves a core challenge job-seekers face: transforming raw career milestones into ATS-optimized, high-impact resumes.

Unlike basic resume apps, **CVBuilder integrates an autonomous AI Career Agent**. The agent acts as an intelligent career copilot, using Google's **XYZ Formula** and semantic keyword analysis to evaluate, rewrite, and mutate resume data directly inside the application state.

---

## 🏗️ Architectural Pattern: MVVM (Model - View - ViewModel)

This project strictly adheres to the **MVVM Architecture** to ensure clean separation of concerns, testability, and scalability:

```
+-------------------------------------------------------------------------+
|                                  VIEW                                   |
|   lib/views/ (HomeScreen, CvEditorScreen, CvPreviewScreen, AiAgentScreen) |
|   lib/widgets/ (Templates, ScoreBadge, AiActionButton, SectionCard)     |
|   • Only renders UI components.                                         |
|   • Listens to ViewModel state via reactive listeners (Consumer/watch). |
|   • Forwards user gestures/intents to ViewModel actions.                |
+------------------------------------+------------------------------------+
                                     |
                                     v  (User Actions / State Observation)
+------------------------------------+------------------------------------+
|                                VIEWMODEL                                |
|   lib/viewmodels/ (CvViewModel, AiAgentViewModel)                       |
|   • Holds and exposes observable UI state (extends ChangeNotifier).     |
|   • Contains presentation logic, validation, and tool execution.        |
|   • Mediates between the View and underlying Services/Models.           |
|   • Views NEVER directly access databases or external APIs.             |
+------------------------------------+------------------------------------+
                                     |
                                     v  (Data Operations & Tool Calls)
+------------------------------------+------------------------------------+
|                             MODEL & SERVICES                            |
|   lib/models/ (CvData, PersonalInfo, WorkExperience, AiAgentMessage...) |
|   lib/services/ (AiAgentService, PdfExportService, StorageService)      |
|   • Pure business entities, JSON serialization, and data definitions.   |
|   • External REST communication (Gemini LLM API) & PDF rendering.       |
+-------------------------------------------------------------------------+
```

### Layer Responsibilities

1. **Model Layer (`lib/models/`)**:
   - `cv_data.dart`: Composite resume domain entity with completeness score algorithm.
   - `work_experience.dart`, `education.dart`, `skill.dart`, `project.dart`, `certification.dart`: Structured career entities.
   - `ai_agent_message.dart`: Conversational messages, reasoning traces, and structured `AgentToolAction` payloads.

2. **ViewModel Layer (`lib/viewmodels/`)**:
   - `cv_viewmodel.dart`: Manages resume CRUD operations, template choices, active color palettes, and persistence orchestration via `StorageService`.
   - `ai_agent_viewmodel.dart`: Manages AI conversational state, reasoning traces, ATS match analysis, and tool execution dispatching.

3. **View Layer (`lib/views/` & `lib/widgets/`)**:
   - `home_screen.dart`: Dashboard with completeness gauges, recent resumes, and navigation.
   - `cv_editor_screen.dart`: Tabbed form editor with inline "AI Polish" hooks.
   - `cv_preview_screen.dart`: Real-time interactive A4 sheet rendering and vector PDF export.
   - `ai_agent_screen.dart`: Dedicated AI career copilot chat and ATS job-matching suite.
   - `settings_screen.dart`: Gemini API key configuration and offline demo engine toggle.

---

## 🧠 The AI Agent: How It Works & Architecture

### 1. What makes this an "AI Agent" rather than a simple prompt?
In Artificial Intelligence and Software Engineering, an **Agent** is defined by three continuous capabilities:
1. **Perception**: The agent inspects the application state in `CvViewModel` (work experience, skills, education, and user prompts).
2. **Cognitive Reasoning & Planning**: It breaks down text into structural metrics, evaluating active vs. passive voice, quantifying achievements, and checking ATS keyword density.
3. **Autonomous Tool Execution (Function Calling)**: Rather than just printing suggestions as text, the agent outputs structured tool invocations (`AgentToolAction`) that mutate the `CvViewModel` state with one-click user consent.

### 2. Supported Agent Tools & Functions
| Tool Name | Purpose | Trigger / Action |
|---|---|---|
| `replace_bullet` | Replaces weak, passive bullet points with quantifiable XYZ achievements. | Inline on any experience bullet or via chat. |
| `update_summary` | Synthesizes target job title and top 3 technical skills into an executive profile. | Summary input field or chat command. |
| `add_skill` | Extracts demanded frameworks from job descriptions and appends them as categorized chips. | ATS scanner or conversational command. |
| `analyze_ats` | Scans a target Job Description, computes match percentage (0–100%), and detects missing keywords. | ATS Job Matcher tab. |

### 3. Dual Engine Architecture (Cloud & Offline Resilient)
- **Live Mode**: Directly queries Google Gemini via REST API using standard HTTP headers and JSON structured mode.
- **Offline / Fallback Mode**: Features an embedded heuristic rule engine that executes local reasoning and XYZ formatting, ensuring uninterrupted productivity without requiring an active internet connection or external API availability.

---

## 🚀 Key Application Features

1. **Structured CV Form Editor**:
   - Tabbed navigation across *Personal Info*, *Work Experience*, *Education*, *Skills*, and *Projects*.
   - Inline "AI Polish" buttons beside individual achievements.
   - Dynamic bullet point additions and drag/delete controls.
2. **Multiple Professional Resume Templates**:
   - **Modern Tech**: Accent lines, bold titles, and technical skill badges.
   - **Executive Pro**: Structured two-column layout with header banner and corporate typography.
   - **Minimalist Clean**: Scandinavian whitespace balance and subtle hairline dividers.
3. **Dynamic Color Palettes**:
   - Instant customization across 6 curated palettes: Royal Blue, Modern Teal, Emerald Green, Indigo Slate, Rose Crimson, and Midnight Dark.
4. **Vector-Quality PDF Export**:
   - Powered by the `pdf` and `printing` packages.
   - Generates exact A4 vector PDF documents with 1-click preview, native printing, or download.
5. **Real-time ATS & Completeness Gauges**:
   - Visual progress rings rating resume strength and ATS alignment.

---

## 📁 Project Directory Structure (MVVM)

```
cv_builder/
├── lib/
│   ├── main.dart                      # App entry point & MultiProvider initialization
│   ├── models/                        # [M] MODEL LAYER: Domain entities & serialization
│   │   ├── cv_data.dart               # Composite CV model & completeness score logic
│   │   ├── personal_info.dart         # Contact & summary details
│   │   ├── work_experience.dart       # Job positions & bullet points
│   │   ├── education.dart             # Academic credentials & GPA
│   │   ├── skill.dart                 # Categorized skills & proficiency ratings
│   │   ├── project.dart               # Portfolio projects & repository links
│   │   ├── certification.dart         # Certifications & licenses
│   │   └── ai_agent_message.dart      # Chat messages, reasoning logs & tool actions
│   ├── viewmodels/                    # [VM] VIEWMODEL LAYER: State & Presentation Logic
│   │   ├── cv_viewmodel.dart          # CV state management & section mutations
│   │   └── ai_agent_viewmodel.dart    # Agent chat state, reasoning traces & tool execution
│   ├── views/                         # [V] VIEW LAYER: Screen components
│   │   ├── home_screen.dart           # Dashboard with saved CVs & quick actions
│   │   ├── cv_editor_screen.dart      # Multi-tab editor with inline AI hooks
│   │   ├── cv_preview_screen.dart     # Live preview, template switch & PDF export
│   │   ├── ai_agent_screen.dart       # AI Career Copilot chat & ATS Job Matcher
│   │   └── settings_screen.dart       # API key configuration & engine toggles
│   ├── services/                      # SERVICE LAYER: External I/O and hardware
│   │   ├── ai_agent_service.dart      # Dual Gemini / Local Agent engine
│   │   ├── pdf_export_service.dart    # PDF generation for all templates
│   │   └── storage_service.dart       # Local persistence
│   ├── widgets/                       # Reusable UI widgets & Templates
│   │   ├── ai_action_button.dart      # Reusable "AI Polish" widget with modal preview
│   │   ├── score_badge.dart           # Circular score gauge
│   │   ├── section_card.dart          # Form section card container
│   │   └── templates/
│   │       ├── modern_template.dart   # Modern Tech template renderer
│   │       ├── executive_template.dart# Executive Pro template renderer
│   │       └── minimalist_template.dart# Minimalist Clean template renderer
│   ├── theme/
│   │   └── app_theme.dart             # Material 3 light and dark theme styling
│   └── utils/
│       ├── constants.dart             # Palettes, templates, and agent system prompts
│       └── sample_data.dart           # Pre-configured Software Engineer profile
└── pubspec.yaml                       # Project dependencies and asset definitions
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
