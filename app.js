const apodStatus = document.getElementById("apodStatus");
const starsStatus = document.getElementById("starsStatus");
const apodContent = document.getElementById("apodContent");
const apodTitle = document.getElementById("apodTitle");
const apodImage = document.getElementById("apodImage");
const apodExplanation = document.getElementById("apodExplanation");
const starsTable = document.getElementById("starsTable");
const starsTableBody = document.getElementById("starsTableBody");
const apiKeyInput = document.getElementById("apiKey");
const loadDataButton = document.getElementById("loadDataButton");

function setStatus(element, message, isError = false) {
  element.textContent = message;
  element.style.color = isError ? "#ff8d8d" : "#b8c2e6";
}

function toFixedIfNumber(value, digits = 3) {
  return typeof value === "number" && Number.isFinite(value) ? value.toFixed(digits) : "-";
}

async function loadApod(apiKey) {
  setStatus(apodStatus, "Görsel verisi yükleniyor...");
  apodContent.classList.add("hidden");

  const response = await fetch(`https://api.nasa.gov/planetary/apod?api_key=${encodeURIComponent(apiKey)}`);
  if (!response.ok) {
    throw new Error("APOD verisi alınamadı.");
  }

  const data = await response.json();
  apodTitle.textContent = data.title || "Günün görseli";
  apodExplanation.textContent = data.explanation || "Açıklama bulunamadı.";
  apodImage.src = data.url || "";
  apodImage.alt = data.title || "NASA görseli";
  apodContent.classList.remove("hidden");
  setStatus(apodStatus, `Tarih: ${data.date || "-"}`);
}

async function loadStarPositions() {
  setStatus(starsStatus, "Yıldız konumu verileri yükleniyor...");
  starsTable.classList.add("hidden");
  starsTableBody.innerHTML = "";

  const query =
    "select top 8 hostname,ra,dec,sy_dist from pscomppars where ra is not null and dec is not null order by sy_dist";
  const endpoint = `https://exoplanetarchive.ipac.caltech.edu/TAP/sync?query=${encodeURIComponent(query)}&format=json`;

  const response = await fetch(endpoint);
  if (!response.ok) {
    throw new Error("Yıldız konumu verileri alınamadı.");
  }

  const stars = await response.json();
  if (!Array.isArray(stars) || stars.length === 0) {
    throw new Error("Gösterilecek yıldız konumu verisi bulunamadı.");
  }

  stars.forEach((star) => {
    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td>${star.hostname || "-"}</td>
      <td>${toFixedIfNumber(star.ra)}</td>
      <td>${toFixedIfNumber(star.dec)}</td>
      <td>${toFixedIfNumber(star.sy_dist)}</td>
    `;
    starsTableBody.appendChild(tr);
  });

  starsTable.classList.remove("hidden");
  setStatus(starsStatus, `${stars.length} kayıt listeleniyor.`);
}

async function loadAllData() {
  const apiKey = apiKeyInput.value.trim() || "DEMO_KEY";
  loadDataButton.disabled = true;

  try {
    await Promise.all([loadApod(apiKey), loadStarPositions()]);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Veri yüklenirken hata oluştu.";
    if (apodContent.classList.contains("hidden")) {
      setStatus(apodStatus, message, true);
    }
    if (starsTable.classList.contains("hidden")) {
      setStatus(starsStatus, message, true);
    }
  } finally {
    loadDataButton.disabled = false;
  }
}

loadDataButton.addEventListener("click", loadAllData);
loadAllData();
