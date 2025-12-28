# Eduscan AI 🚀

**An AI-powered educational productivity app built with Flutter and Python.**

Eduscan AI helps students study smarter by converting physical notes into digital insights. It features OCR, AI summarization, flashcard generation, and an AI chat assistant.

## ✨ Features

*   **📄 PDF/Image to Text**: high-quality OCR for handwritten and printed notes.
*   **🤖 AI Study Packs**: Generates summaries, concept maps, and flashcards automatically.
*   **📝 Productivity Suite**: Built-in Journal, To-Do List, and Timetable manager.
*   **💬 Ask Sakhi**: An AI chat assistant dedicated to answering your study queries.
*   **📱 Cross-Platform**: Built with Flutter for a seamless mobile experience.

## 📥 Download

[**Download Latest APK**](https://github.com/yashpatil2005/eduscan_ai/releases)
*check the releases tab for the latest `app-release.apk`*

## 🛠️ Tech Stack

*   **Frontend**: Flutter (Dart)
*   **Backend**: Python (Flask)
*   **AI**: DeepSeek (via OpenRouter)
*   **Database**: Firebase Firestore

## 🚀 Getting Started

### Prerequisites

*   [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.
*   Python 3.8+ installed.
*   Firebase project setup.
*   OpenRouter API Key.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yashpatil2005/eduscan_ai.git
    cd eduscan_ai
    ```

2.  **Setup Backend:**
    ```bash
    cd eduscan_backend
    pip install -r requirements.txt
    # Create a .env file and add your OPENROUTER_API_KEY
    python app.py
    ```

3.  **Setup Frontend:**
    ```bash
    # From the root directory
    flutter pub get
    # Update api_service.dart with your backend URL
    flutter run
    ```

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
