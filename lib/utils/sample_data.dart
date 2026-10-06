import '../models/cv_data.dart';
import '../models/personal_info.dart';
import '../models/work_experience.dart';
import '../models/education.dart';
import '../models/skill.dart';
import '../models/project.dart';
import '../models/certification.dart';

class SampleData {
  static CvData get sampleCv => CvData(
        id: 'sample-resume-01',
        title: 'Software Engineer Resume',
        selectedTemplate: 'modern',
        accentColorHex: 0xFF0D9488, // Modern Teal
        personalInfo: PersonalInfo(
          fullName: 'Alex Morgan',
          jobTitle: 'Full Stack Software Engineer',
          email: 'alex.morgan.dev@example.com',
          phone: '+1 (555) 234-5678',
          location: 'San Francisco, CA',
          website: 'https://alexmorgan.dev',
          linkedin: 'linkedin.com/in/alexmorgandev',
          github: 'github.com/alexmorgan-code',
          summary:
              'Results-driven Software Engineer with 3+ years of experience engineering high-performance mobile and web applications. Proven track record of optimizing application response times by 40% and leading cross-functional teams to deploy scalable cloud services.',
        ),
        experiences: [
          WorkExperience(
            id: 'exp-1',
            company: 'TechFlow Solutions',
            role: 'Associate Software Engineer',
            location: 'San Francisco, CA',
            startDate: 'Jan 2024',
            endDate: 'Present',
            isCurrent: true,
            bullets: [
              'Architected and deployed customer onboarding microservice in Dart & Node.js, reducing drop-off rates by 28% across 50K+ active users.',
              'Led Flutter cross-platform mobile migration, cutting code duplication by 45% and reducing CI/CD build times by 15 minutes.',
              'Collaborated with product designers to implement responsive WCAG 2.1 AA accessible UI components.',
            ],
          ),
          WorkExperience(
            id: 'exp-2',
            company: 'Apex Digital Labs',
            role: 'Software Developer Intern',
            location: 'Seattle, WA',
            startDate: 'Jun 2023',
            endDate: 'Dec 2023',
            isCurrent: false,
            bullets: [
              'Developed automated testing pipelines using Mockito and integration tests, increasing codebase unit test coverage from 62% to 89%.',
              'Implemented real-time WebSocket state synchronization, decreasing server telemetry latency by 120ms.',
              'Authored technical documentation and API reference specs for internal developer SDKs.',
            ],
          ),
        ],
        educations: [
          Education(
            id: 'edu-1',
            institution: 'University of California, Berkeley',
            degree: 'Bachelor of Science',
            fieldOfStudy: 'Computer Science',
            startDate: '2020',
            endDate: '2024',
            gradeOrGpa: '3.85 / 4.0 GPA (Dean\'s Honors)',
            description: 'Coursework: Data Structures & Algorithms, Distributed Systems, Software Engineering, Database Systems.',
          ),
        ],
        skills: [
          Skill(id: 'sk-1', name: 'Flutter & Dart', category: 'Technical', level: 5),
          Skill(id: 'sk-2', name: 'TypeScript & Node.js', category: 'Technical', level: 4),
          Skill(id: 'sk-3', name: 'Python & FastAPI', category: 'Technical', level: 4),
          Skill(id: 'sk-4', name: 'PostgreSQL & Redis', category: 'Technical', level: 4),
          Skill(id: 'sk-5', name: 'Docker & Kubernetes', category: 'Tools & Frameworks', level: 3),
          Skill(id: 'sk-6', name: 'Git & GitHub Actions', category: 'Tools & Frameworks', level: 5),
          Skill(id: 'sk-7', name: 'System Architecture', category: 'Soft Skills', level: 4),
          Skill(id: 'sk-8', name: 'Agile & Scrum Leadership', category: 'Soft Skills', level: 5),
        ],
        projects: [
          Project(
            id: 'proj-1',
            title: 'PulseRate: Health Telemetry Dashboard',
            role: 'Lead Mobile Engineer',
            description: 'Cross-platform mobile application processing real-time Bluetooth Low Energy (BLE) health sensor streams with interactive Charts and PDF export.',
            technologies: 'Flutter, Provider, SQLite, Bluetooth LE',
            link: 'github.com/alexmorgan-code/pulserate',
          ),
          Project(
            id: 'proj-2',
            title: 'CloudQueue: Serverless Task Scheduler',
            role: 'Backend Creator',
            description: 'Distributed fault-tolerant worker system handling up to 10,000 tasks/sec with automatic dead-letter queue retries and latency tracking.',
            technologies: 'Go, Docker, AWS SQS, Grafana',
            link: 'github.com/alexmorgan-code/cloudqueue',
          ),
        ],
        certifications: [
          Certification(
            id: 'cert-1',
            name: 'AWS Certified Solutions Architect – Associate',
            issuer: 'Amazon Web Services',
            issueDate: '2024',
            credentialUrl: 'aws.amazon.com/verify/12345',
          ),
        ],
      );
}
