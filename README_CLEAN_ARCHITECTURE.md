# Mwanachuo Campus Marketplace - Clean Architecture Implementation

## 🏗️ Architecture Overview

This project follows **Clean Architecture** principles with **Supabase** backend and **BLoC/Cubit** state management.

### Architecture Layers

```
lib/
├── config/                    # App configuration
│   └── supabase_config.dart   # Supabase initialization
├── core/                      # Shared across features
│   ├── constants/             # App constants
│   ├── di/                    # Dependency injection
│   ├── enums/                 # Enums
│   ├── errors/                # Error handling
│   ├── network/               # Network utilities
│   ├── theme/                 # App theming
│   ├── usecases/              # Base use case classes
│   ├── utils/                 # Utilities
│   └── widgets/               # Shared widgets
└── features/                  # Feature modules
    └── <feature_name>/
        ├── data/
        │   ├── datasources/   # Remote & Local data sources
        │   ├── models/        # Data models
        │   └── repositories/  # Repository implementations
        ├── domain/
        │   ├── entities/      # Business models
        │   ├── repositories/  # Repository interfaces
        │   └── usecases/      # Business logic
        └── presentation/
            ├── bloc/          # BLoC state management
            ├── cubit/         # Cubit state management
            ├── pages/         # UI screens
            └── widgets/       # Feature-specific widgets
```

## 🚀 Getting Started

### Prerequisites

1. Flutter SDK (3.8.1 or higher)
2. Supabase Account
3. Android Studio / VS Code

### Setup Instructions

#### 1. Clone the Repository

```bash
git clone <repository-url>
cd mwanachuo
```

#### 2. Install Dependencies

```bash
flutter pub get
```

#### 3. Set up Supabase

1. Create a new project at [supabase.com](https://supabase.com)
2. Run the SQL script from `SUPABASE_SETUP.sql` in your Supabase SQL Editor
3. Create storage buckets in Supabase Dashboard:
   - `product-images`
   - `service-images`
   - `accommodation-images`
   - `promotion-images`
   - `profile-images`
4. Configure bucket policies (public read access)

#### 4. Configure Supabase Credentials

Update `lib/config/supabase_config.dart`:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

#### 5. Generate Code

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 6. Run the App

```bash
flutter run
```

## 👥 User Roles System

### Roles

1. **Buyer** (Default)
   - Browse products, services, accommodations
   - Make purchases
   - Send messages
   - Leave reviews
   - Request seller access

2. **Seller**
   - All buyer permissions
   - List products, services, accommodations
   - Create promotions
   - View seller dashboard
   - Manage listings

3. **Admin**
   - All seller permissions
   - Approve/Reject seller requests
   - Manage users
   - View all data

### Role Upgrade Flow

```
1. User signs up → Buyer role assigned automatically
2. Buyer requests seller access → Creates seller_request record
3. Admin reviews request
4. Admin approves → User role updated to 'seller'
5. Notification sent to user
```

## 📊 Database Schema

### Core Tables

- `users` - User profiles with role-based access
- `universities` - University information
- `products` - Product listings
- `services` - Service offerings
- `accommodations` - Housing listings
- `promotions` - Promotional campaigns
- `conversations` - Chat conversations
- `messages` - Chat messages
- `reviews` - Ratings and reviews
- `notifications` - User notifications
- `seller_requests` - Seller access requests

### Key Features

- **Row Level Security (RLS)**: All tables protected
- **ACID Compliance**: PostgreSQL transactions
- **Triggers**: Auto-update timestamps, user creation
- **Functions**: Seller approval, business logic
- **Indexes**: Optimized queries

## 🔄 State Management

### BLoC Pattern (Complex Features)

Used for: Authentication, Products, Messages

```dart
// Event
context.read<AuthBloc>().add(SignInEvent(email: email, password: password));

// State listening
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is Authenticated) {
      return HomePage();
    }
    return LoginPage();
  },
)
```

### Cubit Pattern (Simple Features)

Used for: Settings, Filters, UI state

```dart
// Action
context.read<ThemeCubit>().toggleTheme();

// State listening
BlocBuilder<ThemeCubit, ThemeState>(
  builder: (context, state) {
    return Text(state.isDark ? 'Dark' : 'Light');
  },
)
```

## 🔐 Security

### Row Level Security Policies

Every table has RLS policies ensuring:
- Users can only access their own data
- Sellers can create listings
- Admins have full access
- Public data is viewable by all

### Authentication

- Email/Password via Supabase Auth
- Session management
- Auto-login with cached credentials
- Secure token storage

## 📱 Features

### Implemented

✅ Clean Architecture structure
✅ Supabase integration
✅ Authentication system
✅ User roles (Buyer/Seller/Admin)
✅ Seller request workflow
✅ Database schema with RLS
✅ Error handling
✅ Dependency injection
✅ State management setup

### In Progress

🔄 Product listings CRUD
🔄 Service listings CRUD
🔄 Accommodation listings CRUD
🔄 Promotion management
🔄 Real-time messaging
🔄 Reviews and ratings
🔄 Notifications
🔄 Image upload to Supabase Storage

## 🧪 Testing

### Run Tests

```bash
# All tests
flutter test

# Unit tests
flutter test test/unit/

# Widget tests
flutter test test/widget/

# Integration tests
flutter test test/integration/
```

### Test Structure

```
test/
├── unit/
│   ├── domain/
│   │   └── usecases/
│   └── data/
│       ├── models/
│       └── repositories/
├── widget/
│   └── features/
└── integration/
    └── flows/
```

## 📝 Code Generation

### Generate Dependency Injection

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Generate Hive Adapters (if using Hive models)

```bash
flutter pub run build_runner build
```

## 🔧 Development Guidelines

### Adding a New Feature

1. Create feature folder structure:
   ```
   lib/features/my_feature/
   ├── data/
   ├── domain/
   └── presentation/
   ```

2. Domain Layer (business logic):
   - Create entity in `domain/entities/`
   - Create repository interface in `domain/repositories/`
   - Create use cases in `domain/usecases/`

3. Data Layer (data handling):
   - Create model extending entity in `data/models/`
   - Create remote data source in `data/datasources/`
   - Create local data source in `data/datasources/`
   - Implement repository in `data/repositories/`

4. Presentation Layer (UI):
   - Create BLoC/Cubit in `presentation/bloc/` or `presentation/cubit/`
   - Create pages in `presentation/pages/`
   - Create widgets in `presentation/widgets/`

5. Register dependencies in `lib/core/di/injection_container.dart`

### Code Style

- Use `const` constructors where possible
- Follow Clean Architecture dependency rules
- Write tests for use cases and repositories
- Use meaningful variable/function names
- Add comments for complex logic

## 🐛 Troubleshooting

### Common Issues

1. **Build runner errors**
   ```bash
   flutter pub run build_runner clean
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. **Supabase connection issues**
   - Check `supabase_config.dart` credentials
   - Verify RLS policies are set up
   - Check network connectivity

3. **Dependency injection errors**
   - Ensure all dependencies are registered
   - Run code generation
   - Check for circular dependencies

## 📚 Resources

- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Supabase Documentation](https://supabase.com/docs)
- [BLoC Pattern](https://bloclibrary.dev/)
- [Flutter Documentation](https://flutter.dev/docs)

## 📄 License

This project is licensed under the MIT License.

## 👥 Contributors

[Add contributors here]

---

**Note**: This is a comprehensive architecture setup. Make sure to replace placeholder values in `supabase_config.dart` with your actual Supabase credentials before running the app.

