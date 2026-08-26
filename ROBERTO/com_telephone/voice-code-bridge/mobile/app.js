const connDot = document.getElementById("connDot");
const connLabel = document.getElementById("connLabel");
const stateLabel = document.getElementById("stateLabel");
const resetBtn = document.getElementById("resetBtn");
const chat = document.getElementById("chat");
const composer = document.getElementById("composer");
const textInput = document.getElementById("textInput");
const sendBtn = document.getElementById("sendBtn");
const imgInput = document.getElementById("imgInput");
const imgBtn = document.getElementById("imgBtn");
const statusBtn = document.getElementById("statusBtn");
const micBtn = document.getElementById("micBtn");
const voiceScreen = document.getElementById("voiceScreen");
const voiceCircle = document.getElementById("voiceCircle");
const voiceStatus = document.getElementById("voiceStatus");
const voiceCancel = document.getElementById("voiceCancel");
const modeBtn = document.getElementById("modeBtn");
const micHold = document.getElementById("micHold");
const assistantAudioEl = document.getElementById("assistantAudio");
const validationBar = document.getElementById("validationBar");
const validBtn = document.getElementById("validBtn");
const corrBtn = document.getElementById("corrBtn");
const voiceValidation = document.getElementById("voiceValidation");
const voiceValidBtn = document.getElementById("voiceValidBtn");
const voiceCorrBtn = document.getElementById("voiceCorrBtn");
const choiceBar = document.getElementById("choiceBar");

function showValidationButtons(show) {
  validationBar.classList.toggle("visible", show);
  voiceValidation.classList.toggle("visible", show);
}

function showChoiceButtons(options, recommended) {
  choiceBar.innerHTML = "";
  if (!options || !options.length) {
    choiceBar.classList.remove("visible");
    return;
  }
  for (const label of options) {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = "choiceBtn" + (label === recommended ? " recommended" : "");
    btn.textContent = label;
    btn.addEventListener("click", () => {
      choiceBar.classList.remove("visible");
      choiceBar.innerHTML = "";
      sendUserMessage(label, "texte");
    });
    choiceBar.appendChild(btn);
  }
  choiceBar.classList.add("visible");
}

let ws = null;
let reconnectTimer = null;
let currentSession = null;
let sessionCounter = 0;
let hasSpoken = false;
let voiceCancelled = false;
let currentAudio = null;
let audioUnlocked = false;
let retryArmed = false;
let wakeLock = null;
let recordMode = "auto";

try {
  recordMode = localStorage.getItem("recordMode") === "manual" ? "manual" : "auto";
} catch {}

function setRecordMode(mode) {
  recordMode = mode;
  try {
    localStorage.setItem("recordMode", mode);
  } catch {}
  modeBtn.textContent = mode === "auto" ? "Auto" : "Manuel";
}

function armMic() {
  micHold.classList.add("armed");
  micHold.classList.remove("recording");
}

function disarmMic() {
  micHold.classList.remove("armed", "recording");
}

function setMicRecording() {
  micHold.classList.remove("armed");
  micHold.classList.add("recording");
}

const SILENT_WAV = "data:audio/wav;base64,UklGRiQAAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQAAAAA=";

const VAPID_PUBLIC_KEY = "BGh9SgMiThjIktBHR4dsATPFviTWnxqDQe3nAABxk2ZJUVwa8VxEdiur3pHUUX3pxF4s5aoJgmQsy7U8YpwzSJ0";

function urlBase64ToUint8Array(base64String) {
  const padding = "=".repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/");
  const rawData = atob(base64);
  const output = new Uint8Array(rawData.length);
  for (let i = 0; i < rawData.length; i++) output[i] = rawData.charCodeAt(i);
  return output;
}

let pushEnabled = false;

async function enablePushNotifications() {
  if (pushEnabled) return;
  if (!("serviceWorker" in navigator) || !("PushManager" in window) || Notification.permission !== "granted") return;
  try {
    const reg = await navigator.serviceWorker.ready;
    const existing = await reg.pushManager.getSubscription();
    if (existing) {
      await existing.unsubscribe();
    }
    const sub = await reg.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: urlBase64ToUint8Array(VAPID_PUBLIC_KEY)
    });
    await fetch("/push/subscribe", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(sub)
    });
    pushEnabled = true;
  } catch (err) {
    debugLog(`abonnement push impossible: ${err.message}`);
  }
}

