# 🐱 Cat Superhero 🦸‍♀️

A purr-fectly heroic game project developed for GGJ-2026.

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![License](https://img.shields.io/badge/license-Unlicensed-red)
![Stars](https://img.shields.io/github/stars/sumit-sinha-playground/cat-superhero?style=social)
![Forks](https://img.shields.io/github/forks/sumit-sinha-playground/cat-superhero?style=social)

![cat-superhero-preview](/preview_example.png)

---

## ✨ Features

*   🐾 **Unique Cat Abilities**: Unleash a range of feline superpowers to overcome obstacles and outsmart foes.
*   🧩 **Engaging Level Design**: Navigate through cleverly designed levels filled with puzzles and platforming challenges.
*   🎨 **Charming Art Style**: Immerse yourself in a visually appealing game world with a distinct aesthetic.
*   🚀 **Intuitive GDScript Codebase**: Built with clean and modular GDScript, making it easy to understand and extend.
*   🎮 **Dynamic Gameplay Mechanics**: Experience responsive controls and innovative gameplay elements that keep you on your toes.

---

## 🛠️ Installation Guide

To get `cat-superhero` up and running, follow these simple steps. This project requires the Godot Engine.

### Prerequisites

Ensure you have the Godot Engine installed on your system.
*   Download Godot Engine: [Godot Engine Official Website](https://godotengine.org/download)

### Manual Installation

1.  **Clone the Repository**:
	Open your terminal or command prompt and clone the project to your local machine:

	```bash
	git clone https://github.com/sumit-sinha-playground/cat-superhero.git
	cd cat-superhero
	```

2.  **Open with Godot Engine**:
	*   Launch the Godot Engine.
	*   In the Project Manager, click on "Import".
	*   Navigate to the `cat-superhero` directory you just cloned and select the `project.godot` file.
	*   Click "Open" to add the project to your Godot Project Manager.

3.  **Run the Game**:
	*   Select the `cat-superhero` project in the Godot Project Manager and click "Edit".
	*   Once the editor loads, press the "Play" button (▶️ icon) in the top right corner of the editor to start the game.
	*   Alternatively, you can also play a web version [here](https://sumit-sinha-playground.github.io/cat-superhero/).

---

## 🎮 Usage Examples

Once installed, running `cat-superhero` is straightforward.

### Playing the Game

1.  **Launch from Godot Editor**:
	As described in the installation, simply open the project in the Godot Editor and press the Play button.

	```gdscript
	# No direct code execution needed for playing the game.
	# The game runs directly from the Godot editor.
	# To launch a specific scene for testing:
	# Go to Scene -> Run Scene (or press F6)
	```

2.  **Basic Controls**:
	*   **Movement**: Use `A` and `D` (or Left/Right Arrow keys) to move horizontally.
	*   **Jump**: Press `Spacebar` (or `W`/Up Arrow key) to jump.
	*   **Special Ability**: Press `E` (or a designated key) to activate your cat superhero's unique power.

### Game Configuration (Placeholder)

Currently, there are no in-game configuration options available outside the Godot editor. Future versions may include settings for graphics, audio, and controls.

| Setting        | Description                                       | Default Value |
| :------------- | :------------------------------------------------ | :------------ |
| `master_volume`| Overall game volume                               | `100%`        |
| `screen_mode`  | Toggle between fullscreen and windowed            | `Windowed`    |
| `key_bindings` | Customizable key assignments for actions          | `Default`     |

---

## 🗺️ Project Roadmap

Our journey with `cat-superhero` is just beginning! Here's a glimpse of what's planned for future development:

### Upcoming Features

*   **Version 1.1 - New Adventures**:
    *   🌌 Introduce 3 new levels with unique environments and challenges.
    *   🐾 Unlock an additional cat superpower, expanding gameplay mechanics.
    *   👾 Implement new enemy types with distinct behaviors.
*   **Version 1.2 - Polish & Performance**:
    *   ✨ Enhance UI/UX for a more intuitive and immersive experience.
    *   🚀 Optimize game performance across various hardware configurations.
    *   🐛 Address known bugs and stability issues.
*   **Version 1.x - Community & Content**:
    *   🤝 Explore possibilities for community-contributed levels or assets.
    *   🏆 Implement an in-game achievement system.
	*   📖 Expand the game's lore and story elements.

---

## 🤝 Contribution Guidelines

We welcome contributions from the community to make `cat-superhero` even better! Please adhere to the following guidelines:

### Code Style

*   **GDScript Style**: Follow the official [Godot GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_style_guide.html) for consistency.
*   **Comments**: Use clear and concise comments to explain complex logic, especially for functions and classes.
*   **Naming Conventions**:
	*   `snake_case` for variables and function names.
	*   `PascalCase` for class names and file names (e.g., `PlayerCharacter.gd`).

### Branch Naming Conventions

*   `feature/your-feature-name`: For new features.
*   `bugfix/issue-description`: For bug fixes.
*   `hotfix/critical-issue`: For urgent fixes to production.
*   `docs/update-description`: For documentation updates.

### Pull Request (PR) Process

1.  **Fork the Repository**: Start by forking the `cat-superhero` repository to your GitHub account.
2.  **Create a New Branch**: Create a new branch from `main` with an appropriate name (see above).
	```bash
	git checkout main
	git pull origin main
	git checkout -b feature/my-awesome-feature
	```
3.  **Make Your Changes**: Implement your feature or fix.
4.  **Commit Your Changes**: Write clear, descriptive commit messages.
	```bash
	git commit -m "feat: Add new jumping animation for cat superhero"
	```
5.  **Push to Your Fork**:
	```bash
	git push origin feature/my-awesome-feature
	```
6.  **Open a Pull Request**: Go to the original `cat-superhero` repository on GitHub and open a new Pull Request.
	*   Provide a clear title and detailed description of your changes.
	*   Reference any related issues (e.g., `Closes #123`).

### Testing Requirements

*   **Self-Testing**: Before submitting a PR, thoroughly test your changes to ensure they work as intended and do not introduce new bugs.
*   **Godot Editor**: Use the Godot Editor's built-in debugger and profiler to identify and resolve issues.

---

## ⚖️ License Information

This project is currently **Unlicensed**.

*   This means that all rights are reserved by the creators.
*   You may not distribute, modify, or use this software for any purpose without explicit permission from the main contributors.

**Copyright (c) 2026 broder, sumit-sinha-playground, mjimaz**
