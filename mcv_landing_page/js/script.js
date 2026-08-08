function setLang(lang){
  document.documentElement.setAttribute('data-lang', lang);
  document.getElementById('btn-en').classList.toggle('active', lang === 'en');
  document.getElementById('btn-fr').classList.toggle('active', lang === 'fr');
  try { localStorage.setItem('mcv-lang', lang); } catch(e) {}
}

(function(){
  try {
    var saved = localStorage.getItem('mcv-lang');
    if (saved === 'fr' || saved === 'en') setLang(saved);
  } catch(e) {}
})();


function scrollToSection() {
  const isMobile = window.innerWidth <= 820;
  const targetId = isMobile ? 'pwa-card' : 'get-app';
  const target = document.getElementById(targetId);
  if (!target) return;

  const offset = isMobile ? 50 : -50;
  const y = target.getBoundingClientRect().top + window.pageYOffset - offset;
  window.scrollTo({ top: y, behavior: 'smooth' });
}

document.querySelectorAll('a[href^="#"]').forEach(link => {
  link.addEventListener('click', (e) => {
    const id = link.getAttribute('href').slice(1);
    if (document.getElementById(id)) {
      e.preventDefault();
      scrollToSection(id);
    }
  });
});