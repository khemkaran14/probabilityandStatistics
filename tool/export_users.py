"""Export Chance users to a CSV file, for the app owner only.

By default only users who ticked "Send me offers and updates" are exported,
because only they agreed to be contacted. Use --all for every user (for
support or analysis, not for marketing).

Setup (once, on your Mac):
  1. Firebase console → Project settings → Service accounts →
     "Generate new private key". Save the JSON file somewhere safe and never
     commit it or share it: it gives full access to your project.
  2. pip3 install firebase-admin

Usage:
  python3 tool/export_users.py --key ~/chance-service-account.json
  python3 tool/export_users.py --key ~/chance-service-account.json --all --out all-users.csv
"""
import argparse
import csv
import sys

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    sys.exit("Install the Firebase Admin SDK first: pip3 install firebase-admin")

FIELDS = ["uid", "name", "email", "phone", "marketing_opt_in", "consent_at", "photo_url", "xp", "lessons_done", "updated_at"]


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--key", required=True, help="path to the service-account JSON file")
    parser.add_argument("--out", default="chance-users.csv", help="CSV file to write (default: chance-users.csv)")
    parser.add_argument("--all", action="store_true", help="include users who did not opt in to offers")
    args = parser.parse_args()

    firebase_admin.initialize_app(credentials.Certificate(args.key))
    db = firestore.client()

    rows = []
    for doc in db.collection("users").stream():
        data = doc.to_dict() or {}
        profile = data.get("profile") or {}
        progress = data.get("progress") or {}
        opted_in = profile.get("marketingOptIn") is True
        if not opted_in and not args.all:
            continue
        completed = [x for x in (progress.get("completed") or "").split(",") if x]
        updated = data.get("updatedAt")
        rows.append({
            "uid": doc.id,
            "name": profile.get("name", ""),
            "email": profile.get("email", ""),
            "phone": profile.get("phone", ""),
            "marketing_opt_in": "yes" if opted_in else "no",
            "consent_at": profile.get("consentAt", ""),
            "photo_url": profile.get("photoUrl", ""),
            "xp": progress.get("xp", ""),
            "lessons_done": len(completed),
            "updated_at": updated.isoformat() if hasattr(updated, "isoformat") else "",
        })

    with open(args.out, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=FIELDS)
        writer.writeheader()
        writer.writerows(rows)
    who = "users" if args.all else "users who agreed to offers"
    print(f"Wrote {len(rows)} {who} to {args.out}")


if __name__ == "__main__":
    main()