async function askPushPermission() {
  if (!("serviceWorker" in navigator) || !("PushManager" in window)) return;
  if (Notification.permission === "default") {
    try {
      const perm = await Notification.requestPermission();
      if (perm === "granted") await enablePushNotifications();
    } catch {}
  } else if (Notification.permission === "granted") {
    await enablePushNotifications();
  }
}

async function requestWakeLock() {
  try {
    if ("wakeLock" in navigator && document.visibilityState === "visible") {
      wakeLock = await navigator.wakeLock.request("screen");
    }
  } catch {}
}

function ensureConnected() {
  if (!ws || (ws.readyState !== WebSocket.OPEN && ws.readyState !== WebSocket.CONNECTING)) {
    clearTimeout(reconnectTimer);
    connect();
  }
}

document.addEventListener("visibilitychange", () => {
  if (document.visibilityState === "visible") {
    requestWakeLock();
    ensureConnected();
  }
});

window.addEventListener("pageshow", ensureConnected);

function unlockAudioElement() {
  if (audioUnlocked) return;
  audioUnlocked = true;
  assistantAudioEl.src = SILENT_WAV;
  assistantAudioEl.play().then(() => {
    assistantAudioEl.pause();
    assistantAudioEl.currentTime = 0;
  }).catch(() => {
    audioUnlocked = false;
  });
}

const SPEECH_THRESHOLD = 0.02;
const SILENCE_MS = 900;
const MAX_DURATION_MS = 15000;

function wsUrl() {
  const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
  const portSuffix = window.location.port ? `:${window.location.port}` : "";
  return `${protocol}//${window.location.hostname}${portSuffix}`;
}

function setConnected(connected) {
  connDot.classList.toggle("connected", connected);
  connLabel.textContent = connected ? "Connecté" : "Déconnecté";
}

function setState(state) {
  const labels = {
    listening: "Écoute",
    processing: "Traitement",
    speaking: "Réponse",
    error: "Erreur"
  };
  stateLabel.textContent = labels[state] || "";
  if (state === "processing") {
    showThinking();
  } else {
    hideThinking();
  }
}

let thinkingEl = null;

function showThinking() {
  if (thinkingEl) return;
  thinkingEl = document.createElement("div");
  thinkingEl.className = "bubble assistant thinking";
  thinkingEl.textContent = "Titi réfléchit...";
  chat.appendChild(thinkingEl);
  chat.scrollTop = chat.scrollHeight;
}

function hideThinking() {
  if (!thinkingEl) return;
  thinkingEl.remove();
  thinkingEl = null;
}

const HISTORY_KEY = "chatHistory";
const MAX_HISTORY = 50;

function pushHistory(entry) {
  let history = [];
  try {
    history = JSON.parse(localStorage.getItem(HISTORY_KEY)) || [];
  } catch {}
  history.push(entry);
  if (history.length > MAX_HISTORY) history = history.slice(-MAX_HISTORY);
  try {
    localStorage.setItem(HISTORY_KEY, JSON.stringify(history));
  } catch {}
}

function fallbackCopy(text) {
  const textarea = document.createElement("textarea");
  textarea.value = text;
  textarea.style.position = "fixed";
  textarea.style.opacity = "0";
  document.body.appendChild(textarea);
  textarea.focus();
  textarea.select();
  try {
    document.execCommand("copy");
  } catch {}
  document.body.removeChild(textarea);
}

function copyText(text, btn) {
  const markCopied = () => {
    btn.classList.add("copied");
    btn.textContent = "✓";
    setTimeout(() => {
      btn.classList.remove("copied");
      btn.textContent = "⧉";
    }, 1200);
  };
  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(text).then(markCopied).catch(() => {
      fallbackCopy(text);
      markCopied();
    });
  } else {
    fallbackCopy(text);
    markCopied();
  }
}

function addCopyButton(bubbleEl, text) {
  const btn = document.createElement("button");
  btn.type = "button";
  btn.className = "copyBtn";
  btn.textContent = "⧉";
  btn.setAttribute("aria-label", "Copier le message");
  btn.addEventListener("click", () => copyText(text, btn));
  bubbleEl.appendChild(btn);
}

