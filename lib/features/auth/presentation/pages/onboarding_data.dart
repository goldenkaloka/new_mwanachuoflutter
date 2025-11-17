class OnboardingData {
  final String title;
  final String body;
  final String imageUrl;
  final String buttonText;

  OnboardingData({
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.buttonText,
  });
}

final List<OnboardingData> onboardingPages = [
  OnboardingData(
    title: 'Welcome to Mwanachuoshop!',
    body:
        'The ultimate marketplace for university students, covering everything from textbooks to dorm essentials.',
    imageUrl:
        'https://images.unsplash.com/photo-1523240795612-9a054b0db644?auto=format&fit=crop&w=800&q=80',
    buttonText: 'Next',
  ),
  OnboardingData(
    title: 'Discover Everything You Need',
    body:
        'From textbooks and electronics to dorm furniture, tutoring services, and event tickets, find everything for your university life right here.',
    imageUrl:
        'https://images.unsplash.com/photo-1523240795612-9a054b0db644?auto=format&fit=crop&w=800&q=80',
    buttonText: 'Next',
  ),
  OnboardingData(
    title: 'Connect & Earn',
    body:
        'Chat directly with sellers for a better buying experience and list your own items to make extra money on campus.',
    imageUrl:
        'https://images.unsplash.com/photo-1523240795612-9a054b0db644?auto=format&fit=crop&w=800&q=80',
    buttonText: 'Get Started',
  ),
];
