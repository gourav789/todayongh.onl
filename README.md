# Today On General Hospital

Facebook jaisa design wali static website — General Hospital ke daily **Spoilers, Recaps aur News** ke liye. GitHub Pages par deploy hone ke liye ready hai.

Domain: **https://todayongh.online**

---

## Files ka matlab (folder structure)

```
index.html            -> Home page (mixed feed)
spoilers.html         -> Spoiler category page (menu me)
recaps.html           -> Recap category page (menu me)
news.html             -> News category page (menu me)
about.html            -> About Us (300 words)
contact.html          -> Contact (email: gsrseo81@gmail.com)
privacy-policy.html   -> Privacy Policy (700 words)
disclaimer.html       -> Disclaimer (700 words)
404.html              -> Page not found
sitemap.xml           -> Search Console ke liye
robots.txt            -> Search engines ke liye
CNAME                 -> Custom domain (todayongh.online)
.nojekyll             -> GitHub Pages ke liye zaroori
assets/css/style.css  -> Puri design/styling
assets/js/main.js     -> Mobile menu + chhote features
assets/img/           -> Images (placeholder + favicon)
```

Design **mobile aur PC dono par** apne aap fit ho jaata hai. Baar baar kuch karne ki zaroorat nahi.

---

## GitHub Pages par kaise deploy karein

1. GitHub par ek **naya repository** banao (public).
2. Is folder ke saare files repo me upload/push karo.
3. Repo me jao: **Settings > Pages**.
4. "Source" me **Deploy from a branch** choose karo, branch `main` aur folder `/ (root)` select karo, Save.
5. Custom domain ke liye `todayongh.online` daalo (CNAME file already ready hai).
6. Apne domain provider (jaha se domain liya) par DNS me ye records add karo:
   - `A` record -> `185.199.108.153`
   - `A` record -> `185.199.109.153`
   - `A` record -> `185.199.110.153`
   - `A` record -> `185.199.111.153`
   - `CNAME` record `www` -> `<your-github-username>.github.io`
7. GitHub Pages me **Enforce HTTPS** on kar do.

Kuch minute me site live ho jayegi.

---

## Naya daily post kaise dalein (bahut aasaan)

1. Kisi maujuda post file ko **copy** karo aur naya naam do,
   jaise `spoiler-2026-07-21.html`.
2. Us file me ye cheezein badlo:
   - `<title>` aur `<meta name="description">`
   - `<link rel="canonical">` me nayi file ka URL
   - `og:title`, `og:description`, `og:url`, `og:image`
   - `<h1>` heading aur andar ke paragraphs
   - Photos (niche padho)
3. Phir us post ka link `spoilers.html` / `recaps.html` / `news.html` ke feed me
   aur home `index.html` me add kar do (ek `post-card` block copy karke).
4. `sitemap.xml` me naye post ka `<url>` add kar do (SEO ke liye achha).

---

## Images kaise handle karein (har post me bahut saari photos)

- Apni images `assets/img/` folder me daalo (jaise `2026-07-21-1.jpg`, `-2.jpg`...).
- Post ke andar **gallery** me use karo:

```html
<div class="gallery">
  <img src="assets/img/2026-07-21-1.jpg" alt="General Hospital spoiler photo" />
  <img src="assets/img/2026-07-21-2.jpg" alt="GH scene" />
  <img src="assets/img/2026-07-21-3.jpg" alt="Port Charles moment" />
  <!-- jitni chahe utni img daalo, layout apne aap adjust ho jayega -->
</div>
```

Tips:
- Har image me **alt="..."** zaroor likho (SEO + accessibility ke liye).
- Images ko upload se pehle compress karo (tinypng.com jaisa tool), site fast rahegi.
- `loading="lazy"` apne aap lag jaata hai, isliye zyada photos hone par bhi page slow nahi hoga.
- Achhi width: 1200px ke aas paas, format JPG ya WebP.

---

## Google Search Console me kaise dalein

1. https://search.google.com/search-console par jao.
2. Property add karo: `https://todayongh.online`.
3. Ownership verify karo (HTML tag method sabse easy — jo tag mile use
   har page ke `<head>` me daal do, ya DNS method use karo).
4. **Sitemaps** section me jao aur `sitemap.xml` submit karo.
5. Ho gaya — Google aapki site crawl karna shuru kar dega.

---

## Facebook se traffic

- Har page/post me "Share on Facebook" aur "Follow" buttons already lage hain.
- FB page: https://www.facebook.com/todayongeneralhospitalabc
- Naya post publish karke uska link apni FB page par share karo — traffic site par aayega.

---

## Note

Ye ek **fan site** hai, ABC ya official General Hospital se koi affiliation nahi hai.
Disclaimer aur Privacy Policy pages me ye clearly likha hua hai (AdSense/legal ke liye zaroori).