function renderTextBubble(role, text) {
  const el = document.createElement("div");
  el.className = `bubble ${role}`;
  el.textContent = text;
  if (role === "assistant") addCopyButton(el, text);
  chat.appendChild(el);
  chat.scrollTop = chat.scrollHeight;
}

function renderImageBubble(role, dataUrl, caption) {
  const el = document.createElement("div");
  el.className = `bubble ${role}`;
  const img = document.createElement("img");
  img.onload = () => { chat.scrollTop = chat.scrollHeight; };
  img.src = dataUrl;
  el.appendChild(img);
  if (caption) {
    const p = document.createElement("div");
    p.textContent = caption;
    p.style.marginTop = "6px";
    el.appendChild(p);
  }
  chat.appendChild(el);
  chat.scrollTop = chat.scrollHeight;
}

function addBubble(role, text) {
  renderTextBubble(role, text);
  pushHistory({ type: "text", role, text });
}

let messageCounter = 0;
const pendingStatus = new Map();

function addUserMessageBubble(text, id) {
  const el = document.createElement("div");
  el.className = "bubble user";
  const textEl = document.createElement("div");
  textEl.textContent = text;
  el.appendChild(textEl);
  const statusEl = document.createElement("div");
  statusEl.className = "bubbleStatus";
  statusEl.textContent = "Envoi en cours...";
  el.appendChild(statusEl);
  chat.appendChild(el);
  chat.scrollTop = chat.scrollHeight;
  pendingStatus.set(id, statusEl);
  pushHistory({ type: "text", role: "user", text });
}

function markMessageDelivered(id) {
  const statusEl = pendingStatus.get(id);
  if (!statusEl) return;
  statusEl.textContent = "Livré à Titi";
  pendingStatus.delete(id);
  setTimeout(() => statusEl.remove(), 2000);
}

function addImageBubble(role, dataUrl, caption) {
  renderImageBubble(role, dataUrl, caption);
  pushHistory({ type: "image", role, dataUrl, caption });
}

function restoreHistory() {
  let history = [];
  try {
    history = JSON.parse(localStorage.getItem(HISTORY_KEY)) || [];
  } catch {}
  for (const entry of history) {
    if (entry.type === "image") {
      renderImageBubble(entry.role, entry.dataUrl, entry.caption);
    } else {
      renderTextBubble(entry.role, entry.text);
    }
  }
}

function connect() {
  ws = new WebSocket(wsUrl());

  ws.onopen = () => {
    setConnected(true);
    clearTimeout(reconnectTimer);
  };

  ws.onclose = () => {
    setConnected(false);
    reconnectTimer = setTimeout(connect, 3000);
  };

  ws.onerror = () => {
    setConnected(false);
  };

  ws.onmessage = (event) => {
    const msg = JSON.parse(event.data);

    if (msg.type === "state") {
      setState(msg.state);
    } else if (msg.type === "message.ack") {
      markMessageDelivered(msg.id);
    } else if (msg.type === "assistant.text") {
      hideThinking();
      addBubble("assistant", msg.text);
      showValidationButtons(!!msg.awaitValidation);
      showChoiceButtons(msg.options, msg.recommended);
    } else if (msg.type === "assistant.audio") {
      playAssistantAudio(msg.audio, msg.mime);
    }
  };
}

function playAssistantAudio(base64, mime) {
  const inVoiceMode = voiceScreen.classList.contains("active") && !voiceCancelled;
  if (inVoiceMode) {
    voiceCircle.classList.remove("thinking", "paused");
    voiceCircle.classList.add("done");
    voiceStatus.textContent = "Titi vous répond...";
  }

  const audio = assistantAudioEl;
  currentAudio = audio;

  const resumeListening = () => {
    if (currentAudio !== audio) return;
    currentAudio = null;
    audio.onended = null;
    audio.onerror = null;
    if (inVoiceMode && !voiceCancelled) {
      if (recordMode === "auto") {
        startVoiceCapture();
      } else {
        armMic();
        voiceStatus.textContent = "Prêt. Maintenez le micro appuyé pour parler.";
      }
    }
  };

  audio.onended = resumeListening;
  audio.onerror = () => {
    debugLog("erreur lecture audio assistant");
    resumeListening();
  };

  audio.src = `data:${mime};base64,${base64}`;
  audio.play().catch((err) => {
    debugLog(`autoplay bloque: ${err.message}`);
    resumeListening();
  });
}

