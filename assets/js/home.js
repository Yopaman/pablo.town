const glowToggles = document.querySelectorAll(".glow-toggle");

function handleGlowClick(e) {
  if (e.target.classList.contains("glow")) {
    e.target.classList.remove("glow");
  } else {
    e.target.classList.add("glow")
  }
}

for (let i = 0; i < glowToggles.length; i++) {
  glowToggles[i].addEventListener("click", handleGlowClick);
}
