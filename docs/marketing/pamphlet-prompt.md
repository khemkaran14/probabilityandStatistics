# Pamphlet prompt for ChatGPT / Gemini

Copy everything inside the box below into ChatGPT (with image generation)
or Gemini. Attach these files from the repo so the tool can use the real app
look: `docs/store/icon-512.png` and 3–4 screenshots from
`docs/store/screenshots/` (best: 2-galton-board, 3-monty-hall, 4-bayes,
7-quiz).

```
You are a professional graphic designer. Design a DOUBLE-SIDED promotional
pamphlet (front and back) for a mobile learning app, to be printed and
handed out in schools and colleges in India.

== PRINT SPECS ==
- Size: A5 portrait (148 × 210 mm), 3 mm bleed on all sides, 300 DPI.
- Two separate images: FRONT and BACK, same size, same style.
- Keep all text at least 6 mm inside the edges (safe zone).
- High contrast and large text: it must be readable when photocopied too.

== THE APP ==
- Name: Chance: Probability & Stats
- Publisher: Divyrs (do NOT show any personal names)
- What it is: an Android app that teaches probability and statistics with
  short animated lessons you can play with. 90 lessons, 17 chapters.
- Audience: Class 11–12 students, college and university students
  (B.Sc., B.Com., BBA, engineering, data science), and teachers.
- Platform: Android, on Google Play.
- Price model: free to start (chapters 1–3 and 3 preview lessons free);
  one-time purchase unlocks everything. No ads, no subscription.

== BRAND LOOK ==
- Style: bright, friendly, modern, playful but clean. Flat illustration,
  rounded shapes, soft shadows. Think Duolingo-meets-Khan-Academy, not a
  corporate brochure.
- Colours (use these exact hex values):
  Pink #FF3D8B (main accent, buttons, highlights)
  Violet #9B5CFF (secondary accent)
  Yellow #FFC93C (small highlights, the "ball")
  Green #2BC46F, Cyan #14C3D0, Blue #4C7DFF (small accents only)
  Cream background #FFF9F2, dark ink text #1E1B3A
- App icon: five white rounded bars shaped like a bell curve, with a
  yellow ball above the middle bar, on a pink-to-violet diagonal gradient
  (use the attached icon if provided).
- Fonts: a rounded, bold sans-serif for headings (like Poppins, Nunito or
  Inter Display Bold); a clean sans-serif for body text.

== FRONT SIDE (the hook) ==
Background: cream (#FFF9F2) with a large soft pink-to-violet gradient
shape sweeping across the top third. Light, faint maths doodles in the
background at about 8% opacity: dice, coins, a bell curve, a Venn diagram,
a scatter plot, a tree diagram.

Layout, top to bottom:
1. Top-left: small app icon + "Chance" wordmark.
2. Big headline (2 lines, very bold, ink colour, key words in pink):
   "Stop memorising formulas.
    Watch them work."
3. Sub-headline (1 line):
   "Probability & statistics, animated — 90 lessons you can play with."
4. Hero image: a modern Android phone mockup, slightly tilted, showing the
   app screen (use the attached Galton board screenshot: balls falling
   through pegs into a bell-shaped histogram). Around the phone, floating
   illustrated elements: a die, a coin, three doors (Monty Hall), a small
   bell curve.
5. Three short feature pills in a row (rounded, coloured backgrounds):
   "▶ Watch it" (pink)  "🎛 Play with it" (violet)  "✅ Quiz yourself" (green)
6. Bottom band (pink-to-violet gradient, white text):
   "FREE on Google Play" + the official "Get it on Google Play" badge
   + a QR code placeholder box labelled "Scan to download".

== BACK SIDE (the details) ==
Background: plain cream (#FFF9F2), very subtle dotted grid; one small
gradient corner shape top-right to match the front.

Layout, top to bottom:
1. Heading: "Why students love Chance" (pink underline accent).
2. Four feature cards in a 2 × 2 grid, each with a simple flat icon:
   - "See the why" — Every formula comes with a live animation and a
     'Why does this work?' explanation.
   - "Learn by playing" — Tilt the odds, add data, change the sample size
     and watch the result change.
   - "2 minutes a day" — Daily goal, streaks, XP, badges and a daily
     reminder keep you going.
   - "Exam-ready practice" — A 3-question quiz after every lesson plus a
     daily challenge.
3. Section: "17 chapters, from basics to AI" — show as small coloured
   chips/tags in a flowing wrap:
   Averages & spread · Charts · Probability basics · Counting ·
   Conditional probability & Bayes · Random variables · Binomial & Poisson
   · Normal distribution · Correlation · Central Limit Theorem · Sampling ·
   Confidence intervals · Hypothesis testing · Regression · Bayesian
   thinking · A/B testing & AI · Paradoxes (Monty Hall, Simpson's)
4. A strip of 3 small phone screenshots side by side (use the attached
   Monty Hall, Bayes test and quiz screenshots), each with a one-line
   caption: "Should you switch doors?", "Tested positive — are you really
   sick?", "Check yourself in 3 questions".
5. "Perfect for" line with small icons:
   Class 11–12 · College & university · Data science beginners · Teachers
6. Bottom call-to-action box (pink-to-violet gradient, white text):
   "Start free today" — "Chapters 1–3 free · No ads · One-time unlock"
   + QR code placeholder + "Search 'Chance Probability' on Google Play".
7. Tiny footer: "© Divyrs · divyrs.com" (no personal names, no phone
   numbers).

== RULES ==
- Spell every word exactly as given; do not invent features, prices,
  ratings, download counts, awards or testimonials.
- Do not use real logos of schools, exam boards or brands other than the
  official Google Play badge.
- Leave the QR code as a clearly marked empty square placeholder
  (I will insert the real QR code).
- Output: FRONT and BACK as two separate high-resolution images, then
  list the exact text you used for each side so I can recreate it in
  Canva if any letters come out wrong.
```

## Tips

- **Text in AI images often comes out misspelled.** If that happens, ask:
  "Generate the same design again WITHOUT any text, keeping empty spaces for
  headings, cards and the QR code." Then add the text yourself in Canva
  (free) using the text list from the answer.
- **QR code:** make it for
  `https://play.google.com/store/apps/details?id=com.divyrs.chance`
  (free at qr-code-generator.com or in Canva → Apps → QR code). It works
  only once the app is live in Production; until then it shows "not found".
- **Google Play badge:** download the official one from
  <https://play.google.com/intl/en_us/badges/> (allowed on print).
- **Printing:** export as PDF (print) with bleed, CMYK if the printer asks.
  A5 on 130–170 gsm glossy or matte paper works well for hand-outs.
- **Hindi version:** add to the prompt: "Make a second version with all
  text in Hindi (Devanagari), keeping the app name 'Chance' in English."
