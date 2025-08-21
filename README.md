# FamilyBudget

**FamilyBudget** is an experimental iOS application designed to manage personal and shared family budgets. This project was created to explore **The Composable Architecture (TCA)** and its benefits compared to traditional MVVM, while integrating **Core Data** with **CloudKit** for cross-user collaborative budgeting.

---

## Project Overview

- **Platform:** iOS (iOS 16+)
- **Architecture:** The Composable Architecture (TCA)
- **Persistence:** Core Data + CloudKit (Private & Shared iCloud)
- **Objective:** Explore TCA patterns for real-world app development and cross-user collaborative data.

---

## Key Features

- Full CRUD for **BudgetYears**, **BudgetMonths**, and **Entries**.
- Cross-user collaboration using **CloudKit shared databases**.
- Persistent selection of **Private vs Shared iCloud storage**.
- Async-safe Core Data operations using structured concurrency.
- Automatic creation of months for each year to simplify setup.
- `AppStorage` integration to persist user storage choice.

---

## Architectural Decisions

### TCA Benefits

Compared to traditional MVVM:

| Feature                         | TCA                                      | MVVM                                         |
|---------------------------------|-----------------------------------------|----------------------------------------------|
| State Management                | Centralized, predictable state          | Decentralized, can be inconsistent          |
| Dependency Injection            | Built-in via `DependencyKey`            | Manual or via environment objects           |
| Side Effects                    | Handled with `Effect`s, testable        | Usually scattered in viewModels             |
| Testability                     | High — pure functions + Effects         | Medium — harder to isolate                  |
| Composition                     | Reducers can be composed hierarchically| ViewModels are often tightly coupled        |

TCA allows **deterministic state updates** and **isolated effect handling**, making cross-user sync logic more reliable.

---

### Folder Structure

```
FamilyBudget/
│
├── App/
│   ├── FamilyBudgetApp.swift      # Main entry point
│   └── AppView.swift              # Root view
│
├── Features/
│   ├── AppFeature/                # TCA root feature
│   │   ├── Reducer.swift
│   │   ├── State.swift
│   │   └── Actions.swift
│   └── OtherFeatures/             # Modular features (Entries, BudgetMonth)
│
├── Models/
│   ├── BudgetYear+CoreData.swift
│   ├── BudgetMonth+CoreData.swift
│   └── Entry+CoreData.swift
│
├── Persistence/
│   ├── CoreDataClient.swift       # Async-safe Core Data wrapper
│   └── PersistenceController.swift# CloudKit container setup
│
├── Views/
│   ├── StorageSelectionView.swift # Select Private/Shared iCloud
│   └── Shared/                    # Reusable UI components
│
├── Tests/
│   └── CoreDataClientTests.swift
└── README.md
```

---

## Improvements vs MVVM

1. **Centralized State**: TCA ensures all state flows through a single source of truth.
2. **Composable Reducers**: Each feature is modular and testable independently.
3. **Effect Management**: Async Core Data + CloudKit operations are safely handled.
4. **Dependency Injection**: `DependencyValues` allows easy swapping of live vs mock clients.

---

## Drawbacks / Considerations

- **Steep Learning Curve**: TCA is more verbose than MVVM for simple apps.
- **Boilerplate Code**: Requires more files and boilerplate (State, Actions, Reducer).
- **CloudKit Complexity**: Shared database setup requires careful CloudKit configuration and testing.
- **Concurrency Awareness**: All Core Data operations must respect `@MainActor` isolation.

---

## Future Improvements

- **Invite & Collaboration Flow**: Fully integrated UI for inviting other users to the shared budget.
- **Conflict Resolution**: Automatic merge strategies for concurrent edits by multiple users.
- **Advanced Analytics**: Monthly and yearly budget reports.
- **Cross-Platform**: iPad / macOS integration leveraging shared Core Data + CloudKit.
- **UI Enhancements**: Animations and interactive charts.

---

## Architectural Diagram

```text
+-------------------+       +----------------------+       +----------------+
|                   |       |                      |       |                |
|     AppView       | <---> |  AppFeature Reducer   | <---> | CoreDataClient |
|  (Root SwiftUI)   |       |  (TCA State & Action)|       | Async + CKSync |
|                   |       |                      |       |                |
+-------------------+       +----------------------+       +----------------+
         |                            |                             |
         | SwiftUI Binding           | TCA Effects                  | @MainActor async
         v                            v                             v
+-------------------+       +----------------------+       +----------------+
| StorageSelection  |       | BudgetYear / Month   |       | NSPersistentCK  |
|   View            |       | Reducers            |       | CloudKit        |
+-------------------+       +----------------------+       +----------------+
```

- The diagram shows **TCA State flow**, **effects**, and **Core Data + CloudKit interactions** for shared and private iCloud databases.

---

## Conclusion

This project demonstrates a **practical implementation of TCA with Core Data + CloudKit** for cross-user collaborative iOS apps. It serves as an experimental playground to explore **composable architecture patterns**, async-safe persistent storage, and multi-user state synchronization.

