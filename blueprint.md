
# Blueprint: Platify Financial Assistant

## Overview

Platify is a simple financial assistant application designed to help users track their bank accounts and transactions. The application uses Isar as a local database to store and manage financial data efficiently. The UI is built with Flutter and follows Material Design principles for a clean and intuitive user experience.

## Features & Design

### 1. Core Architecture

*   **State Management**: `provider` is used for managing the application's state, particularly for providing the `IsarService` to the widget tree.
*   **Database**: `isar` (Community Edition) is used as the local, high-performance database for storing `Account` and `Transaction` data.
*   **Code Generation**: `build_runner` and `isar_generator` are used to generate the necessary code for Isar schemas.

### 2. Screens & UI

*   **Accounts Screen (`accounts_screen.dart`)**:
    *   This is the main screen of the application.
    *   It displays a list of all bank accounts stored in the database.
    *   Each account in the list shows its name and current balance.
    *   A Floating Action Button (FAB) allows users to navigate to the "Add Account" screen.
    *   Tapping on an account will navigate the user to a (future) transaction details screen.

*   **Add Account Screen (`add_account_screen.dart`)**:
    *   A simple form with text fields for the account name and initial balance.
    *   A "Save" button to persist the new account to the Isar database using `IsarService`.

*   **Add Transaction Screen (`add_transaction_screen.dart`)**:
    *   A form to add a new transaction to a specific account.
    *   Fields for transaction description, amount, and date.
    *   A "Save" button to add the transaction and update the corresponding account's balance.

### 3. Data Models

*   **`Account` (`account_model.dart`)**:
    *   `id`: Auto-incrementing primary key.
    *   `name`: `String` - The name of the account (e.g., "Checking Account").
    *   `balance`: `double` - The current balance of the account.
    *   `transactions`: `IsarLinks<Transaction>` - A link to all transactions associated with this account.

*   **`Transaction` (`transaction_model.dart`)**:
    *   `id`: Auto-incrementing primary key.
    *   `description`: `String` - A description of the transaction.
    *   `amount`: `double` - The transaction amount (can be positive or negative).
    *   `date`: `DateTime` - The date of the transaction.

## Current Plan

1.  **Rebuild `main.dart`**: Set up the main application widget, initialize `IsarService`, and use `ChangeNotifierProvider` to make it available to the rest of the app.
2.  **Implement `accounts_screen.dart`**: Create the UI to display a list of accounts from `IsarService`.
3.  **Implement `add_account_screen.dart`**: Create the form and logic to add new accounts.
4.  **Implement `add_transaction_screen.dart`**: Create the form and logic to add new transactions.
5.  **Connect Screens**: Implement navigation between the screens.