function sendUserMessage(text, channel) {
  if (!text || !ws || ws.readyState !== WebSocket.OPEN) return;
  const id = `u${Date.now()}_${++messageCounter}`;
  addUserMessageBubble(text, id);
  ws.send(JSON.stringify({ type: "user.message", text, channel: channel || "texte", id }));
}

const MAX_IMAGE_BYTES = 8 * 1024 * 1024;

function sendUserImage(file) {
  if (!file || !ws || ws.readyState !== WebSocket.OPEN) return;
  if (file.size > MAX_IMAGE_BYTES) {
    debugLog(`image trop volumineuse: ${file.size} octets`);
    return;
  }
  const caption = textInput.value.trim();
  const reader = new FileReader();
  reader.onload = () => {
    const dataUrl = reader.result;
    addImageBubble("user", dataUrl, caption);
    ws.send(JSON.stringify({ type: "user.image", data: dataUrl, caption }));
    textInput.value = "";
  };
  reader.onerror = () => debugLog("lecture image echouee");
  reader.readAsDataURL(file);
}

async function pasteImageFromClipboard() {
  if (!navigator.clipboard || !navigator.clipboard.read) {
    imgInput.click();
    return;
  }
  try {
    const items = await navigator.clipboard.read();
    for (const item of items) {
      const type = item.types.find((t) => t.startsWith("image/"));
      if (type) {
        const blob = await item.getType(type);
        sendUserImage(blob);
        return;
      }
    }
    debugLog("aucune image dans le presse-papier");
    imgInput.click();
  } catch (err) {
    debugLog(`lecture presse-papier impossible: ${err.message}`);
    imgInput.click();
  }
}

imgBtn.addEventListener("click", pasteImageFromClipboard);

statusBtn.addEventListener("click", () => {
  sendUserMessage("Que fais-tu ?", "texte");
});
resetBtn.addEventListener("click", () => {
  chat.innerHTML = "";
  try {
    localStorage.removeItem(HISTORY_KEY);
  } catch {}
});
imgInput.addEventListener("change", () => {
  const file = imgInput.files[0];
  imgInput.value = "";
  sendUserImage(file);
});

function sendValidation(value) {
  if (!ws || ws.readyState !== WebSocket.OPEN) return;
  ws.send(JSON.stringify({ type: "user.validation", value }));
}

function startCorrectionCapture() {
  haltSession(currentSession);
  if (currentAudio) {
    currentAudio.pause();
    currentAudio = null;
  }
  if (recordMode === "auto") {
    startVoiceCapture();
  } else {
    openVoiceScreen();
    voiceStatus.textContent = "Correction. Maintenez le micro appuyé pour dicter.";
  }
}

validBtn.addEventListener("click", () => {
  sendValidation("ok");
  addBubble("user", "✓ Validé");
  showValidationButtons(false);
});

corrBtn.addEventListener("click", () => {
  sendValidation("corriger");
  addBubble("user", "✗ Corrigé");
  showValidationButtons(false);
  unlockAudioElement();
  startCorrectionCapture();
});

voiceValidBtn.addEventListener("click", () => {
  sendValidation("ok");
  voiceStatus.textContent = "Validé.";
  showValidationButtons(false);
});

voiceCorrBtn.addEventListener("click", () => {
  sendValidation("corriger");
  showValidationButtons(false);
  startCorrectionCapture();
});

composer.addEventListener("submit", (e) => {
  e.preventDefault();
  askPushPermission();
  const text = textInput.value.trim();
  sendUserMessage(text);
  textInput.value = "";
});

function openVoiceScreen() {
  voiceScreen.classList.add("active");
  voiceCircle.classList.remove("done", "thinking", "paused");
  voiceStatus.textContent = recordMode === "auto" ? "Je vous écoute..." : "Prêt. Maintenez le micro appuyé pour parler.";
  modeBtn.textContent = recordMode === "auto" ? "Auto" : "Manuel";
  armMic();
}

function closeVoiceScreen() {
  voiceScreen.classList.remove("active");
  retryArmed = false;
}

