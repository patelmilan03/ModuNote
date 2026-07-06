# LinkedIn Profile Refresh - Copy-Paste Guide

Approved plan. Paste each section directly into the matching LinkedIn field. Character counts noted where limits apply.

---

## 1. Headline (max 220 characters)

```
Data & Automation Engineer | Flutter Mobile Developer | Python · SQL · FastAPI · Flutter | BTech CS, MIT-WPU '25 | Open to Work
```

---

## 2. About (max 2,600 characters)

```
Recent Computer Science graduate (BTech, MIT World Peace University, 2025) building at the intersection of data engineering and mobile app development, and open to full-time roles in either.

On the data/backend side: at Portway Solutions, I built multi-modal data extraction pipelines (Selenium, PDF parsing, browser-intercepted API requests) that pulled trade-regulation data from 20+ government portals across Malaysia, China, and Singapore, then cleaned and normalized 15,000-30,000 rows per batch with Python, Pandas, and Regex into a standardized schema. I've since built Route-Aggregator, an async FastAPI backend that concurrently queries routing and weather APIs to generate daylight-aware travel itineraries, containerized with Docker and shipped to production with CI/CD.

On the mobile side: I design and ship Flutter apps with production-grade architecture - MVVM, Riverpod, offline-first local databases with full-text search. ModuNote, my most recent project, is a voice-to-text note-taking app built phase-by-phase with documented architectural decisions throughout.

I also spent close to 3 years as a video editor for my university's media club, which sharpened my eye for detail and comfort working under deadline pressure - habits that carry over directly into engineering work.

Tools: Python, Java, SQL, Dart, FastAPI, Pandas, NumPy, Selenium, Flutter, Docker, Git, PostgreSQL, Firebase.

Open to data engineering, backend, and mobile developer roles - let's connect.
```

---

## 3. Experience

### Position 1 - update existing Portway entry

**Title:** `Data & Automation Engineer` (change from "Content/ Data Engineer")
**Company:** Portway Solutions India Private Limited
**Dates:** Feb 2025 - Jun 2025 (unchanged)
**Employment type / Location:** Full-time, Remote (unchanged)

**Description:**
```
Built multi-modal data extraction pipelines using Selenium, PDF parsing, and browser-intercepted API requests to collect trade regulation data (tariffs, permits, restricted goods) from 20+ government portals across Malaysia, China, and Singapore.

Developed Python ETL workflows using Pandas, NumPy, and Regex to clean, validate, and normalize heterogeneous datasets of 15,000-30,000 rows per batch into a standardized schema, maintaining consistent output across sources of varying data quality.

Authored technical documentation for all scraping and ETL pipelines to ensure reproducibility across data validation and reporting workflows.
```

**Skills to tag:** Python, Pandas, NumPy, Selenium, Web Scraping, ETL, Regex

---

### Position 2 - update existing Shutterbugs entry

**Title:** Video Editor (unchanged)
**Company:** MIT-WPU Shutterbugs
**Dates:** Sep 2022 - May 2025 (unchanged - kept as currently listed on LinkedIn)
**Employment type:** Freelance (unchanged)

**Description (shortened):**
```
Edited and produced video content for university events, social campaigns, and inter-college showcases over roughly 2.5 years.
```

**Skills to tag:** Adobe Premiere Pro, After Effects, Video Editing

---

## 4. Projects (replace "FlashChat" with these three)

### Project 1

**Title:** `Route-Aggregator - Logistics & Route Aggregator API`
**Associated with:** Portway/personal project (leave blank or "Personal Project")
**Links:** Live demo `https://route-aggregator-api.onrender.com` and GitHub `https://github.com/patelmilan03/Route-Aggregator`

**Description:**
```
Architected and deployed a concurrent REST API using FastAPI and Python 3.11, containerized with Docker and shipped to Render via a GitHub CI/CD pipeline, with API-key authentication securing all endpoints.

Built an async I/O layer (asyncio.gather + httpx) to concurrently query OSRM and OpenWeatherMap across multiple waypoints, eliminating sequential blocking, and persisted results via SQLAlchemy with aiosqlite.

Implemented a Temporal Daylight Safety Engine that computes localized arrival times against live OSRM estimates and flags unsafe sunset arrivals, with a self-pinging background daemon maintaining 100% uptime against PaaS sleep cycles.
```

**Skills:** FastAPI, Python, Docker, SQLAlchemy, asyncio, PostgreSQL

---

### Project 2

**Title:** `ModuNote`
**Links:** GitHub `https://github.com/patelmilan03/ModuNote` (add the live web demo link too if you're comfortable making it public)

**Description:**
```
A quick-capture, offline-first note-taking app built with a strict MVVM + Repository architecture. Features a Drift SQLite database with FTS5 full-text search, Riverpod 2 state management with code generation, a Quill Delta rich-text editor, voice-to-text memo capture, and Firebase-backed sync with conflict/pending status tracking. Developed phase-by-phase with documented architectural decisions throughout.
```

**Skills:** Flutter, Dart, Riverpod, Firebase, SQLite

---

### Project 3

**Title:** `Forgeload`
**Links:** GitHub `https://github.com/patelmilan03/progressive-load-engine`

**Description:**
```
A Java 17 sports-analytics engine (5,800 lines, 30 files) applying Template Method, Builder, DAO, and Singleton design patterns. Implements RPE-weighted volume and Bannister TRIMP load models through an abstract WorkoutSession hierarchy, plus a per-muscle recovery scoring model across 10 muscle groups producing a composite Readiness Score, with Acute:Chronic Workload Ratio-based injury risk classification.
```

**Skills:** Java, JUnit, Maven, Object-Oriented Design

---

## 5. Skills section

**Pin these 3 as "Top Skills"** (replace the current single pinned "Java"):
```
Python
Flutter
SQL
```

**Full skills list** - remove the duplicate "Flutter " entry and the bare "C" entry, then add/reorder to:
```
Python, SQL, Pandas, NumPy, FastAPI, Selenium, Web Scraping, ETL, PostgreSQL, MongoDB, Docker, Git, Linux, Flutter, Dart, Android Development, Java, C++, iOS Development, Android Studio, Video Editing, Adobe Premiere Pro, After Effects
```

---

## 6. Education

Consolidate the two existing "MIT World Peace University" entries into **one** clean entry (delete the blank duplicate that has no degree filled in):

**School:** MIT World Peace University
**Degree:** Bachelor of Technology - BTech
**Field of study:** Computer Science Engineering
**Dates:** 2021 - 2025
**Grade:** 8.4 / 10
**Description:**
```
Relevant coursework: Data Structures & Algorithms, DBMS, Operating Systems, Computer Networks, Object-Oriented Programming
```

---

## 7. Licenses & Certifications (new section)

**Certification 1**
```
Name: Android App Development using Java
Issuing organization: NITTR Bhopal
Issue date: 2024
```

**Certification 2**
```
Name: Flutter Course
Issuing organization: Hungrimind
Issue date: February 2026
```

---

## 8. Featured section

Add these as featured links:
```
https://github.com/patelmilan03
https://route-aggregator-api.onrender.com
```

---

## 9. Housekeeping (outside LinkedIn)

- Your resume lists your LinkedIn URL as `linkedin.com/in/milan-patel-040703mm` (double "m") - fix the typo so it matches your real profile `milan-patel-040703m`.
- Once your headline/About no longer say "Student," double check your "Open to Work" preferences (job titles, locations, remote) list both Data Engineer and Flutter/Mobile Developer roles so you show up in both recruiter searches.
