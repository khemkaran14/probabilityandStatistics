# LiveLifeTricks – Income Tax & EMI Calculators

A fast, static website for **livelifetricks.com** with:

- **Income Tax Calculator** (`/income-tax-calculator/`): new vs old regime for FY 2026-27 and FY 2025-26, with HRA (including the new 8-city list), 80C, 80D, NPS, home loan interest, 87A rebate, marginal relief, surcharge and cess. It shows which regime is cheaper and how many extra deductions the old regime would need to match.
- **EMI Calculator** (`/emi-calculator/`): home, car, personal and education loans, with a year-by-year schedule you can expand month by month, extra-payment savings, a CSV download and a shareable link.
- Home, About, Contact, Privacy policy, Disclaimer and 404 pages (needed for AdSense approval), plus an automatic `sitemap.xml` and `robots.txt`, SEO tags, FAQ structured data and dark mode.

There is no database and no server code. The site is plain HTML, CSS and JS, so it loads quickly and is cheap to host alongside your other sites.

## Folder layout

```
livelifetricks/
├── src/
│   ├── layout.html        shared header, footer and SEO tags
│   ├── pages/             one file per page (meta block at the top)
│   ├── assets/css, js     styles and calculator code
│   └── static/            favicon, share image, manifest
├── tests/                 checks the tax and EMI maths
├── deploy/                nginx config and deploy script
├── build.js               builds everything into dist/
└── site.config.json       site URL, email, Google Analytics / AdSense IDs
```

## Everyday commands (needs Node.js 18+)

```bash
cd livelifetricks
npm test          # check the calculations
npm run build     # build the site into dist/
npm run serve     # build and preview at http://localhost:8080
```

**To add a page**, copy `src/pages/about.html`, change the meta block (`title`, `description`, `path`) and the content, then run `npm run build`. It's added to the sitemap automatically.

**To turn on Google Analytics or AdSense**, put your IDs in `site.config.json` (`ga4Id`, for example `G-XXXXXXX`, and `adsenseClient`, for example `ca-pub-123...`) and rebuild.

---

## Hosting on your Hostinger VPS

This assumes your VPS runs Ubuntu with **nginx**, which is the most common setup. If you use a panel such as CloudPanel, aaPanel, Coolify or Hestia, see the note at the end.

### Step 1 – Back up the old site (important)

Before you switch anything, back up the current livelifetricks.com (files plus database if it's WordPress). Note any old pages that get visits in Google Search Console, because you'll redirect them in Step 6.

### Step 2 – Point the domain to the VPS

In your domain's DNS settings (in Hostinger: **Domains → DNS / Nameservers**):

| Type  | Name | Value              |
|-------|------|--------------------|
| A     | @    | your VPS IP address |
| CNAME | www  | livelifetricks.com |

DNS changes can take anywhere from a few minutes to a few hours.

### Step 3 – Set up the site on the VPS (one time)

SSH into the VPS (`ssh root@YOUR_VPS_IP`), then:

```bash
# Check which web server you already run. Your other sites use it too.
systemctl is-active nginx apache2

# Create the folder for the site
mkdir -p /var/www/livelifetricks.com

# Add the nginx config. Copy the contents of deploy/nginx-livelifetricks.conf into this file:
nano /etc/nginx/sites-available/livelifetricks.com
ln -s /etc/nginx/sites-available/livelifetricks.com /etc/nginx/sites-enabled/

# Test before reloading, so your other sites aren't affected by a typo
nginx -t && systemctl reload nginx

# Free HTTPS certificate
apt install -y certbot python3-certbot-nginx   # skip if already installed
certbot --nginx -d livelifetricks.com -d www.livelifetricks.com
```

If `/etc/nginx/sites-available` doesn't exist on your server, put the file in `/etc/nginx/conf.d/livelifetricks.com.conf` instead and skip the `ln -s` line.

### Step 4 – Upload the site

**Option A, from your computer** (needs `rsync` and SSH access):

```bash
cd livelifetricks
VPS_HOST=YOUR_VPS_IP ./deploy/deploy.sh
```

This runs the tests, builds the site and uploads it. Run it again whenever you change something.

**Option B, build on the VPS** (needs Node.js and git on the VPS):

```bash
cd /opt && git clone <this-repo-url> llt && cd llt/livelifetricks
git checkout <branch>
node build.js && rsync -a --delete dist/ /var/www/livelifetricks.com/
# Later updates:
git pull && node build.js && rsync -a --delete dist/ /var/www/livelifetricks.com/
```

### Step 5 – Check it

- Open https://livelifetricks.com, https://livelifetricks.com/income-tax-calculator/ and https://livelifetricks.com/emi-calculator/
- Check that http:// and www. both redirect to https://livelifetricks.com
- Run the homepage through https://pagespeed.web.dev (aim for 90+ on mobile)

### Step 6 – Tell Google

1. In **Google Search Console**, add or verify livelifetricks.com and submit `https://livelifetricks.com/sitemap.xml`.
2. Use **URL Inspection → Request indexing** for the two calculator pages.
3. If old pages had traffic or backlinks, redirect them to the closest new page by adding lines like these inside the `server { }` block, then run `nginx -t && systemctl reload nginx`:

```nginx
location = /old-post-name/ { return 301 /income-tax-calculator/; }
```

### Using a panel or Apache instead

- **CloudPanel / aaPanel / Hestia / Hostinger panel:** create a new "static site" for livelifetricks.com, turn on its free SSL, and upload the contents of `dist/` to the site's document root (with the panel's file manager, SFTP, or `deploy.sh` using `REMOTE_DIR=/path/to/docroot`).
- **Apache:** use a normal `<VirtualHost>` with `DocumentRoot /var/www/livelifetricks.com` and `ErrorDocument 404 /404.html`. Clean URLs work without extra rules because every page is a folder with an `index.html`.

---

## Keeping the tax calculator accurate

Tax rules live in one file: `src/assets/js/tax-engine.js`.

- **Slabs and rates:** `NEW_SLABS`, `oldSlabs()` and `SURCHARGE`
- **Year list and HRA metro cities:** `YEARS`
- **Rebate, standard deduction and deduction limits:** inside `compute()`

After every Union Budget (1 February), check the rules, add the new year to `YEARS`, update the tests in `tests/engines.test.js`, then run `npm test` before deploying.
