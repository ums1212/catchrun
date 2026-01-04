import 'dart:math';

class NicknameGenerator {
  static final List<String> _adjectives = [
    '빠른', '느긋한', '용감한', '영리한', '빛나는', '푸른', '붉은', '거대한', '작은', '강한',
    '날쌘', '멋진', '졸린', '행복한', '화난', '조용한', '시끄러운', '신비한', '평범한', '특별한'
  ];

  static final List<String> _nouns = [
    '호랑이', '사자', '펭귄', '독수리', '토끼', '거북이', '고양이', '강아지', '늑대', '곰',
    '바람', '구름', '햇살', '달빛', '파도', '나무', '바위', '불꽃', '번개', '별빛'
  ];

  static String generate() {
    final random = Random();
    final adj = _adjectives[random.nextInt(_adjectives.length)];
    final noun = _nouns[random.nextInt(_nouns.length)];
    final number = random.nextInt(9000) + 1000; // 1000~9999

    return '$adj$noun$number';
  }
}
