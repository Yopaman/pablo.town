let topZ = 10;

for (const win of document.getElementsByTagName("window")) {
  const bar = win.getElementsByTagName("window-title")[0];
  if (!bar) continue;

  let startX = 0, startY = 0, baseX = 0, baseY = 0;

  bar.addEventListener("pointerdown", e => {
    if (e.button !== 0) return;

    const t = getComputedStyle(win).translate;
    if (t === "none") {
      baseX = baseY = 0;
    } else {
      const parts = t.split(" ").map(parseFloat);
      baseX = parts[0] || 0;
      baseY = parts[1] || 0;
    }

    startX = e.clientX;
    startY = e.clientY;
    win.style.zIndex = ++topZ;
    bar.setPointerCapture(e.pointerId);
  });

  bar.addEventListener("pointermove", e => {
    if (!bar.hasPointerCapture(e.pointerId)) return;
    win.style.translate =
      `${baseX + e.clientX - startX}px ${baseY + e.clientY - startY}px`;
  });
}