voiceCircle.addEventListener("click", () => {
  if (retryArmed && recordMode === "auto") startVoiceCapture();
});

function debugLog(text) {
  fetch("/debug", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ text })
  }).catch(() => {});
}

function pickMimeType() {
  const candidates = ["audio/webm", "audio/mp4", "audio/ogg"];
  for (const type of candidates) {
    if (window.MediaRecorder && MediaRecorder.isTypeSupported(type)) return type;
  }
  return "";
}

function confirmAndSend(transcript) {
  voiceCircle.classList.remove("paused");
  voiceCircle.classList.add("done");
  voiceStatus.textContent = "Compris, j'envoie à Titi";

  let done = false;
  const finish = () => {
    if (done) return;
    done = true;
    sendUserMessage(transcript, "vocal");

    voiceCircle.classList.remove("done", "paused");
    voiceCircle.classList.add("thinking");
    voiceStatus.textContent = "Titi réfléchit...";
    disarmMic();
  };

  if (window.speechSynthesis) {
    const utterance = new SpeechSynthesisUtterance("Compris, j'envoie à Titi");
    utterance.lang = "fr-FR";
    utterance.onend = finish;
    utterance.onerror = finish;
    window.speechSynthesis.speak(utterance);
    setTimeout(finish, 3500);
  } else {
    setTimeout(finish, 800);
  }
}

const WHISPER_HALLUCINATIONS = [
  "sous-titres réalisés par la communauté d'amara.org",
  "sous-titrage st' 501",
  "merci d'avoir regardé cette vidéo",
  "abonnez-vous"
];

function isHallucination(text) {
  const lower = text.toLowerCase().trim();
  return WHISPER_HALLUCINATIONS.some((h) => lower.includes(h));
}

async function transcribeAudio(blob) {
  voiceStatus.textContent = "Transcription en cours...";
  try {
    const res = await fetch("/transcribe", {
      method: "POST",
      headers: { "Content-Type": blob.type || "application/octet-stream" },
      body: blob
    });
    const data = await res.json();

    if (!res.ok || !data.text || isHallucination(data.text)) {
      debugLog(`transcription vide/hallucination: ${JSON.stringify(data)}`);
      voiceStatus.textContent = recordMode === "auto"
        ? "Rien compris. Retouchez le cercle pour réessayer."
        : "Rien compris. Maintenez le micro appuyé pour réessayer.";
      voiceCircle.classList.remove("thinking", "paused");
      voiceCircle.classList.add("done");
      retryArmed = true;
      return;
    }

    confirmAndSend(data.text);
  } catch (err) {
    debugLog(`erreur transcription: ${err.message}`);
    voiceStatus.textContent = recordMode === "auto"
      ? "Erreur. Retouchez le cercle pour réessayer."
      : "Erreur. Maintenez le micro appuyé pour réessayer.";
    voiceCircle.classList.remove("thinking", "paused");
    voiceCircle.classList.add("done");
    retryArmed = true;
  }
}

