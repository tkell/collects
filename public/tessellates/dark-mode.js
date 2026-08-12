(function () {
  const savedTheme = localStorage.getItem('theme');
  if (savedTheme === 'dark-mode') {
    document.documentElement.setAttribute('data-theme', 'dark-mode');
  } else {
    document.documentElement.setAttribute('data-theme', 'light-mode');
  }
})();
