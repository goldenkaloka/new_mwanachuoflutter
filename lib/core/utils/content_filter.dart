import 'dart:core';

/// Utility class to filter and detect restricted content in messages
/// Optimized for Tanzania and Swahili language
/// Uses regex patterns for fast, free content filtering
class ContentFilter {
  // Pre-compile regex patterns for performance
  static final _emailPattern = RegExp(r'\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b');
  
  // English word-to-digit mapping
  static final Map<String, String> _englishWordToDigit = {
    'zero': '0', 'one': '1', 'two': '2', 'three': '3', 'four': '4',
    'five': '5', 'six': '6', 'seven': '7', 'eight': '8', 'nine': '9',
    'oh': '0', 'o': '0',
  };

  // Swahili word-to-digit mapping
  static final Map<String, String> _swahiliWordToDigit = {
    'sifuri': '0', 'moja': '1', 'mbili': '2', 'tatu': '3', 'nne': '4',
    'tano': '5', 'sita': '6', 'saba': '7', 'nane': '8', 'tisa': '9',
  };

  // Combined word mapping (English + Swahili)
  static Map<String, String> get _wordToDigit => {
    ..._englishWordToDigit,
    ..._swahiliWordToDigit,
  };

  // Swahili keywords that indicate phone sharing
  static final List<String> _swahiliPhoneKeywords = [
    'namba yangu',
    'namba yako',
    'namba ni',
    'namba za',
    'namba ya simu',
    'namba ya simu yangu',
    'namba ya simu yako',
    'piga simu',
    'piga mimi',
    'piga kwa',
    'wasiliana nami',
    'wasiliana na mimi',
    'wasiliana',
    'niumbie namba',
    'namba',
    'simu yangu',
    'simu yako',
    'namba ya',
    'whatsapp',
    'sms',
    'text',
    'piga',
    'call',
  ];

  // English keywords (for mixed language)
  static final List<String> _englishPhoneKeywords = [
    'call me at',
    'call me on',
    'my number is',
    'my phone is',
    'contact me at',
    'reach me at',
    'whatsapp me',
    'text me at',
    'sms me',
    'phone:',
    'tel:',
    'mobile:',
    'cell:',
  ];

  /// Validate message with conversation context
  /// recentMessages: List of recent messages in the conversation (last 5-10 messages)
  static String? validateMessage(
    String content, {
    List<String> recentMessages = const [],
  }) {
    final trimmedContent = content.trim();
    
    // Early exit if content is very short
    if (trimmedContent.length < 3) return null;
    
    final lowerContent = trimmedContent.toLowerCase();

    // 1. Check for direct phone numbers in current message
    if (_containsPhoneNumber(lowerContent)) {
      return 'Kwa usalama wako, tafadhali endelea kuwasiliana ndani ya programu tu. Namba za simu haziruhusiwi.';
    }

    // 2. Check for word-based numbers (English + Swahili) in current message
    if (_containsWordNumbers(lowerContent)) {
      return 'Kwa usalama wako, tafadhali endelea kuwasiliana ndani ya programu tu. Namba za simu haziruhusiwi.';
    }

    // 3. Check for split numbers across recent messages
    if (recentMessages.isNotEmpty) {
      final combinedContent = _combineRecentMessages(recentMessages, trimmedContent);
      if (_containsPhoneNumber(combinedContent.toLowerCase())) {
        return 'Kwa usalama wako, tafadhali endelea kuwasiliana ndani ya programu tu. Namba za simu haziruhusiwi.';
      }
      
      // Check for word numbers in combined context
      if (_containsWordNumbers(combinedContent.toLowerCase())) {
        return 'Kwa usalama wako, tafadhali endelea kuwasiliana ndani ya programu tu. Namba za simu haziruhusiwi.';
      }
    }

    // 4. Check for email addresses
    if (_containsEmail(lowerContent)) {
      return 'Kwa usalama wako, tafadhali endelea kuwasiliana ndani ya programu tu. Anwani za barua pepe haziruhusiwi.';
    }

    // 5. Check for social media links
    if (_containsSocialMedia(lowerContent)) {
      return 'Kwa usalama wako, tafadhali endelea kuwasiliana ndani ya programu tu. Viungo vya mitandao ya kijamii haviruhusiwi.';
    }

    // 6. Check for external links
    if (_containsExternalLinks(lowerContent)) {
      return 'Kwa usalama wako, tafadhali endelea kuwasiliana ndani ya programu tu. Viungo vya nje haviruhusiwi.';
    }

    return null; // Content is safe
  }

  /// Combine recent messages with current message to detect split numbers
  static String _combineRecentMessages(List<String> recentMessages, String currentMessage) {
    // Take last 5 messages (to avoid checking too far back)
    final recent = recentMessages.length > 5 
        ? recentMessages.sublist(recentMessages.length - 5)
        : recentMessages;
    
    // Combine recent messages + current message
    return [...recent, currentMessage].join(' ');
  }

