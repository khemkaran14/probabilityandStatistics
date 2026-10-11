/// "Why does this work?": the reasoning behind each lesson's formula,
/// shown under the big idea. Keyed by lesson id; every lesson has one.
const Map<String, String> kWhy = {
  'types_of_data':
      'An average needs arithmetic: adding values and dividing only means something if the gaps between values are real amounts. The gap from 3 to 4 children is one child, the same as from 7 to 8. The gap from \'medium\' to \'large\' has no size at all. So categories can only be counted (use the mode), ordered labels can also be ranked (median, percentiles), and only true numbers can be averaged.',
  'averages':
      'The mean is the balance point: mean × n = total. Add an outlier of 200 to ten values and the total jumps by 200, so the mean jumps by about 200 ÷ 11 ≈ 18. The median only cares which value sits in the middle position. An outlier, however huge, moves the middle by at most one place, so the median barely shifts. The mode only counts repeats, so it ignores the outlier completely.',
  'spread':
      'Plain distances from the mean always add up to exactly zero: that\'s what makes it the mean. Squaring makes every distance positive and has a bonus: variances of independent things simply add. The square root then brings the answer back to the original units. We divide by n − 1, not n, because distances measured from the sample\'s own mean come out slightly too small (see \'Why divide by n − 1?\' in chapter 12).',
  'percentiles':
      'The smallest value sits at position 0 and the largest at position n − 1. Going p of the way along that line lands at position p × (n − 1). If that falls between two values, take the point the same fraction of the way between them. Software packages use slightly different conventions for this, but they agree closely once there is plenty of data.',
  'skew':
      'The mean is a balance point, and a value far out on a long tail is like a weight on a long lever: it pulls the balance point towards the tail. The median only counts how many values are on each side, not how far away they are, so it stays with the bulk of the data. That\'s why mean − median > 0 points to a right skew and < 0 to a left skew.',
  'outliers':
      'The IQR uses only the middle half of the data, so the outliers themselves can\'t inflate it. The standard deviation would get stretched by the very values you\'re trying to catch. For bell-shaped data, the fences at Q1 − 1.5·IQR and Q3 + 1.5·IQR sit about 2.7 standard deviations from the middle, so only about 0.7% of values get flagged. A flagged value really is unusual.',
  'zscores':
      'Subtracting the mean moves the average to 0, so the sign tells you above or below. Dividing by the sd changes the units from \'marks\' to \'standard deviations\'. On a test where marks are tightly bunched, each extra mark is harder to get, so it counts for more. English: 8 marks above with sd 5 gives 1.6. Maths: 18 above with sd 12 gives only 1.5. Z-scores always have mean 0 and sd 1, whatever the original scale.',
  'bar_pie':
      'Experiments on how people read charts (Cleveland & McGill, 1984) found we judge positions along a shared scale most accurately, then lengths, then angles and areas. Bars use position and length; pies use angle and area. A slice\'s angle is share × 360° because the whole circle stands for 100%. That\'s also why a pie only makes sense when the parts add up to one whole.',
  'histograms':
      'With k bins, each bin holds about n/k values, and a count of c values naturally wobbles by about √c. Too many bins leave a handful of values per bin and the wobble drowns the shape. Too few bins average the shape away. About √n bins balances the two: roughly √n values per bin. Other rules of thumb, like Sturges\' 1 + log₂n, are just different compromises.',
  'box_plots':
      'The median and quartiles depend only on the order of the values, not on how extreme the biggest ones are. That makes them resistant: one wild value can\'t drag the box around. The box is the spread of the middle half (the IQR), so comparing boxes compares typical values. Whiskers usually stop at the 1.5 × IQR fences and show any outliers beyond them as separate dots.',
  'scatter':
      'Each dot adds (x − x̄)(y − ȳ) to the top of the formula. That\'s positive in the top-right and bottom-left quarters around the averages, and negative in the other two. The sum says which diagonal wins. Dividing by √(Σ(x − x̄)² · Σ(y − ȳ)²) removes the units, and the Cauchy–Schwarz inequality guarantees the answer lies between −1 and +1. It only reaches ±1 when every point sits exactly on a line.',
  'stem_leaf':
      'Each stem is a bin ten wide, and the number of leaves in a row is the count in that bin. The row of leaves is literally a bar, so you get a histogram for free. Because each leaf is a real digit, no information is lost: you can read every value back. With sorted leaves the data is in order, so the median is just the (n + 1)/2-th leaf.',
  'graphs_lie':
      'Your eye reads the ratio of bar heights. If the axis starts at b, the bars show (55 − b) ÷ (52 − b). Starting at 0 gives the honest 1.06. Starting at 50 gives 5 ÷ 2 = 2.5, which makes a 6% gap look like 150%. Only a zero baseline makes the picture\'s ratio equal the real ratio. Line charts are different: they show change, so their axis doesn\'t need to start at 0.',
  'events':
      'If all n outcomes are equally likely and their chances add up to 1, each one must have chance 1/n. An event\'s chance is the sum of its outcomes\' chances, so an event with k outcomes has k/n. The catch is the \'equally likely\' part. \'Rain or no rain\' has two outcomes, but that doesn\'t make rain a 50-50 chance.',
  'coin_flips':
      'The number of heads in n flips wobbles by about √(n·p(1 − p)). That wobble grows, but much more slowly than n does. So the share of heads, heads ÷ n, wobbles by only √(p(1 − p)/n), which shrinks towards 0. With 100 flips the share is typically within ±5% of p; with 10,000 flips, within ±0.5%. The count of heads minus tails can still drift: it\'s the proportion that settles.',
  'complement':
      'Every outcome is either \'at least one six\' or \'no six\', never both and never neither. All the chances add up to 1, so P(A) + P(not A) = 1. \'No six\' on four dice means each die independently misses, with chance 5/6 each. Multiplying gives (5/6)⁴ ≈ 0.482, so P(at least one six) = 1 − 0.482 = 0.518.',
  'venn':
      'P(A) counts every outcome inside A, including those that are also in B. P(B) counts those shared outcomes too. So in P(A) + P(B), everything in the overlap is counted twice. Subtracting P(A and B) once leaves every outcome in \'A or B\' counted exactly once. With three sets you subtract the pairwise overlaps and add back the triple overlap. This pattern is called inclusion–exclusion.',
  'mutually_exclusive':
      'When two events can\'t happen together, P(A and B) = 0, so the addition rule loses its last term and you just add. Hearts or spades: 13 + 13 = 26 out of 52. Hearts or kings: 13 + 4 − 1 = 16 out of 52, because the king of hearts belongs to both. Careful: mutually exclusive is the opposite of independent. If A happens, B certainly doesn\'t, so knowing one tells you a lot about the other.',
  'multiplication_principle':
      'Draw the choices as a tree: 3 shirt branches, each splitting into 2 trouser branches, each splitting into 2 shoe branches. Every outfit is exactly one path from the root to a leaf, and every path is an outfit, so counting leaves counts outfits: 3 × 2 × 2. It works whenever the number of options at each step stays the same, even if which options are available changes.',
  'permutations':
      'By the multiplication principle, filling r places from n gives n × (n − 1) × … × (n − r + 1). Write it as n! ÷ (n − r)!: the (n − r)! cancels the tail of n! that you never used. With r = n you\'re arranging everyone, and since 0! = 1 you get n! arrangements.',
  'combinations':
      'Every team of r people can be put in order in r! different ways, and each ordering is a different permutation. So the number of permutations is the number of teams × r!. Divide it out: nCr = n! ÷ (r!(n − r)!). There\'s a nice symmetry too: choosing r people to include is the same as choosing n − r to leave out, so nCr = nC(n − r).',
  'repeats':
      'Pretend the letters are all different: label them A₁ A₂ A₃ and N₁ N₂. That gives 6! = 720 arrangements. Each real word matches 3! × 2! = 12 labelled ones, because the labels can be shuffled among the A positions and among the N positions without changing the word. So there are 720 ÷ 12 = 60 words. In general it\'s n! ÷ (n₁! n₂! …).',
  'pigeonhole':
      'Suppose no hole held two pigeons. Then each hole holds at most one, so 5 holes hold at most 5 pigeons, but there are 6. That\'s a contradiction, so some hole must hold two. In general, n items in k holes put at least ⌈n/k⌉ in some hole. A head has at most about 150,000 hairs: far fewer possible counts than a million people, so two must share a count.',
  'birthday':
      'Count the opposite. Person 1 can have any birthday. Person 2 must avoid one day (364/365), person 3 must avoid two days (363/365), and so on. Multiply these, since each step assumes everyone so far is different. For 23 people the product is about 0.493, so P(match) ≈ 0.507. A quick check: 253 pairs, each matching with chance 1/365, gives about e^(−253/365) ≈ 0.50 for no match.',
  'conditional':
      'Being told that B happened makes B the whole world, so its chances must be rescaled until B has total probability 1. The only part of A that is still possible is \'A and B\'. Dividing by P(B) does the rescaling: P(A | B) = P(A and B) ÷ P(B). In counts it\'s just 12 cricketers among the 40 glasses-wearers, which is 0.30.',
  'independence':
      'The multiplication rule always says P(A and B) = P(A) × P(B | A). Independence means knowing A changes nothing, so P(B | A) = P(B), and the rule becomes P(A) × P(B). For two fair coins that\'s ½ × ½ = ¼. With the sticky coin, P(B | A) is bigger than P(B), so heads-heads turns up more than a quarter of the time.',
  'tree_diagrams':
      'A path is a sequence: first this happens, then that happens given the first. By the multiplication rule its chance is the product of the branches. Different paths can\'t both happen, so for \'either\' you add their chances. One of each = RB + BR = (3/5 × 2/4) + (2/5 × 3/4) = 0.3 + 0.3 = 0.6. All the leaf probabilities add up to 1, which is a handy check.',
  'multiplication_rule':
      'This is the definition of conditional probability rearranged: P(B | A) = P(A and B) ÷ P(A), so multiply both sides by P(A). In the picture, the strip\'s width is P(A) and the purple part\'s height inside it is P(B | A). The area is width × height. You can also slice it the other way, P(B) × P(A | B), and get the same area.',
  'total_probability':
      'Factories A, B and C split all the bulbs into groups that don\'t overlap and leave nothing out (a partition). So \'faulty\' splits the same way into faulty-and-A, faulty-and-B and faulty-and-C. Separate pieces add up. Each piece is P(factory) × P(faulty | factory), by the multiplication rule: 0.020 + 0.018 + 0.030 = 0.068.',
  'bayes':
      'Bayes\' theorem: P(sick | +) = P(+ | sick) · P(sick) ÷ P(+). The bottom comes from the law of total probability: P(+) = P(+ | sick)·P(sick) + P(+ | healthy)·P(healthy). In counts, imagine 1,000 people at 1% prevalence: 10 are sick and 9 test positive; 990 are healthy and 9% of them, about 89, also test positive. So 9 ÷ (9 + 89) ≈ 9%. Thinking in counts makes Bayes easy.',
  'monty_hall':
      'List the cases. You pick door 1. The car is behind door 1 (chance 1/3): switching loses. Behind door 2 (1/3): the host must open door 3, and switching wins. Behind door 3 (1/3): the host must open door 2, and switching wins. Switching wins 2 cases out of 3. It isn\'t 50-50 because the host never opens the car\'s door. Imagine 100 doors where the host opens 98 goats: switching is obviously smart.',
  'discrete_continuous':
      'On a fair spinner, the chance of landing in a range is its length: P(0.4 ≤ X ≤ 0.6) = 0.2. Shrink the range around 0.5: [0.49, 0.51] gives 0.02, and [0.4999, 0.5001] gives 0.0002. A single point has length 0, so its chance is 0, even though some exact value always comes up. That\'s why continuous variables use a density: probability per unit of length.',
  'pmf_cdf':
      'Count the dice pairs. A total of 7 comes from (1,6), (2,5), … , (6,1): 6 of the 36 rolls. A total of 2 comes only from (1,1). Counting every total gives the triangle 1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1 (out of 36). The CDF F(x) = P(X ≤ x) adds the bars up to x, so it jumps by each bar\'s height and has to finish at 1. Ranges come for free: P(a < X ≤ b) = F(b) − F(a).',
  'expected_value':
      'Picture 100 spins landing in exactly the right proportions. 60 lose ₹10 (−₹600), 25 win nothing, 10 win ₹10 (+₹100) and 5 win ₹90 (+₹450). The total is −₹50, which is −₹0.50 per spin. That calculation is exactly Σ x·p(x): the average you\'d get if every outcome came up in its true share. The Law of Large Numbers says real long-run averages head there.',
  'variance_rv':
      'When rounds are independent, variances add. So n rounds have variance n·Var(X), and the spread of your total is sd × √n. The risky game pays +₹9 one time in 10 and −₹1 nine times in 10. That averages 0, with variance 9 and sd ₹3. After 100 rounds the expected total is still ₹0, but a typical player is about 3 × 10 = ₹30 away from it.',
  'linearity':
      'E[X + Y] is a weighted sum over all outcomes, and a sum can always be split up: Σ(X + Y)·p = ΣX·p + ΣY·p. Nothing in that step needs X and Y to be independent. Person i\'s score averages P(they get their own hat), and their hat is equally likely to be any of the n hats, so that\'s 1/n. Adding n of them gives 1. (Adding variances is what needs independence, not adding averages.)',
  'bernoulli':
      'E[X] = 1·p + 0·(1 − p) = p. Because X is only ever 0 or 1, X² = X, so E[X²] = p too. Then Var(X) = E[X²] − (E[X])² = p − p² = p(1 − p). This is largest at p = 0.5 (0.25): a fair coin is the hardest to predict, and p near 0 or 1 is nearly certain.',
  'galton':
      'To land in bin k, a ball must go right exactly k times out of 8. Any one such path has chance p^k (1 − p)^(8−k), and there are C(8, k) of them (choose which rows go right). So P(bin k) = C(8, k) p^k (1 − p)^(8−k): the binomial. The middle bins have by far the most paths: C(8, 4) = 70, against just 1 for the edge. The mean is n·p because each row adds p rights on average.',
  'geometric':
      'Needing exactly k tries means k − 1 independent misses and then a hit: (1 − p)^(k−1)·p. For the average: with chance p you\'re done in 1 try. Otherwise you\'ve spent 1 try and you\'re back at the start, because the process has no memory. So E = 1 + (1 − p)·E, which solves to E = 1/p. With p = 0.3 that\'s about 3.33 tries.',
  'negative_binomial':
      'The k-th trial must be the r-th success. Among the first k − 1 trials, choose which r − 1 were successes: C(k − 1, r − 1) ways. Each arrangement has chance p^r (1 − p)^(k−r). The total wait is r separate geometric waits in a row, each averaging 1/p, so by linearity E = r/p. Adding several waits together is also why the shape becomes more bell-like as r grows.',
  'hypergeometric':
      'All C(20, 5) handfuls are equally likely. Those with exactly k reds pick k of the 8 reds and 5 − k of the 12 blues: C(8, k)·C(12, 5 − k) ways. For the mean, notice that any single draw is equally likely to be any ball, so each draw is red with chance 8/20. By linearity E = 5 × 8/20 = 2, just like drawing with replacement. The variance is smaller by the factor (20 − 5)/(20 − 1).',
  'poisson':
      'Cut the window into n tiny slices, each with chance λ/n of an arrival. The count is then Binomial(n, λ/n). As the slices shrink (n → ∞), C(n, k)(λ/n)^k (1 − λ/n)^(n−k) turns into λ^k e^(−λ) / k!, because (1 − λ/n)^n → e^(−λ). The mean n·λ/n = λ, and the variance n(λ/n)(1 − λ/n) also tends to λ.',
  'discrete_uniform':
      'Pair the values up: 1 with n, 2 with n − 1, and so on. Every pair averages (n + 1)/2, so that\'s the mean. For the variance, E[X²] = (n + 1)(2n + 1)/6. Subtract the squared mean (n + 1)²/4 and it simplifies to (n² − 1)/12. For a die that\'s 35/12 ≈ 2.92.',
  'continuous_uniform':
      'The total area under a density must be 1. Over a width of b − a, that forces a height of 1/(b − a). The chance of [a, t] is then a rectangle: (t − a) × 1/(b − a). By symmetry the mean is the midpoint, (a + b)/2. The variance (b − a)²/12 is the continuous cousin of the die\'s (n² − 1)/12.',
  'normal_curve':
      'When a value is the sum of many small independent nudges, the Central Limit Theorem says the total is close to normal, whatever the nudges look like: the Galton board in slow motion. The formula e^(−(x−μ)²/2σ²) falls off with the squared distance from μ, so the tails thin out very fast. Dividing by σ√(2π) makes the area exactly 1. That puts the peak at 1/(σ√(2π)), which is why a wider bell must be shorter.',
  'standard_normal':
      'If X is normal with mean μ and sd σ, then Z = (X − μ)/σ is standard normal. Subtracting slides the bell to 0 and dividing rescales its width, but the shape stays the same. Since X ≤ x exactly when Z ≤ (x − μ)/σ, we get P(X ≤ x) = Φ((x − μ)/σ), so one table covers every normal. The curve is symmetric, so Φ(−z) = 1 − Φ(z), and tables only need positive z.',
  'rule_68_95':
      'These are just areas under the standard normal curve: Φ(1) − Φ(−1) = 0.683, Φ(2) − Φ(−2) = 0.954 and Φ(3) − Φ(−3) = 0.997. Any normal turns into the standard one through z-scores, so the same percentages hold for every mean and sd. The famous 1.96 is the exact cut-off that gives 95%; 2 is the rounded version.',
  'exponential':
      'Waiting longer than t means no arrivals in [0, t]. The Poisson count in that window has mean λt, so P(none) = e^(−λt), and that is P(X > t). Memorylessness falls out of the algebra: P(X > s + t | X > s) = e^(−λ(s+t)) ÷ e^(−λs) = e^(−λt), the same as starting fresh. The average wait is 1/λ.',
  'gamma_beta':
      'A Gamma(k) is the sum of k independent exponential waits with rate 1. Each wait has mean 1 and variance 1, so the sum has mean k and variance k, and by the CLT it gets bell-shaped as k grows. If X ~ Gamma(a) and Y ~ Gamma(b), then X/(X + Y) ~ Beta(a, b), with mean a/(a + b). The Beta density ∝ p^(a−1)(1 − p)^(b−1) has the same shape as the likelihood of a − 1 successes and b − 1 failures. That\'s why it pairs so well with yes/no data.',
  't_chi_f':
      'Chi-square: each Z² averages 1, so a sum of df of them averages df. t: if you knew σ, (x̄ − μ)/(σ/√n) would be exactly normal. Using the sample\'s s instead adds randomness to the bottom of the fraction. When s happens to come out small, the statistic is inflated, and that fattens the tails. With more data s ≈ σ, and t becomes normal. F is a ratio of two chi-squares, each divided by its df. Both are near 1 when nothing is going on, so F is near 1.',
  'joint_marginal':
      'By the multiplication rule, P(X = x, Y = y) = P(X = x) × P(Y = y | X = x) = 1/6 × C(x, y)/2^x, since Y given x coins is binomial. For the marginal of Y, the cells (X = 1, Y = y) … (X = 6, Y = y) don\'t overlap and together make up \'Y = y\', so you add down the column (total probability). The whole grid adds up to 1. For example, P(X = 4, Y = 2) = 1/6 × 6/16 = 0.0625.',
  'covariance':
      '(x − x̄)(y − ȳ) is literally the signed area of the rectangle from the averages\' cross to the dot. Dots in the top-right and bottom-left give positive areas; the other two corners give negative ones. Their average is the covariance (using n − 1 for the same reason as the sample variance). The units are hours × marks, so switching hours to minutes multiplies the covariance by 60 even though nothing real has changed.',
  'correlation':
      'Change units by multiplying x by c, and both cov(x, y) and sₓ get multiplied by c, so the c\'s cancel in r. In fact r is just the covariance of the z-scores. The Cauchy–Schwarz inequality keeps r between −1 and +1, and it only hits ±1 when every point is on a line. In a U-shape, the positive rectangles on one side cancel the negative ones on the other, so r ≈ 0 even though y depends perfectly on x.',
  'correlation_causation':
      'Inside a narrow temperature band, temperature is almost constant, so it can no longer push ice cream and swimming up together. Whatever link remains would have to come from somewhere else, and here almost none does. Experiments go further. Randomly assigning who gets a treatment makes the groups alike, on average, in everything else, measured or not. So any difference that appears has to be caused by the treatment.',
  'clt_dice':
      'The sum of n independent dice has variance nσ² (variances add). The average is the sum ÷ n, which divides the variance by n², leaving σ²/n and an sd of σ/√n. For a die, σ = √(35/12) ≈ 1.71. The bell shape appears because there are vastly more ways to make an average near 3.5 than an extreme one, just like on the Galton board. Adding independent pieces smooths almost any starting shape towards the normal curve.',
  'chebyshev':
      'Every value more than kσ from the mean adds at least (kσ)² to the variance\'s sum of squared distances. If a fraction q of the values are that far out, the variance is at least q·k²σ², and it equals σ², so q ≤ 1/k². That means at least 1 − 1/k² are within kσ. The proof only uses the definition of variance, which is why it works for any shape.',
  'population_sample':
      'In a simple random sample everyone is equally likely to be picked, so each person in it says \'yes\' with chance p. The sample share p̂ is an average of n such 0/1 answers. Its expected value is exactly p (it\'s unbiased), and it typically misses by √(p(1 − p)/n). The parameter p is fixed; p̂ changes with every sample. Surprisingly, the size of the population hardly matters. What matters is n.',
  'sampling_methods':
      'Estimates wobble because each sample mixes people differently. Stratifying fixes how many come from each neighbourhood, so differences between neighbourhoods can\'t cause wobble; only the randomness within each group is left. Cluster sampling picks whole blocks of people who think alike, which is like having far fewer independent opinions, so the estimate swings with which blocks get chosen. Systematic sampling behaves like random sampling unless the list has a repeating pattern.',
  'sampling_bias':
      'Error = bias + random noise. Random noise shrinks like 1/√n, but bias doesn\'t depend on n at all: every extra mall shopper comes from the same lopsided group. A huge biased sample gives a very precise wrong answer. In 1936 the Literary Digest poll had 2.4 million replies, mostly from car and telephone owners, and still predicted the wrong winner of the US election.',
  'sampling_distributions':
      'The sample is random, so anything you compute from it is a random variable with its own distribution. For the mean, linearity gives E[x̄] = μ, and adding variances gives an sd of σ/√n. The Central Limit Theorem makes it bell-shaped even when the population is skewed. The maximum of n values is always at least as big as a typical value, so its distribution sits higher and leans towards the top.',
  'standard_error':
      'Var(x̄) = Var(sum) ÷ n² = nσ² ÷ n² = σ²/n, so SE = σ/√n. Averaging cancels people\'s random ups and downs, but only partly: they don\'t line up perfectly, so the cancelling happens at the √n rate, not the n rate. In real studies σ is unknown, so you plug in the sample\'s s: SE ≈ s/√n.',
  'point_estimates':
      'The sample mean x̄ is the single point that makes Σ(x − point)² as small as possible. So Σ(x − x̄)² is always a little smaller than Σ(x − μ)² measured from the true mean. Exactly: Σ(x − μ)² = Σ(x − x̄)² + n(x̄ − μ)², and the last term averages σ². So on average Σ(x − x̄)² = (n − 1)σ², and dividing by n − 1 lands right on σ². We say one degree of freedom was used up estimating the mean.',
  'mle':
      'The likelihood is L(p) = p^h (1 − p)^t. Taking logs turns the product into a sum with the same peak: h·ln p + t·ln(1 − p). Its slope is h/p − t/(1 − p), which is zero at p = h/(h + t): heads ÷ flips. With more flips, the likelihood of values away from the peak drops off exponentially faster, so the curve narrows.',
  'confidence_intervals':
      'x̄ is normal around μ with sd σ/√n, so 95% of the time |x̄ − μ| < 1.96σ/√n. That inequality reads the same both ways: μ is within 1.96σ/√n of x̄. So the recipe \'x̄ ± 1.96σ/√n\' catches μ in 95% of samples. Once a particular interval has been computed it either contains μ or it doesn\'t; the 95% belongs to the recipe.',
  'margin_of_error':
      'A poll share p̂ is an average of n yes/no answers, so its sd is √(p(1 − p)/n), and the margin is 1.96 × that. p(1 − p) is largest at p = 0.5, where it\'s 0.25. That gives a worst-case margin of 1.96 × √(0.25/n) ≈ 1/√n: about ±3 points for n = 1,000. In a two-way race, the lead (A − B) has a margin about twice as big.',
  'sample_size':
      'Start from the margin, E = z√(p(1 − p)/n), and solve for n: n = z²·p(1 − p)/E². With the worst case p = 0.5 that\'s (z × 0.5 / E)². Because n grows with 1/E², halving the margin quadruples the sample. The population size doesn\'t even appear, unless you\'re sampling a big chunk of it. For ±1 point at 95%: (1.96 × 0.5 / 0.01)² = 9,604.',
  'null_alternative':
      'If the coin is fair, we know exactly what to expect: heads in 20 flips is Binomial(20, ½). \'Biased\' covers infinitely many possible values of p, so there\'s no single prediction to check against. So we assume H₀ and pick outcomes that would be rare under it. P(≤ 5 or ≥ 15 heads | fair) = 2 × 0.0207 ≈ 0.041. That is the chance of a false alarm, α.',
  'p_values':
      'If H₀ is true, the chance of getting p ≤ 0.05 is 5%, because that\'s what the p-value measures: being among H₀\'s most extreme 5% of results. The same holds for every cut-off c: P(p ≤ c) = c. That\'s exactly an even (uniform) spread. With a real effect, extreme results happen more often, so p-values pile up near 0. To get P(H₀ is true | data) you\'d need Bayes\' theorem and a prior. The p-value doesn\'t give it.',
  'type_errors':
      'The cut-off splits both bells. α is the area of H₀\'s bell beyond the cut-off; β is the area of H₁\'s bell on the near side of it. Moving the cut-off shrinks one area and grows the other, so you can\'t win both with the cut-off alone. To shrink both, pull the bells apart (a bigger effect) or make them narrower (more data, since their width is σ/√n).',
  'power':
      'The test rejects when z > 1.645 (one-sided, α = 0.05). If the true effect is d standard deviations, the sample mean shifts by d·σ, so z is centred at d√n instead of 0. P(reject) = P(Z + d√n > 1.645) = 1 − Φ(1.645 − d√n). Increasing d or n pushes this towards 1. For 80% power you need d√n ≈ 2.49, so n ≈ (2.49/d)².',
  'z_test':
      'If the claim is true, x̄ is normal with mean 500 g and sd 10/√25 = 2 g. So z = (x̄ − 500)/2 is standard normal, and |z| > 1.96 happens only 5% of the time: that\'s the rejection rule. We can use z, not t, because the sd is known. If the real mean is 497 g, z is centred at −1.5, so the test rejects much more often.',
  't_tests':
      'Both groups\' sample sds estimate the same σ, so pooling them uses all 16 values: s_p² is the average of the two variances. The difference of two means has variance σ²/n + σ²/n = 2σ²/n, so its standard error is s_p√(2/n). There are 16 − 2 = 14 degrees of freedom, because two means were estimated. With df 14, the two-sided 5% cut-off is 2.145 instead of the normal 1.96.',
  'chi_square':
      'Each face count O wobbles around its expected count E with a variance close to E, so (O − E)/√E behaves roughly like a standard normal. Squaring and adding gives a chi-square. There are only 5 degrees of freedom because the six counts must add up to 60: once you know five, the sixth is fixed. 11.07 is the 95th percentile of χ² with 5 df.',
  'anova':
      'If all groups share one mean, the group averages differ only by chance, and their spread (scaled by group size) estimates σ². The scatter inside the groups estimates σ² whether or not H₀ is true. So under H₀ the two estimates agree and F ≈ 1. Real differences inflate only the between-group part, so F grows. Doing three separate 5% t-tests instead would give about 1 − 0.95³ ≈ 14% chance of at least one false alarm.',
  'line_of_best_fit':
      'For any slope, the best intercept makes the residuals average zero, and that puts the line through (x̄, ȳ). What\'s left is to minimise Σ(y − ȳ − b(x − x̄))² over b. That\'s a parabola in b, and setting its slope to zero gives b = Σ(x − x̄)(y − ȳ) / Σ(x − x̄)². This also equals r × s_y / s_x, so the fitted line and the correlation are closely tied.',
  'residuals':
      'Least squares guarantees the residuals average zero and have no straight-line link with x. So if a straight line is the right model, nothing systematic is left: just random scatter. If the truth is curved, the line is too high in the middle and too low at the ends (or the other way round), and the residuals trace a U. A funnel shape means the spread changes with x.',
  'r_squared':
      'For a least-squares line the total variation splits exactly in two: Σ(y − ȳ)² = Σ(ŷ − ȳ)² + Σ(y − ŷ)². That\'s explained plus left over; the cross term cancels. So R² = 1 − left over ÷ total = explained ÷ total. With a single x, ŷ − ȳ = b(x − x̄), and the algebra simplifies to exactly r².',
  'multiple_regression':
      'Bigger homes tend to have more bedrooms, so when size goes up, bedrooms usually go up too. The size-only slope therefore picks up both effects: the true size effect plus (bedroom effect × how many extra bedrooms come with extra size). This is called omitted-variable bias. Fitting both inputs together solves for each coefficient using only the part of that input the other one can\'t explain. That\'s what \'holding the others fixed\' means.',
  'logistic_regression':
      'The sigmoid 1/(1 + e^(−z)) squeezes any number z into (0, 1). Turn it around and ln(p/(1 − p)) = a + b·x: the line describes the log-odds, so each extra hour multiplies the odds of passing by e^b. There\'s no formula for the best fit, so we climb the log-likelihood step by step. Each point pulls with (y − p)·x: it pushes the curve up where a student passed but the predicted p was low.',
  'prior_posterior':
      'Bayes\' rule: posterior ∝ prior × likelihood. With h heads and t tails the likelihood is p^h (1 − p)^t. A Beta(a, b) prior is ∝ p^(a−1)(1 − p)^(b−1). Multiply them and you get p^(a+h−1)(1 − p)^(b+t−1): still a Beta, now Beta(a + h, b + t). So the prior acts like heads and tails you\'d already seen. The mean (a + h)/(a + b + h + t) is swamped by the data as h + t grows.',
  'updating_evidence':
      'Bayes\' rule in odds form: posterior odds = prior odds × (chance of this ball under A ÷ chance under B). Each red multiplies the odds for A by 0.7/0.3 = 7/3, and each blue divides them by 7/3. So only reds minus blues matters, and the order doesn\'t. As draws pile up that difference tends to grow, which pushes the belief towards 0% or 100%.',
  'bayes_vs_frequentist':
      'With a flat Beta(1, 1) prior, k clicks in n visits gives a Beta(1 + k, 1 + n − k) posterior. For large n its mean is close to p̂, its sd is close to √(p̂(1 − p̂)/n), and it\'s nearly normal. So the 95% credible interval ≈ p̂ ± 1.96√(p̂(1 − p̂)/n), the confidence interval. With 0 clicks in 10, p̂ = 0 gives a zero-width confidence interval, while the Beta(1, 11) posterior still allows small positive rates.',
  'ab_testing':
      'If the buttons are really the same, both share one click rate p̄. Then p̂_B − p̂_A has sd √(p̄(1 − p̄)(1/n_A + 1/n_B)), and dividing by it gives a z that\'s roughly standard normal. Peeking breaks this: every look is another roughly 5% chance of a false alarm. Check after every visitor and you get dozens of chances, so the chance of ever seeing p < 0.05 by luck is far above 5%.',
  'monte_carlo':
      'Each dart lands uniformly in the unit square, so its chance of landing inside the quarter circle equals that area, π/4. The count inside is binomial, and by the Law of Large Numbers the share heads to π/4. The error of 4 × share is about 4√(p(1 − p)/n) ≈ 1.64/√n. So 10,000 darts give π to about ±0.016, and each extra digit needs 100 times more darts.',
  'random_walks':
      'After n steps, the position is the sum of n independent steps of ±1, each with mean 0 and variance 1. Variances add, so the position has variance n, and its root-mean-square distance from the start is √n. The same holds in 2D: the squared distance adds 1 per unit step on average, so it\'s again √n. Spreading like √n, not n, is the signature of diffusion.',
  'markov_chains':
      'If today\'s chances of each state are π, tomorrow\'s are πP. A stationary distribution is one that stays put: π = πP. When every state can reach every other and nothing forces a fixed rhythm, each step blends the rows of P together. The differences caused by where you started shrink away, so the chain converges to that π. The long-run share of days in each state then equals π.',
  'ai_ml':
      'e^score is always positive and keeps the order of the scores. Dividing by the sum makes the results add up to 1, so they\'re valid probabilities. Dividing the scores by T first controls the gaps: T < 1 stretches them so the top word dominates, and T > 1 squeezes them so the odds become more even. A word that scores 1 point higher is e^(1/T) times as likely.',
  'simpsons':
      'Each treatment\'s overall rate is an average of its small-stone and large-stone rates, weighted by how many patients of each kind it got. A got mostly large stones (263 of 350), where success is lower, so its overall rate is pulled towards 73%. B got mostly small stones (270 of 350), so it\'s pulled towards 87%. It\'s the mix of cases that flips the comparison, not the treatments. Compare within groups, or randomise who gets what.',
  'gamblers_fallacy':
      'The spins are independent: P(red | any history) = P(red). The wheel has no idea what happened before. \'Evening out\' is just dilution. After 26 extra blacks, the next 1,000 spins come out about 500–500, so black\'s share is about 526/1,026 ≈ 51%. The extra 26 never get cancelled; they just matter less and less.',
  'st_petersburg':
      'E = Σ (½)^k × 2^k = 1 + 1 + 1 + … over every possible k, which is infinite. But in N games the biggest prize you\'ll typically see is only about N, so the average prize grows like log₂N: roughly ₹10 after 1,000 games. And no real banker can pay out 2⁴⁰ rupees. Cap the prize at the bank\'s wealth W and the game is worth only about log₂W + 1: even a ₹1 trillion bank makes it worth about ₹41.',
};
