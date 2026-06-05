import './style.css'

/**
 * Reveal on Scroll Animation
 * Uses Intersection Observer to fade in elements as they enter the viewport
 */
const observerOptions = {
  root: null,
  rootMargin: '0px',
  threshold: 0.1
};

const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('reveal-visible');
      // Once revealed, we don't need to observe it anymore
      observer.unobserve(entry.target);
    }
  });
}, observerOptions);

// Initialize animations once DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
  // Select sections and grid items for animation
  const revealElements = document.querySelectorAll('section, .group, #projects > div');
  
  revealElements.forEach(el => {
    el.classList.add('reveal-hidden');
    observer.observe(el);
  });
});

console.log('Portfolio initialized with animations');
