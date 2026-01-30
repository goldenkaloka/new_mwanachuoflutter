class OnboardingData {
  final String title;
  final String body;
  final String assetPath;
  final String buttonText;

  OnboardingData({
    required this.title,
    required this.body,
    required this.assetPath,
    required this.buttonText,
  });
}

final List<OnboardingData> onboardingPages = [
  OnboardingData(
    title: 'Welcome to Mwanachuoshop!',
    body:
        'The ultimate marketplace for university students. Buy, sell, and connect with your campus community.',
    assetPath: 'assets/svgs/college students-amico.svg',
    buttonText: 'Next',
  ),
  OnboardingData(
    title: 'Buy & Sell Easily',
    body:
        'Find textbooks, electronics, dorm essentials, and more. List your own items to make extra cash!',
    assetPath: 'assets/svgs/Shopping-pana.svg',
    buttonText: 'Next',
  ),
  OnboardingData(
    title: 'Connect & Grow',
    body:
        'Join a network of students, find services, and check out what others are doing on campus.',
    assetPath: 'assets/svgs/Contact us-bro.svg',
    buttonText: 'Get Started',
  ),
];
