var slideIndex = 1;
showSlides(slideIndex);

function plusSlides(n) { showSlides(slideIndex += n); }
function currentSlide(n) { showSlides(slideIndex = n); }

function showSlides(n) {
  var slides = document.getElementsByClassName("mySlides");
  var dots   = document.getElementsByClassName("dot");
  if (n > slides.length) slideIndex = 1;
  if (n < 1)             slideIndex = slides.length;
  for (var i = 0; i < slides.length; i++) slides[i].style.display = "none";
  for (i = 0; i < dots.length;   i++) dots[i].classList.remove("active");
  slides[slideIndex-1].style.display = "block";
  dots[slideIndex-1].classList.add("active");
}

// --- auto‐advance control ---
var interval;
function startAuto() {
  clearInterval(interval);
  interval = setInterval(() => plusSlides(1), 3000);
}
function stopAuto() {
  clearInterval(interval);
}

// kick off on page load
startAuto();

// pause when pointer is on prev/next, resume when it leaves
var prevBtn = document.querySelector('.prev');
var nextBtn = document.querySelector('.next');
[prevBtn, nextBtn].forEach(btn => {
  btn.addEventListener('mouseenter', stopAuto);
  btn.addEventListener('mouseleave', startAuto);
});
