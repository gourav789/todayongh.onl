$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

# Root site folder (parent of _tools)
$script:Root = Split-Path -Parent $PSScriptRoot
if (-not $script:Root) { $script:Root = (Get-Item ..).FullName }

$script:WatermarkText = 'Today On General Hospital'
$script:FollowUrl = 'https://www.facebook.com/todayongeneralhospitalabc'

# Collected metadata for building listing pages
$script:PostIndex = @()

function Get-CleanUrl($url) {
    # strip query string (e.g. ?resize=1024%2C598) for the actual download
    return ($url -split '\?')[0]
}

function Add-Watermark($path) {
    $img = [System.Drawing.Image]::FromFile($path)
    try {
        $bmp = New-Object System.Drawing.Bitmap($img.Width, $img.Height)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.SmoothingMode = 'AntiAlias'
        $g.InterpolationMode = 'HighQualityBicubic'
        $g.DrawImage($img, 0, 0, $img.Width, $img.Height)

        $w = $img.Width
        $h = $img.Height
        $barH = [int]([Math]::Max(28, $h * 0.09))
        $fontSize = [int]($barH * 0.42)
        if ($fontSize -lt 12) { $fontSize = 12 }

        # semi-transparent bar at bottom
        $barBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(120, 0, 0, 0))
        $g.FillRectangle($barBrush, 0, ($h - $barH), $w, $barH)

        $font = New-Object System.Drawing.Font('Arial', $fontSize, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
        $sf = New-Object System.Drawing.StringFormat
        $sf.Alignment = 'Center'
        $sf.LineAlignment = 'Center'
        $rect = New-Object System.Drawing.RectangleF(0, ($h - $barH), $w, $barH)

        # subtle shadow then white text
        $shadow = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(160, 0, 0, 0))
        $white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(235, 255, 255, 255))
        $rectShadow = New-Object System.Drawing.RectangleF(2, ($h - $barH + 2), $w, $barH)
        $g.DrawString($script:WatermarkText, $font, $shadow, $rectShadow, $sf)
        $g.DrawString($script:WatermarkText, $font, $white, $rect, $sf)

        $g.Dispose()
        $img.Dispose()

        # save as jpeg quality 88
        $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
        $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]88)
        $bmp.Save($path, $codec, $ep)
        $bmp.Dispose()
    } catch {
        $img.Dispose()
        throw
    }
}

function Fetch-Image($url, $destAbs) {
    if (Test-Path $destAbs) { return }  # idempotent
    $clean = Get-CleanUrl $url
    $tmp = [System.IO.Path]::GetTempFileName()
    Invoke-WebRequest -Uri $clean -OutFile $tmp -UseBasicParsing -TimeoutSec 60 -Headers @{ 'User-Agent' = 'Mozilla/5.0' }
    Copy-Item $tmp $destAbs -Force
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    Add-Watermark $destAbs
}