function startVoiceCapture() {
  voiceCancelled = false;
  hasSpoken = false;
  retryArmed = false;

  if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
    openVoiceScreen();
    voiceStatus.textContent = "Micro non supporté sur ce navigateur.";
    debugLog("getUserMedia indisponible");
    setTimeout(closeVoiceScreen, 2000);
    return;
  }

  openVoiceScreen();

  const session = { id: ++sessionCounter, discard: false, stopped: false };
  currentSession = session;

  navigator.mediaDevices.getUserMedia({ audio: true })
    .then((stream) => {
      if (voiceCancelled || currentSession !== session || session.stopped) {
        stream.getTracks().forEach((t) => t.stop());
        return;
      }

      session.stream = stream;
      const mimeType = pickMimeType();
      const recorder = mimeType ? new MediaRecorder(stream, { mimeType }) : new MediaRecorder(stream);
      session.recorder = recorder;
      const chunks = [];

      recorder.ondataavailable = (e) => {
        if (e.data.size > 0) chunks.push(e.data);
      };

      recorder.onstop = () => {
        session.stopped = true;
        clearTimeout(session.silenceTimer);
        clearTimeout(session.maxDurationTimer);
        stream.getTracks().forEach((t) => t.stop());
        if (session.audioContext) session.audioContext.close().catch(() => {});
        armMic();

        if (session.discard || voiceCancelled) return;
        const blob = new Blob(chunks, { type: recorder.mimeType });
        transcribeAudio(blob);
      };

      recorder.start();
      debugLog(`enregistrement demarre (${recorder.mimeType})`);
      if (recordMode === "manual") setMicRecording();

      if (recordMode === "auto") {
        const AudioCtx = window.AudioContext || window.webkitAudioContext;
        const ctx = new AudioCtx();
        session.audioContext = ctx;
        const source = ctx.createMediaStreamSource(stream);
        const analyser = ctx.createAnalyser();
        analyser.fftSize = 512;
        source.connect(analyser);
        const data = new Uint8Array(analyser.frequencyBinCount);

        function checkVolume() {
          if (currentSession !== session || session.stopped) return;
          analyser.getByteTimeDomainData(data);
          let sum = 0;
          for (let i = 0; i < data.length; i++) {
            const v = (data[i] - 128) / 128;
            sum += v * v;
          }
          const rms = Math.sqrt(sum / data.length);

          if (rms > SPEECH_THRESHOLD) {
            hasSpoken = true;
            clearTimeout(session.silenceTimer);
            session.silenceTimer = setTimeout(() => {
              if (recorder.state === "recording") recorder.stop();
            }, SILENCE_MS);
          }

          requestAnimationFrame(checkVolume);
        }
        requestAnimationFrame(checkVolume);

        session.maxDurationTimer = setTimeout(() => {
          if (recorder.state === "recording") recorder.stop();
        }, MAX_DURATION_MS);
      }
    })
    .catch((err) => {
      debugLog(`getUserMedia refusé ou erreur: ${err.message}`);
      voiceStatus.textContent = "Micro refusé ou indisponible.";
      setTimeout(closeVoiceScreen, 2000);
    });
}

micBtn.addEventListener("click", () => {
  unlockAudioElement();
  askPushPermission();
  requestWakeLock();
  if (recordMode === "manual") {
    openVoiceScreen();
  } else {
    startVoiceCapture();
  }
});

micHold.addEventListener("pointerdown", (e) => {
  e.preventDefault();
  micHold.setPointerCapture(e.pointerId);
  if (recordMode === "manual") {
    if (!currentSession || currentSession.stopped) {
      unlockAudioElement();
      startVoiceCapture();
    }
  }
});

function stopManualRecording() {
  const s = currentSession;
  if (s && !s.stopped && s.recorder && s.recorder.state === "recording") {
    s.recorder.stop();
  }
}

micHold.addEventListener("pointerup", () => {
  if (recordMode === "manual") stopManualRecording();
});

micHold.addEventListener("pointercancel", () => {
  if (recordMode === "manual") stopManualRecording();
});

micHold.addEventListener("click", () => {
  if (recordMode === "auto" && retryArmed) startVoiceCapture();
});

modeBtn.addEventListener("click", () => {
  if (recordMode === "auto") {
    haltSession(currentSession);
    setRecordMode("manual");
    openVoiceScreen();
  } else {
    setRecordMode("auto");
    startVoiceCapture();
  }
});

function haltSession(session) {
  if (!session || session.stopped) return;
  session.discard = true;
  session.stopped = true;
  if (session.recorder && session.recorder.state === "recording") {
    session.recorder.stop();
  } else if (session.stream) {
    clearTimeout(session.silenceTimer);
    clearTimeout(session.maxDurationTimer);
    session.stream.getTracks().forEach((t) => t.stop());
    if (session.audioContext) session.audioContext.close().catch(() => {});
  }
}

voiceCancel.addEventListener("click", () => {
  voiceCancelled = true;
  haltSession(currentSession);
  if (currentAudio) {
    currentAudio.pause();
    currentAudio = null;
  }
  closeVoiceScreen();
});

restoreHistory();
requestAnimationFrame(() => { chat.scrollTop = chat.scrollHeight; });
connect();
requestWakeLock();
askPushPermission();
if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("/sw.js").catch((err) => {
    debugLog(`enregistrement service worker impossible: ${err.message}`);
  });
}
debugLog(`ua: ${navigator.userAgent} | secureContext: ${window.isSecureContext} | mediaDevices: ${!!navigator.mediaDevices}`);
