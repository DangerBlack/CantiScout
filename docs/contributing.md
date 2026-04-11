# Contributing to CantScout

Thank you for your interest in contributing. All kinds of contributions are
welcome: bug reports, feature suggestions, translations, documentation
improvements, and code.

---

## Before you start

- Check the open issues to see if your bug or idea has already been reported.
- For significant new features, open an issue to discuss the approach before
  writing code. This avoids wasted effort.
- For small bug fixes and documentation changes, you can go straight to a pull
  request.

---

## Development setup

See [build.md](build.md) for prerequisites and how to run the project locally.

---

## Workflow

```
fork → feature branch → commit → pull request
```

1. Fork the repository and clone your fork.
2. Create a branch from `master` with a short descriptive name:
   ```bash
   git checkout -b fix/chord-alignment
   git checkout -b feat/dark-mode
   ```
3. Make your changes. Keep commits focused — one logical change per commit.
4. Run the analyzer before pushing:
   ```bash
   flutter analyze
   flutter test
   ```
5. Open a pull request against `master`. Describe **what** you changed and
   **why**. Link the related issue if one exists.

---

## Code style

- Follow the conventions already present in the file you are editing.
- Dart code is formatted with `dart format` (80-character line length).
- Do not add comments that restate what the code already says; add comments
  only where the intent is not immediately obvious.
- Do not refactor unrelated code in the same PR as a feature or bug fix.

---

## Translations

To add or update a language, follow the step-by-step guide in
[localization.md](localization.md). Translation PRs are very welcome.

---

## Reporting bugs

Open a GitHub issue and include:

- Device model and Android / iOS version.
- App version (visible in Settings).
- Steps to reproduce the problem.
- What you expected to happen, and what actually happened.
- A sample `.chopro` body that triggers the issue, if the problem is
  rendering-related.

---

## Song data and copyright

CantScout does not accept contributions of song lyrics or chord sheets.
The app ships with no content; see the [copyright policy](../README.md#copyright-and-content-policy)
in the README for the reasoning.

---

## License

By submitting a pull request you agree that your contribution will be licensed
under the [MIT License](../LICENSE).
