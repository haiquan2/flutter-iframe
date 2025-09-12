# LUMIR Chat Widget

Flutter Web chat widget tích hợp vào website qua iframe.

## 🚀 Setup

```bash
git clone https://github.com/haiquan2/flutter-iframe.git
cd flutter-iframe
flutter pub get
```

## ⚙️ Environment

```bash
# .env hoặc dart-define
BASE_URL=you_endpoint
SESSIONS_URL=you_endpoint
```

## 🏃‍♂️ Development

```bash
flutter run -d chrome --web-port 8080 --dart-define=BASE_URL=your_endpoint --dart-define=SESSIONS_URL=your_end_point
flutter build web --release                    # Production build
```

## 🌐 Integration


### Direct Iframe
```html
<iframe src="https://your-app.com/?iframe=true&theme=light" 
    width="400" height="600">
</iframe>
```

### PostMessage API
```javascript
iframe.contentWindow.postMessage({
  type: 'USER_INFO',
  payload: { name: 'User', email: 'user@email.com' }
}, '*');
```

## 📁 Structure

```
lib/
├── core/
│   ├── theme/             # Theme & color schemes
│   └── provider/          # State management providers
├── models/
│   └── message.dart       # Chat message model
├── pages/
│   ├── chat/              # Main chat interface
│   └── home/              # Landing page
├── services/
│   └── chat_service.dart  # API calls & business logic
├── widgets/
│   ├── common/            # Reusable components
│   └── messages/          # Message UI components
├── env.deploy.dart        # Environment config
└── main.dart              # App entry point
```

## 🛠 Tech Stack

- **Flutter Web** (>=3.3.0)
- **Provider** (State management)
- **GoRouter** (Routing)
- **Dio** (HTTP client)

## 📞 Support

- Issues: [GitHub](https://github.com/haiquan2/flutter-iframe/issues)