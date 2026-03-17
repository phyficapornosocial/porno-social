# Custom Domain Deployment Checklist

Use this checklist after code is merged to ensure domain, auth, email, and SSL are fully live.

## Step 5: Firebase Auth Authorized Domains

- [ ] Open Firebase Console -> Authentication -> Settings
- [ ] In Authorized domains, add `porno-social.com`
- [ ] In Authorized domains, add `www.porno-social.com`
- [ ] Save and confirm both domains are listed

## Step 11: Email Domain Setup (Optional but Recommended)

### Namecheap forwarding

- [ ] Open Namecheap -> Domain List -> Manage -> Email Forwarding
- [ ] Create forwarding for `support@porno-social.com` -> team inbox
- [ ] Create forwarding for `dmca@porno-social.com` -> team inbox
- [ ] Create forwarding for `privacy@porno-social.com` -> team inbox
- [ ] Create forwarding for `noreply@porno-social.com` -> team inbox

### Firebase Auth sender domain

- [ ] Open Firebase Console -> Authentication -> Templates
- [ ] Edit Email address verification template
- [ ] Click Customize domain and enter `porno-social.com`
- [ ] Add Firebase-provided DNS records in Namecheap
- [ ] Wait for verification completion in Firebase Console

## Step 12: Verification Commands

Run after DNS updates propagate:

```bash
# 1) DNS
nslookup porno-social.com

# 2) SSL / headers
curl -I https://www.porno-social.com

# 3) Build + deploy
flutter build web --release
firebase deploy --only hosting
```

Expected checks:

- [ ] `nslookup` resolves to Firebase Hosting records
- [ ] `curl -I` returns success with valid TLS and Firebase headers
- [ ] `https://www.porno-social.com` loads latest production build
- [ ] Bare domain redirects to `https://www.porno-social.com`
- [ ] Auth flows and email templates use the custom domain

## Troubleshooting

- SSL appears invalid right after setup: wait up to 24 hours for certificate provisioning.
- Domain already in use: remove conflicting A/AAAA/CNAME records, then re-add Firebase records.
- Auth domain mismatch: verify both `porno-social.com` and `www.porno-social.com` are in Authorized domains.

## Local Guard Commands

- Linux/macOS/CI: `bash scripts/check_domain_literals.sh`
- Windows PowerShell: `pwsh -File scripts/check_domain_literals.ps1`
