# AI_CONTEXT.md

# Room Expense Manager

This file is intended for AI assistants (ChatGPT or any future AI) to quickly understand the project and continue development without asking the user to explain everything again.

---

# Project Overview

Project Name:
Room Expense Manager

Platform:
Flutter

Backend:
Firebase

Database:
Cloud Firestore

Authentication:
Firebase Phone Authentication (OTP)

Version:
Development

---

# Goal

Build a production-quality Room Expense Manager application where users can:

- Login using OTP
- Create a Room
- Join a Room
- Add Members
- Add Expenses
- Split Expenses Automatically
- View Settlement
- Generate Reports

The app should be clean, scalable and production ready.

---

# Current Progress

Completed:

- Flutter Project Setup
- GitHub Repository
- Firebase Integration
- Firebase Authentication
- OTP Login
- Home Dashboard
- Firestore Database
- Firestore Service
- User Auto Save

Current Firestore Structure

users
    uid
        uid
        phone
        name
        roomId
        createdAt

---

# Current Folder Structure

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

# Architecture

Follow Clean Architecture style.

UI

↓

Service Layer

↓

Firebase

↓

Firestore

Business logic should NOT be written directly inside UI whenever possible.

---

# Services

Current Service

FirestoreService

Responsibilities

- Save User
- Update User
- Read User
- Room Operations (future)

---

# Authentication Flow

Splash

↓

Login Screen

↓

OTP Screen

↓

Firebase Verification

↓

Save User in Firestore

↓

Home Dashboard

---

# Current Home Screen

Contains

- Welcome
- Total Balance
- Total Expense
- Room Members
- Add Expense Button

Currently static.

---

# Coding Rules

Always:

- Write complete code.
- Keep files clean.
- Avoid duplicate logic.
- Use reusable widgets.
- Keep UI and Firebase code separated.
- Use meaningful names.

Never:

- Rewrite working code unnecessarily.
- Change folder structure without reason.
- Break previous features.

---

# Firestore Collections

Current

users

Future

rooms

expenses

settlements

notifications

---

# Roadmap

Phase 1

✔ OTP Login

✔ Firestore User Save

⬜ Complete Profile

⬜ Create Room

⬜ Join Room

Phase 2

⬜ Members

⬜ Add Expense

⬜ Expense History

⬜ Edit Expense

Phase 3

⬜ Split Calculation

⬜ Settlement

⬜ Reports

Phase 4

⬜ Notifications

⬜ Settings

⬜ Profile

⬜ Dark Mode

---

# Development Workflow

For every feature:

1. Design UI
2. Connect Firebase
3. Test
4. Update PROJECT_STATUS.md
5. Commit
6. Push to GitHub

Never skip testing before moving to the next feature.

---

# GitHub Repository

Repository

https://github.com/PAPPU-PRAKASH/room-expense-manager

---

# Important Instruction For Any AI

Before writing any code:

1. Read the complete repository.
2. Read README.md.
3. Read PROJECT_STATUS.md.
4. Read AI_CONTEXT.md.
5. Understand current architecture.
6. Continue ONLY from the latest completed feature.
7. Never restart the project.
8. Never ask the user to explain old work if it already exists in the repository.
9. Maintain the existing coding style.
10. Produce production-quality Flutter code.

If any required file is missing, ask only for that specific file.

---

Last Updated

13 July 2026

Status

Project Stable

Next Feature

Complete Profile Screen