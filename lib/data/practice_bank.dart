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
  QuizQuestion(
    prompt: 'A basketball player scores 40% of free throws. What is the expected number of tries to the first score?',
    options: ['2', '2.5', '4', '0.4'],
    answer: 1,
    explanation: 'Geometric waiting time: E = 1/p = 1/0.4 = 2.5 tries.',
  ),
  QuizQuestion(
    prompt: 'A shop gets 4 customers an hour on average, at random. What is the variance of the hourly count?',
    options: ['2', '4', '16', '√4'],
    answer: 1,
    explanation: 'For a Poisson distribution the variance equals the mean: λ = 4.',
  ),
  QuizQuestion(
    prompt: 'Exam scores are normal with mean 60 and sd 10. About what share score above 80?',
    options: ['2.5%', '5%', '16%', '32%'],
    answer: 0,
    explanation: '80 is 2 sd above the mean. 95% lie within 2 sd, so 5% are outside, '
        'half of them on the high side: 2.5%.',
  ),
  QuizQuestion(
    prompt: 'Buses come every 10 minutes and you arrive at a random time. What is your average wait?',
    options: ['2 minutes', '5 minutes', '10 minutes', 'It depends on luck'],
    answer: 1,
    explanation: 'The wait is uniform from 0 to 10 minutes, so the mean is the middle: 5.',
  ),
  QuizQuestion(
    prompt: 'You change heights from metres to centimetres. What happens to their correlation with weight?',
    options: ['It is multiplied by 100', 'It is divided by 100', 'It stays the same', 'It becomes 1'],
    answer: 2,
    explanation: 'Correlation has no units: rescaling one variable cancels out. Covariance would change.',
  ),
  QuizQuestion(
    prompt: 'Whatever the shape of the data, at least what share lies within 2 sd of the mean?',
    options: ['50%', '68%', '75%', '95%'],
    answer: 2,
    explanation: 'Chebyshev: at least 1 − 1/k² = 1 − 1/4 = 75%. The 95% only holds for bell curves.',
  ),
  QuizQuestion(
    prompt: 'To halve the standard error of a sample mean, you need…',
    options: ['Twice the sample', 'Four times the sample', 'Half the sample', '√2 times the sample'],
    answer: 1,
    explanation: 'SE = σ/√n. Halving it needs √n to double, which means n × 4.',
  ),
  QuizQuestion(
    prompt: 'A poll asks only people at a gym about exercise habits. Asking more people at the gym will…',
    options: [
      'Remove the bias',
      'Shrink the random error but keep the bias',
      'Make the poll representative',
      'Increase the bias',
    ],
    answer: 1,
    explanation: 'Bigger samples reduce random wobble, not bias: every extra person comes from the same skewed group.',
  ),
  QuizQuestion(
    prompt: 'A poll of 1,000 people has a margin of error of about…',
    options: ['±1 point', '±3 points', '±10 points', '±30 points'],
    answer: 1,
    explanation: 'Roughly 1/√n = 1/√1000 ≈ 0.03, so about ±3 percentage points.',
  ),
  QuizQuestion(
    prompt: 'A study reports p = 0.03. What does that mean?',
    options: [
      'There is a 3% chance H₀ is true',
      'If H₀ were true, results this extreme would happen 3% of the time',
      'The effect is 3% big',
      'There is a 97% chance the effect is real',
    ],
    answer: 1,
    explanation: 'A p-value is computed assuming H₀ is true. It is not the chance that H₀ is true.',
  ),
  QuizQuestion(
    prompt: 'A test convicts an innocent defendant. Which error is that?',
    options: ['Type I', 'Type II', 'Both', 'Neither'],
    answer: 0,
    explanation: 'Rejecting a true H₀ ("innocent") is a Type I error: a false alarm.',
  ),
  QuizQuestion(
    prompt: 'A regression has R² = 0.64. What is |r|, the size of the correlation?',
    options: ['0.36', '0.64', '0.8', '0.41'],
    answer: 2,
    explanation: 'With one predictor, R² = r², so |r| = √0.64 = 0.8.',
  ),
  QuizQuestion(
    prompt: 'Your prior for a coin is Beta(1, 1). You see 3 heads and 1 tail. Your posterior is…',
    options: ['Beta(3, 1)', 'Beta(4, 2)', 'Beta(2, 4)', 'Beta(1, 1)'],
    answer: 1,
    explanation: 'Add the heads to the first number and the tails to the second: Beta(1 + 3, 1 + 1).',
  ),
  QuizQuestion(
    prompt: 'You throw 1,000 random darts at a square; 785 land inside the quarter circle. Your estimate of π?',
    options: ['3.00', '3.14', '0.785', '7.85'],
    answer: 1,
    explanation: 'Share inside ≈ π/4, so π ≈ 4 × 0.785 = 3.14.',
  ),
  QuizQuestion(
    prompt: 'A random walker takes 400 steps of ±1. Roughly how far from the start is it, typically?',
    options: ['0', '20', '200', '400'],
    answer: 1,
    explanation: 'The typical distance grows like √n: √400 = 20.',
  ),
  QuizQuestion(
    prompt: 'Red has come up 8 times in a row on a fair roulette wheel. The next spin is…',
    options: ['More likely black', 'More likely red', 'Equally likely as before', 'Certainly black'],
    answer: 2,
    explanation: 'Spins are independent. The wheel has no memory, so the streak changes nothing.',
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
