import 'dart:math' as math;

import 'package:chance/engine/lesson_spec.dart';
import 'package:chance/lessons/registry.dart';

/// General questions for the daily challenge, on top of lesson quizzes.
const List<QuizQuestion> kPracticeBank = [
  QuizQuestion(
    prompt: 'What is the mean of 2, 4, 4, 5 and 10?',
    options: ['4', '5', '4.5', '10'],
    answer: 1,
    explanation: '(2 + 4 + 4 + 5 + 10) / 5 = 25 / 5 = 5.',
  ),
  QuizQuestion(
    prompt: 'What is the median of 2, 4, 4, 5 and 10?',
    options: ['4', '5', '4.5', '2'],
    answer: 0,
    explanation: 'Sorted, the middle value of five numbers is the 3rd one: 4. '
        'Unlike the mean, the median ignores how big the 10 is.',
  ),
  QuizQuestion(
    prompt: 'You roll a fair die. What is P(not a 6)?',
    options: ['1/6', '1/2', '5/6', '6/5'],
    answer: 2,
    explanation: 'Complement rule: 1 − P(6) = 1 − 1/6 = 5/6.',
  ),
  QuizQuestion(
    prompt: 'You flip two fair coins. What is P(both heads)?',
    options: ['1/2', '1/3', '1/4', '2/3'],
    answer: 2,
    explanation: 'Independent events multiply: 1/2 × 1/2 = 1/4. '
        'Outcomes: HH, HT, TH, TT.',
  ),
  QuizQuestion(
    prompt: 'How many ways can 3 people stand in a line?',
    options: ['3', '6', '9', '27'],
    answer: 1,
    explanation: '3 choices for first, 2 for second, 1 for last: 3! = 6.',
  ),
  QuizQuestion(
    prompt: 'How many 2-person teams can you pick from 5 people?',
    options: ['10', '20', '25', '5'],
    answer: 0,
    explanation: 'Order doesn\'t matter: C(5, 2) = 5 × 4 / 2 = 10.',
  ),
  QuizQuestion(
    prompt: 'A dataset has a few very large values. Which is pulled up the most?',
    options: ['The median', 'The mode', 'The mean', 'None of them'],
    answer: 2,
    explanation: 'The mean uses every value\'s size, so outliers drag it. '
        'That\'s why incomes are usually reported as medians.',
  ),
  QuizQuestion(
    prompt: 'Roughly what share of a normal distribution lies within 1 sd of the mean?',
    options: ['50%', '68%', '95%', '99.7%'],
    answer: 1,
    explanation: 'The 68-95-99.7 rule: about 68% within 1 sd, 95% within 2, '
        '99.7% within 3.',
  ),
  QuizQuestion(
    prompt: 'Ice-cream sales and drownings rise together. The best explanation?',
    options: [
      'Ice cream causes drowning',
      'Drowning causes ice-cream sales',
      'Hot weather drives both',
      'It must be a coincidence',
    ],
    answer: 2,
    explanation: 'Correlation is not causation. A hidden third variable '
        '(summer heat) pushes both up.',
  ),
  QuizQuestion(
    prompt: 'In a room of 23 people, the chance two share a birthday is about…',
    options: ['6%', '25%', '50%', '90%'],
    answer: 2,
    explanation: 'The birthday paradox: 23 people make 253 pairs, which is '
        'plenty of chances for a match.',
  ),
  QuizQuestion(
    prompt: 'A z-score of −2 means the value is…',
    options: [
      '2 below the mean',
      '2 standard deviations below the mean',
      'In the bottom 2%',
      'An error',
    ],
    answer: 1,
    explanation: 'z = (x − mean) / sd, so it counts standard deviations from the mean.',
  ),
  QuizQuestion(
    prompt: 'What is the expected value of one roll of a fair die?',
    options: ['3', '3.5', '4', '6'],
    answer: 1,
    explanation: '(1 + 2 + 3 + 4 + 5 + 6) / 6 = 21 / 6 = 3.5.',
  ),
];

/// Every question available: the bank plus all built lesson quizzes.
List<QuizQuestion> get allQuestions => [
      ...kPracticeBank,
      for (final spec in lessonRegistry.values) ...spec.quiz,
    ];

/// Today's 5 daily-challenge questions. Same for everyone on the same day.
List<QuizQuestion> dailyChallengeFor(DateTime day, {int count = 5}) {
  final seed = day.year * 10000 + day.month * 100 + day.day;
  final pool = [...allQuestions]..shuffle(math.Random(seed));
  return pool.take(count).toList();
}

/// Random questions from lessons the learner has finished (plus the bank).
List<QuizQuestion> practiceSet(Set<String> completed, {int count = 5, math.Random? rng}) {
  final pool = [
    ...kPracticeBank,
    for (final id in completed) ...?lessonRegistry[id]?.quiz,
  ]..shuffle(rng ?? math.Random());
  return pool.take(count).toList();
}
