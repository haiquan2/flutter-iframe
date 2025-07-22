(function () {
  const scriptTag = document.currentScript;

  const config = {
    widgetUrl: scriptTag.dataset.widgetUrl || 'http://localhost:50257',
    buttonColor: scriptTag.dataset.buttonColor || '#6366F1',
    buttonSize: parseInt(scriptTag.dataset.buttonSize) || 60,
    iframeWidth: parseInt(scriptTag.dataset.iframeWidth) || 400,
    iframeHeight: parseInt(scriptTag.dataset.iframeHeight) || 600,
    theme: scriptTag.dataset.theme || 'light',
    buttonIcon: scriptTag.dataset.buttonIcon || '💬',
  };

  // Generate or retrieve chatId
  let chatId = localStorage.getItem('chat_id');
  if (!chatId) {
    chatId = 'chat_' + Math.random().toString(36).substring(2, 10);
    localStorage.setItem('chat_id', chatId);
  }

  // Create floating button
  const button = document.createElement('div');
  button.style.position = 'fixed';
  button.style.bottom = '24px';
  button.style.right = '24px';
  button.style.width = `${config.buttonSize}px`;
  button.style.height = `${config.buttonSize}px`;
  button.style.backgroundColor = config.buttonColor;
  button.style.borderRadius = '50%';
  button.style.boxShadow = '0 4px 12px rgba(0,0,0,0.1)';
  button.style.cursor = 'pointer';
  button.style.zIndex = '9999';
  button.style.display = 'flex';
  button.style.alignItems = 'center';
  button.style.justifyContent = 'center';
  button.innerHTML = `<span style="font-size: 24px; color: white;">${config.buttonIcon}</span>`;

  // Create iframe
  const iframe = document.createElement('iframe');
  iframe.src = `${config.widgetUrl}/?iframe=true&chatId=${chatId}&theme=${config.theme}`;
  iframe.style.position = 'fixed';
  iframe.style.bottom = '24px';
  iframe.style.right = '24px';
  iframe.style.width = '0px';
  iframe.style.height = '0px';
  iframe.style.border = 'none';
  iframe.style.boxShadow = '2px 4px 12px rgba(0,0,0,0.2)';
  iframe.style.borderRadius = '12px';
  iframe.style.zIndex = '9998';
  iframe.style.transition = 'all 0.3s ease';
  iframe.style.backgroundColor = 'white';
  iframe.allow = 'clipboard-write';

  function adjustIframeSize() {
    const maxWidth = window.innerWidth > 500 ? config.iframeWidth : window.innerWidth - 48;
    const maxHeight = window.innerHeight > 700 ? config.iframeHeight : window.innerHeight - 100;
    if (isOpen) {
      iframe.style.width = `${Math.min(maxWidth, config.iframeWidth)}px`;
      iframe.style.height = `${Math.min(maxHeight, config.iframeHeight)}px`;
    }
  }

  let isOpen = false;
  button.onclick = () => {
    isOpen = !isOpen;
    if (isOpen) {
      adjustIframeSize();
      iframe.style.bottom = `${config.buttonSize + 28}px`;
    } else {
      iframe.style.width = '0px';
      iframe.style.height = '0px';
      iframe.style.bottom = '24px';
    }
  };

  window.addEventListener('resize', adjustIframeSize);
  // Append to DOM
  document.body.appendChild(button);
  document.body.appendChild(iframe);
  adjustIframeSize();
})();