# Room Expense Manager - Architecture

Last Updated: 13 July 2026

---

# Purpose

Room Expense Manager is a Flutter application that helps roommates manage shared expenses.

Users can:

- Login using OTP
- Create a Room
- Join a Room
- Add Members
- Add Expenses
- Split Bills
- View Settlements
- Generate Reports

---

# Technology Stack

Frontend

- Flutter
- Dart

Backend

- Firebase Authentication
- Cloud Firestore

Version Control

- Git
- GitHub

---

# Folder Structure

lib

app/
core/
features/
models/
services/
utils/
widgets/

firebase_options.dart
main.dart

---

# Feature Structure

features/

auth/
home/
room/
expense/
profile/
settings/

Each feature contains:

- UI
- Widgets
- Logic

Business logic should be kept inside services whenever possible.

---

# Current Navigation

Splash

↓

Login

↓

OTP Verification

↓

Firestore User Save

↓

Home Dashboard

---

# Firestore Structure

users

uid

uid

phone

name

roomId

createdAt

Future Collections

rooms

expenses

settlements

notifications

---

# Services

Current

FirestoreService

Responsibilities

- Save User
- Update User
- Read User

Future Services

AuthService

RoomService

ExpenseService

NotificationService

---

# Home Dashboard

Current Widgets

- Welcome
- Total Balance
- Total Expense
- Room Members
- Add Expense

Future Widgets

- Recent Expenses
- Pending Settlements
- Monthly Summary
- Room Information

---

# Development Rules

Always

- Use Clean Code.
- Use reusable widgets.
- Separate UI and Firebase logic.
- Keep architecture consistent.
- Test every feature before moving forward.

Never

- Rewrite working code unnecessarily.
- Change folder structure without reason.
- Break previous features.

---

# Development Workflow

Every feature follows:

1. UI
2. Firebase Integration
3. Testing
4. Update PROJECT_STATUS.md
5. Commit
6. Push

---

# Git Commit Style

Examples

feat: complete OTP authentication

feat: add Firestore user save

feat: create home dashboard

fix: phone auth bug

docs: update project status

---

# Current Progress

Completed

- Project Setup
- Firebase Setup
- OTP Login
- Home Dashboard
- Firestore User Save

Current Feature

Complete Profile

Next Features

- Create Room
- Join Room
- Members
- Expenses
- Split Calculation
- Reports

---

# AI Instructions

Before writing code:

1. Read README.md
2. Read PROJECT_STATUS.md
3. Read AI_CONTEXT.md
4. Read docs/architecture.md

Continue only from the latest completed feature.

Never restart the project unless explicitly asked.

Maintain the existing architecture and coding style.

If repository access is unavailable, ask only for the specific missing file instead of requesting the entire project explanation.