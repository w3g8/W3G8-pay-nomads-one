// Web QR Scanner — browser camera API + jsQR
// Called from Flutter via JS interop

window._qrCallback = null;

function _setQRCallback(fn) {
  window._qrCallback = fn;
}

window._qrScanner = {
  stream: null,
  video: null,
  canvas: null,
  ctx: null,
  scanning: false,

  async start() {
    this.scanning = true;

    const container = document.getElementById('qr-scanner-container');
    if (!container) return false;

    // Clear previous
    container.innerHTML = '';

    // Create video element
    this.video = document.createElement('video');
    this.video.setAttribute('playsinline', '');
    this.video.setAttribute('autoplay', '');
    this.video.setAttribute('muted', '');
    this.video.style.width = '100%';
    this.video.style.height = '100%';
    this.video.style.objectFit = 'cover';
    container.appendChild(this.video);

    // Offscreen canvas for frame analysis
    this.canvas = document.createElement('canvas');
    this.ctx = this.canvas.getContext('2d', { willReadFrequently: true });

    try {
      this.stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: 'environment', width: { ideal: 1280 }, height: { ideal: 720 } }
      });
      this.video.srcObject = this.stream;
      await this.video.play();

      // Load jsQR if not already loaded
      if (!window.jsQR) {
        await new Promise((resolve, reject) => {
          const s = document.createElement('script');
          s.src = 'https://cdn.jsdelivr.net/npm/jsqr@1.4.0/dist/jsQR.min.js';
          s.onload = resolve;
          s.onerror = reject;
          document.head.appendChild(s);
        });
      }

      this._scanFrame();
      return true;
    } catch (e) {
      console.error('QR Scanner error:', e);
      return false;
    }
  },

  _scanFrame() {
    if (!this.scanning || !this.video) return;

    if (this.video.readyState === this.video.HAVE_ENOUGH_DATA) {
      this.canvas.width = this.video.videoWidth;
      this.canvas.height = this.video.videoHeight;
      this.ctx.drawImage(this.video, 0, 0, this.canvas.width, this.canvas.height);

      const imageData = this.ctx.getImageData(0, 0, this.canvas.width, this.canvas.height);

      if (window.jsQR) {
        const code = window.jsQR(imageData.data, imageData.width, imageData.height, {
          inversionAttempts: 'dontInvert',
        });

        if (code && code.data && window._qrCallback) {
          window._qrCallback(code.data);
          return; // Stop after detection
        }
      }
    }

    requestAnimationFrame(() => this._scanFrame());
  },

  stop() {
    this.scanning = false;
    if (this.stream) {
      this.stream.getTracks().forEach(t => t.stop());
      this.stream = null;
    }
    if (this.video && this.video.parentNode) {
      this.video.parentNode.removeChild(this.video);
      this.video = null;
    }
  }
};
