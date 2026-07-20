/* Google Analytics (gtag.js) - Today On General Hospital
   Measurement ID: G-83S71RGVTZ
   Loaded on every page so tracking is managed from this single file. */
(function () {
  var GA_ID = "G-83S71RGVTZ";

  // Load the gtag.js library
  var s = document.createElement("script");
  s.async = true;
  s.src = "https://www.googletagmanager.com/gtag/js?id=" + GA_ID;
  document.head.appendChild(s);

  // Initialize gtag
  window.dataLayer = window.dataLayer || [];
  function gtag() { dataLayer.push(arguments); }
  window.gtag = gtag;
  gtag("js", new Date());
  gtag("config", GA_ID);
})();
