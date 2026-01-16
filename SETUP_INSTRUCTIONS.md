# Setup Instructions for open-source-lab-resources

Follow these steps to push this repository to GitHub.

---

## Step 1: Create the Repository on GitHub

### Option A: Using GitHub Website (Easiest)

1. Go to https://github.com/new
2. Fill in:
   - **Repository name:** `open-source-lab-resources`
   - **Description:** `Open-source tools and templates for modern laboratories - by Next Step Solutions`
   - **Visibility:** ✅ Public
   - **DO NOT initialize with:**
     - ❌ README (we already have one)
     - ❌ .gitignore (we already have one)
     - ❌ license (we already have MIT license)
3. Click **"Create repository"**

### Option B: Using GitHub CLI (if installed)

```bash
gh repo create open-source-lab-resources --public --description "Open-source tools and templates for modern laboratories - by Next Step Solutions"
```

---

## Step 2: Push to GitHub

After creating the repo, run these commands:

```bash
cd /tmp/open-source-lab-resources

# Add the GitHub remote (replace 'tdoerks' with your username if different)
git remote add origin https://github.com/tdoerks/open-source-lab-resources.git

# Push to GitHub
git push -u origin main
```

**If you need authentication:**

Use your GitHub token:
```bash
git push https://tdoerks:YOUR_GITHUB_TOKEN@github.com/tdoerks/open-source-lab-resources.git main
```

---

## Step 3: Verify

1. Go to https://github.com/tdoerks/open-source-lab-resources
2. You should see:
   - ✅ README with Next Step Solutions branding
   - ✅ MIT License
   - ✅ freezer-defrost/ folder
   - ✅ All files present

---

## Step 4: Optional - Enable GitHub Pages

To host the interactive sign online:

1. Go to repository **Settings** → **Pages**
2. Under **Source**, select: **Deploy from a branch**
3. Branch: **main** / folder: **/ (root)**
4. Click **Save**
5. Wait a few minutes
6. Visit: `https://tdoerks.github.io/open-source-lab-resources/freezer-defrost/Freezer_Defrosting_Sign_Interactive.html`

Now people can use the sign directly from the web!

---

## Step 5: Add Topics/Tags (Recommended)

1. Go to your repo on GitHub
2. Click the ⚙️ gear icon next to "About"
3. Add topics:
   - `laboratory`
   - `lab-management`
   - `open-source`
   - `sop`
   - `templates`
   - `laboratory-tools`
   - `freezer-maintenance`
   - `lab-operations`
4. Save

This helps people find your repo!

---

## Step 6: Share It!

- Tweet about it
- Share on LinkedIn
- Post in lab manager groups
- Tell colleagues
- Add to your consulting website

---

## Future Updates

To add new resources later:

```bash
cd /tmp/open-source-lab-resources

# Make changes, add new folders, etc.

git add .
git commit -m "Add new resource: [name]"
git push
```

---

## Transferring to Organization Later

When you create the "Next Step Solutions" organization:

1. Go to repo **Settings** → **Danger Zone** → **Transfer ownership**
2. Type: `next-step-solutions`
3. Confirm transfer
4. URL becomes: `github.com/next-step-solutions/open-source-lab-resources`
5. Old URL redirects automatically!

---

## Need Help?

Contact: Tyler Doerksen
GitHub: [@tdoerks](https://github.com/tdoerks)

---

**You're all set!** 🚀