  /// Detect phone numbers in various formats (Tanzania-specific)
  static bool _containsPhoneNumber(String content) {
    // Remove common separators
    final normalized = content.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');

    // Pattern 1: 10+ consecutive digits
    if (RegExp(r'\d{10,}').hasMatch(normalized)) {
      final match = RegExp(r'\d{10,}').firstMatch(normalized);
      if (match != null) {
        final startIndex = match.start;
        final endIndex = match.end;
        final before = startIndex > 0 ? normalized[startIndex - 1] : ' ';
        final after = endIndex < normalized.length ? normalized[endIndex] : ' ';
        
        if (!RegExp(r'\d').hasMatch(before) && !RegExp(r'\d').hasMatch(after)) {
          return true;
        }
      }
    }

    // Pattern 2: Tanzania international format (+255)
    if (RegExp(r'\+?255\d{9}').hasMatch(content)) {
      return true;
    }

    // Pattern 3: Tanzania local format (0712, 0754, 0767, 0784, etc.)
    // Common prefixes: 071, 072, 073, 074, 075, 076, 077, 078, 079
    if (RegExp(r'0[67]\d{1}[\s\-]?\d{3}[\s\-]?\d{3,4}').hasMatch(content)) {
      return true;
    }

    // Pattern 4: Common phone patterns with separators
    if (RegExp(r'\(?\d{3,4}\)?[\s\-\.]?\d{3}[\s\-\.]?\d{3,4}').hasMatch(content)) {
      return true;
    }

    // Pattern 5: Keywords that indicate phone sharing (Swahili + English)
    final allKeywords = [..._swahiliPhoneKeywords, ..._englishPhoneKeywords];
    
    for (final keyword in allKeywords) {
      if (content.contains(keyword)) {
        final index = content.indexOf(keyword);
        final afterKeyword = content.substring(index + keyword.length).trim();
        // Check if followed by numbers or number words
        if (RegExp(r'\d{7,}').hasMatch(afterKeyword) ||
            _containsWordNumbers(afterKeyword)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Detect word-based number representations (English + Swahili)
  static bool _containsWordNumbers(String content) {
    // Convert word numbers to digits (both English and Swahili)
    String converted = content;
    _wordToDigit.forEach((word, digit) {
      // Match whole words only (not parts of words)
      converted = converted.replaceAll(
        RegExp(r'\b' + word + r'\b', caseSensitive: false),
        digit,
      );
    });

    // After conversion, check if we have a phone number pattern
    final normalized = converted.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    
    // Check for 10+ consecutive digits (likely phone number)
    if (RegExp(r'\d{10,}').hasMatch(normalized)) {
      // Check if original content had phone-related keywords
      final allKeywords = [..._swahiliPhoneKeywords, ..._englishPhoneKeywords];
      final hasPhoneKeywords = allKeywords.any((keyword) => content.contains(keyword));
      
      if (hasPhoneKeywords) {
        return true;
      }
      
      // Check if the digits form a valid phone pattern
      final digitSequence = RegExp(r'\d{10,}').firstMatch(normalized)?.group(0) ?? '';
      if (digitSequence.length >= 10) {
        // Tanzania patterns: starts with 0, +255, or 255
        if (digitSequence.startsWith('0') || 
            digitSequence.startsWith('255') ||
            digitSequence.startsWith('1')) {
          return true;
        }
      }
    }

    // Check for word sequences that form phone numbers
    // Pattern: "sifuri saba moja mbili..." or "zero seven one two..."
    final wordNumberPattern = RegExp(
      r'\b(sifuri|moja|mbili|tatu|nne|tano|sita|saba|nane|tisa|zero|one|two|three|four|five|six|seven|eight|nine|oh|o)\b',
      caseSensitive: false,
    );
    
    final matches = wordNumberPattern.allMatches(content);
    if (matches.length >= 10) {
      // Extract the word sequence
      final words = matches.map((m) => m.group(0)!.toLowerCase()).toList();
      
      // Convert to digits
      final digits = words.map((w) => _wordToDigit[w] ?? '').join('');
      
      // Check if it forms a phone number
      if (digits.length >= 10 && _looksLikePhoneNumber(digits)) {
        return true;
      }
    }

    return false;
  }

  /// Check if a digit sequence looks like a Tanzanian phone number
  static bool _looksLikePhoneNumber(String digits) {
    if (digits.length < 10) return false;
    
    // Tanzania local: starts with 0 (10 digits: 0712345678)
    if (digits.startsWith('0') && digits.length == 10) {
      // Check if it's a valid Tanzanian mobile prefix
      final prefix = digits.substring(0, 3);
      if (RegExp(r'0[67]\d').hasMatch(prefix)) {
        return true;
      }
    }
    
    // Tanzania international: starts with 255 (12 digits: 255712345678)
    if (digits.startsWith('255') && digits.length == 12) {
      return true;
    }
    
    // International format with +255
    if (digits.length >= 10 && digits.length <= 15) {
      // Common international patterns
      if (digits.startsWith('255') && digits.length == 12) return true;
      if (digits.startsWith('1') && digits.length == 11) return true; // US
      if (digits.startsWith('44') && digits.length >= 10) return true; // UK
    }
    
    return false;
  }

  /// Detect email addresses
  static bool _containsEmail(String content) {
    return _emailPattern.hasMatch(content);
  }

  /// Detect social media handles and links
  static bool _containsSocialMedia(String content) {
    final socialMediaPatterns = [
      r'instagram\.com',
      r'facebook\.com',
      r'twitter\.com',
      r'x\.com',
      r'linkedin\.com',
      r'snapchat\.com',
      r'tiktok\.com',
      r'whatsapp\.com',
      r'telegram\.me',
      r'@[a-zA-Z0-9_]+',
      r'fb\.com',
      r'ig\.me',
    ];

    for (final pattern in socialMediaPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(content)) {
        return true;
      }
    }

    return false;
  }

  /// Detect external website links
  static bool _containsExternalLinks(String content) {
    final safeDomains = ['mwanachuo', 'supabase', 'stripe', 'paypal'];

    final urlPattern = RegExp(
      r'https?://[^\s]+|www\.[^\s]+',
      caseSensitive: false,
    );

    if (urlPattern.hasMatch(content)) {
      final matches = urlPattern.allMatches(content);
      for (final match in matches) {
        final url = match.group(0)!.toLowerCase();
        final isSafe = safeDomains.any((domain) => url.contains(domain));
        if (!isSafe) {
          return true;
        }
      }
    }

    return false;
  }
}