function HtmlEnc($s) {
    return ($s -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;')
}

function Render-Post($post) {
    $slug = $post.Slug
    $folderRel = "assets/img/posts/$slug"
    $folderAbs = Join-Path $script:Root ($folderRel -replace '/', '\')
    New-Item -ItemType Directory -Force -Path $folderAbs | Out-Null

    $imgCount = 0
    $firstImageRel = $null
    $bodyParts = @()

    foreach ($b in $post.Blocks) {
        if ($b.img) {
            $imgCount++
            $name = ('{0:D2}.jpg' -f $imgCount)
            $destAbs = Join-Path $folderAbs $name
            $rel = "$folderRel/$name"
            Write-Host ("  image {0}: {1}" -f $imgCount, (Get-CleanUrl $b.img))
            Fetch-Image $b.img $destAbs
            if (-not $firstImageRel) { $firstImageRel = $rel }
            $cap = HtmlEnc $b.cap
            $alt = HtmlEnc $b.alt
            $bodyParts += "      <figure class=`"post-figure`"><img src=`"../$rel`" alt=`"$alt`" /><figcaption>$cap</figcaption></figure>"
        } elseif ($b.h) {
            $bodyParts += ("      <h2>" + (HtmlEnc $b.h) + "</h2>")
        } else {
            $bodyParts += ("      <p>" + (HtmlEnc $b.t) + "</p>")
        }
    }

    if ($imgCount -gt 99) { throw ("Post $slug has $imgCount images (>99)") }

    $body = ($bodyParts -join "`r`n")
    $titleEnc = HtmlEnc $post.Title
    $dekEnc = HtmlEnc $post.Dek
    $url = "https://todayongh.onl/$slug.html"
    $ogImg = "https://todayongh.onl/$firstImageRel"

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>$titleEnc - Today On General Hospital</title>
  <meta name="description" content="$dekEnc" />
  <link rel="canonical" href="$url" />
  <meta name="robots" content="index, follow" />
  <meta property="og:type" content="article" />
  <meta property="og:title" content="$titleEnc" />
  <meta property="og:description" content="$dekEnc" />
  <meta property="og:url" content="$url" />
  <meta property="og:image" content="$ogImg" />
  <meta property="article:published_time" content="$($post.Date)" />
  <link rel="icon" href="assets/img/favicon.svg" />
  <link rel="stylesheet" href="assets/css/style.css" />
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "NewsArticle",
    "headline": "$titleEnc",
    "image": ["$ogImg"],
    "datePublished": "$($post.Date)",
    "author": { "@type": "Organization", "name": "Today On General Hospital" },
    "publisher": {
      "@type": "Organization",
      "name": "Today On General Hospital",
      "logo": { "@type": "ImageObject", "url": "https://todayongh.onl/assets/img/favicon.svg" }
    }
  }
  </script>
</head>
<body>
  <header class="site-header">
    <div class="header-inner">
      <a href="index.html" class="brand">
        <span class="logo">TOGH</span>
        <span class="brand-text">
          <span class="full">Today On General Hospital</span>
          <small>Spoilers &bull; Recaps &bull; News</small>
        </span>
      </a>
      <button class="nav-toggle" aria-label="Toggle menu" aria-expanded="false">&#9776;</button>
      <nav class="main-nav">
        <ul>
          <li><a href="index.html">Home</a></li>
          <li><a href="spoilers.html">Spoilers</a></li>
          <li><a href="recaps.html">Recaps</a></li>
          <li><a href="news.html">News</a></li>
          <li><a href="about.html">About</a></li>
          <li><a href="contact.html">Contact</a></li>
        </ul>
      </nav>
    </div>
  </header>

  <main class="container">
    <article class="article">
      <span class="badge badge-recap">Recap</span>
      <h1>$titleEnc</h1>
      <div class="article-meta">By Today On General Hospital &bull; $($post.Day), $($post.DisplayDate) &bull; General Hospital Recap</div>
      <p class="article-dek">$dekEnc</p>
$body
      <p class="post-source">This is an original recap written by Today On General Hospital for our fans. Follow our <a href="$script:FollowUrl" target="_blank" rel="noopener">Facebook page</a> for daily General Hospital updates.</p>
      <p style="margin-top:20px;">
        <a class="btn" href="recaps.html">&larr; All Recaps</a>
        <a class="btn btn-fb" href="$script:FollowUrl" target="_blank" rel="noopener">Share on Facebook</a>
      </p>
    </article>
  </main>

  <footer class="site-footer">
    <div class="footer-inner">
      <div class="footer-cols">
        <div>
          <h4>Today On General Hospital</h4>
          <p>An independent fan site delivering daily General Hospital spoilers, recaps and news. We are not affiliated with ABC or the official General Hospital production.</p>
        </div>
        <div>
          <h4>Categories</h4>
          <ul>
            <li><a href="spoilers.html">Spoilers</a></li>
            <li><a href="recaps.html">Recaps</a></li>
            <li><a href="news.html">News</a></li>
          </ul>
        </div>
        <div>
          <h4>Site</h4>
          <ul>
            <li><a href="about.html">About Us</a></li>
            <li><a href="contact.html">Contact</a></li>
            <li><a href="privacy-policy.html">Privacy Policy</a></li>
            <li><a href="disclaimer.html">Disclaimer</a></li>
          </ul>
        </div>
      </div>
    </div>
    <div class="footer-bottom">
      &copy; <span class="js-year">2026</span> Today On General Hospital. All rights reserved. Fan site &bull; Not affiliated with ABC.
    </div>
  </footer>

  <script src="assets/js/main.js"></script>
</body>
</html>
"@

    $outAbs = Join-Path $script:Root "$slug.html"
    Set-Content -Path $outAbs -Value $html -Encoding UTF8
    Write-Host ("Wrote {0}.html ({1} images)" -f $slug, $imgCount)

    $script:PostIndex += [pscustomobject]@{
        Slug = $slug
        Title = $post.Title
        Dek = $post.Dek
        Date = $post.Date
        Day = $post.Day
        DisplayDate = $post.DisplayDate
        Image = $firstImageRel
    }
}


function Card($p) {
    $img = HtmlEnc $p.Image
    $title = HtmlEnc $p.Title
    $dek = HtmlEnc $p.Dek
    return @"
          <article class="post-card">
            <div class="post-head">
              <div class="avatar">GH</div>
              <div class="post-meta"><strong>Today On General Hospital</strong><span>Recap &bull; $($p.Day), $($p.DisplayDate)</span></div>
            </div>
            <h2 class="post-title"><a href="$($p.Slug).html">$title</a></h2>
            <p class="post-excerpt">$dek</p>
            <a href="$($p.Slug).html"><img class="post-image" src="$img" alt="$title" /></a>
            <div class="post-actions">
              <a href="$($p.Slug).html">Read Full Recap</a>
              <a href="$script:FollowUrl" target="_blank" rel="noopener">Share on Facebook</a>
            </div>
          </article>
"@
}

function Build-Listings {
    $sorted = $script:PostIndex | Sort-Object { [datetime]$_.Date } -Descending

    # ---------- recaps.html ----------
    $cards = ($sorted | ForEach-Object { Card $_ }) -join "`r`n"
    $recaps = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>General Hospital Recaps - Today On General Hospital</title>
  <meta name="description" content="Daily General Hospital recaps. Catch up on every GH episode with detailed recaps covering all the key moments from Port Charles." />
  <meta name="keywords" content="General Hospital recap, GH recap, GH daily recap, General Hospital episode recap" />
  <link rel="canonical" href="https://todayongh.onl/recaps.html" />
  <meta name="robots" content="index, follow" />
  <meta property="og:type" content="website" />
  <meta property="og:title" content="General Hospital Recaps - Today On General Hospital" />
  <meta property="og:description" content="Daily General Hospital episode recaps covering every key moment." />
  <meta property="og:url" content="https://todayongh.onl/recaps.html" />
  <link rel="icon" href="assets/img/favicon.svg" />
  <link rel="stylesheet" href="assets/css/style.css" />
</head>
<body>
  <header class="site-header">
    <div class="header-inner">
      <a href="index.html" class="brand">
        <span class="logo">TOGH</span>
        <span class="brand-text">
          <span class="full">Today On General Hospital</span>
          <small>Spoilers &bull; Recaps &bull; News</small>
        </span>
      </a>
      <button class="nav-toggle" aria-label="Toggle menu" aria-expanded="false">&#9776;</button>
      <nav class="main-nav">
        <ul>
          <li><a href="index.html">Home</a></li>
          <li><a href="spoilers.html">Spoilers</a></li>
          <li><a href="recaps.html">Recaps</a></li>
          <li><a href="news.html">News</a></li>
          <li><a href="about.html">About</a></li>
          <li><a href="contact.html">Contact</a></li>
        </ul>
      </nav>
    </div>
  </header>

  <main class="container">
    <div class="layout">
      <div>
        <h1 class="section-title"><span class="badge badge-recap">Recap</span> General Hospital Recaps</h1>
        <p style="color:var(--text-muted); margin-bottom:16px;">Missed an episode? Catch up with our detailed daily General Hospital recaps, newest first.</p>
        <div class="feed">
$cards
        </div>
      </div>
      <aside class="sidebar">
        <div class="widget fb-follow">
          <h3>Follow Us</h3>
          <p>Get daily GH recaps on Facebook.</p>
          <a class="btn btn-fb" href="$script:FollowUrl" target="_blank" rel="noopener">Like our Page</a>
        </div>
        <div class="widget">
          <h3>Categories</h3>
          <ul>
            <li><a href="spoilers.html">Spoilers</a></li>
            <li><a href="recaps.html">Recaps</a></li>
            <li><a href="news.html">News</a></li>
          </ul>
        </div>
      </aside>
    </div>
  </main>

  <footer class="site-footer">
    <div class="footer-inner">
      <div class="footer-cols">
        <div>
          <h4>Today On General Hospital</h4>
          <p>An independent fan site delivering daily General Hospital spoilers, recaps and news. We are not affiliated with ABC or the official General Hospital production.</p>
        </div>
        <div>
          <h4>Categories</h4>
          <ul>
            <li><a href="spoilers.html">Spoilers</a></li>
            <li><a href="recaps.html">Recaps</a></li>
            <li><a href="news.html">News</a></li>
          </ul>
        </div>
        <div>
          <h4>Site</h4>
          <ul>
            <li><a href="about.html">About Us</a></li>
            <li><a href="contact.html">Contact</a></li>
            <li><a href="privacy-policy.html">Privacy Policy</a></li>
            <li><a href="disclaimer.html">Disclaimer</a></li>
          </ul>
        </div>
      </div>
    </div>
    <div class="footer-bottom">
      &copy; <span class="js-year">2026</span> Today On General Hospital. All rights reserved. Fan site &bull; Not affiliated with ABC.
    </div>
  </footer>
  <script src="assets/js/main.js"></script>
</body>
</html>
"@
    Set-Content -Path (Join-Path $script:Root 'recaps.html') -Value $recaps -Encoding UTF8
    Write-Host 'Wrote recaps.html'

    # ---------- index.html feed (latest 6) ----------
    $latest = $sorted | Select-Object -First 6
    $homeCards = ($latest | ForEach-Object { Card $_ }) -join "`r`n"
    $sideList = ($sorted | Select-Object -First 5 | ForEach-Object {
        '            <li><a href="' + $_.Slug + '.html">' + (HtmlEnc $_.Title) + '</a></li>'
    }) -join "`r`n"

    $index = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Today On General Hospital - Spoilers, Recaps &amp; News</title>
  <meta name="description" content="Today On General Hospital brings you daily General Hospital recaps, spoilers and news. Your #1 fan source for everything happening in Port Charles." />
  <meta name="keywords" content="General Hospital, GH spoilers, General Hospital recap, GH news, Today On General Hospital, Port Charles" />
  <link rel="canonical" href="https://todayongh.onl/" />
  <meta name="robots" content="index, follow" />
  <meta property="og:type" content="website" />
  <meta property="og:site_name" content="Today On General Hospital" />
  <meta property="og:title" content="Today On General Hospital - Spoilers, Recaps &amp; News" />
  <meta property="og:description" content="Daily General Hospital recaps, spoilers and news from Port Charles." />
  <meta property="og:url" content="https://todayongh.onl/" />
  <link rel="icon" href="assets/img/favicon.svg" />
  <link rel="stylesheet" href="assets/css/style.css" />
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebSite",
    "name": "Today On General Hospital",
    "url": "https://todayongh.onl/"
  }
  </script>
</head>
<body>
  <header class="site-header">
    <div class="header-inner">
      <a href="index.html" class="brand">
        <span class="logo">TOGH</span>
        <span class="brand-text">
          <span class="full">Today On General Hospital</span>
          <small>Spoilers &bull; Recaps &bull; News</small>
        </span>
      </a>
      <button class="nav-toggle" aria-label="Toggle menu" aria-expanded="false">&#9776;</button>
      <nav class="main-nav">
        <ul>
          <li><a href="index.html">Home</a></li>
          <li><a href="spoilers.html">Spoilers</a></li>
          <li><a href="recaps.html">Recaps</a></li>
          <li><a href="news.html">News</a></li>
          <li><a href="about.html">About</a></li>
          <li><a href="contact.html">Contact</a></li>
        </ul>
      </nav>
    </div>
  </header>

  <main class="container">
    <section class="cover">
      <h1>Today On General Hospital</h1>
      <p>Your daily home for General Hospital recaps, spoilers, and news from Port Charles. Updated every weekday for true GH fans.</p>
      <div class="cover-cta">
        <a class="btn btn-fb" href="$script:FollowUrl" target="_blank" rel="noopener">Follow on Facebook</a>
        <a class="btn btn-green" href="recaps.html">Read Latest Recaps</a>
      </div>
    </section>

    <div class="layout">
      <div>
        <h2 class="section-title">Latest Recaps</h2>
        <div class="feed">
$homeCards
        </div>
        <p style="margin-top:16px;"><a class="btn" href="recaps.html">View All Recaps &rarr;</a></p>
      </div>
      <aside class="sidebar">
        <div class="widget fb-follow">
          <h3>Follow Us</h3>
          <p>Join 23K+ fans getting daily General Hospital updates on Facebook.</p>
          <a class="btn btn-fb" href="$script:FollowUrl" target="_blank" rel="noopener">Like our Page</a>
        </div>
        <div class="widget">
          <h3>Categories</h3>
          <ul>
            <li><a href="spoilers.html">Spoilers</a></li>
            <li><a href="recaps.html">Recaps</a></li>
            <li><a href="news.html">News</a></li>
          </ul>
        </div>
        <div class="widget">
          <h3>Recent Recaps</h3>
          <ul>
$sideList
          </ul>
        </div>
      </aside>
    </div>
  </main>

  <footer class="site-footer">
    <div class="footer-inner">
      <div class="footer-cols">
        <div>
          <h4>Today On General Hospital</h4>
          <p>An independent fan site delivering daily General Hospital spoilers, recaps and news. We are not affiliated with ABC or the official General Hospital production.</p>
        </div>
        <div>
          <h4>Categories</h4>
          <ul>
            <li><a href="spoilers.html">Spoilers</a></li>
            <li><a href="recaps.html">Recaps</a></li>
            <li><a href="news.html">News</a></li>
          </ul>
        </div>
        <div>
          <h4>Site</h4>
          <ul>
            <li><a href="about.html">About Us</a></li>
            <li><a href="contact.html">Contact</a></li>
            <li><a href="privacy-policy.html">Privacy Policy</a></li>
            <li><a href="disclaimer.html">Disclaimer</a></li>
          </ul>
        </div>
      </div>
    </div>
    <div class="footer-bottom">
      &copy; <span class="js-year">2026</span> Today On General Hospital. All rights reserved. Fan site &bull; Not affiliated with ABC.
    </div>
  </footer>
  <script src="assets/js/main.js"></script>
</body>
</html>
"@
    Set-Content -Path (Join-Path $script:Root 'index.html') -Value $index -Encoding UTF8
    Write-Host 'Wrote index.html'

    # ---------- sitemap.xml ----------
    $staticUrls = @('','spoilers.html','recaps.html','news.html','about.html','contact.html','privacy-policy.html','disclaimer.html')
    $sm = @()
    $sm += '<?xml version="1.0" encoding="UTF-8"?>'
    $sm += '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
    foreach ($u in $staticUrls) {
        $sm += '  <url><loc>https://todayongh.onl/' + $u + '</loc></url>'
    }
    foreach ($p in $sorted) {
        $sm += '  <url><loc>https://todayongh.onl/' + $p.Slug + '.html</loc><lastmod>' + $p.Date + '</lastmod></url>'
    }
    $sm += '</urlset>'
    Set-Content -Path (Join-Path $script:Root 'sitemap.xml') -Value ($sm -join "`r`n") -Encoding UTF8
    Write-Host 'Wrote sitemap.xml'
}
