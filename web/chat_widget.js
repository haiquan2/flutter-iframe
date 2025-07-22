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

  let chatId = localStorage.getItem('chat_id');
  if (!chatId) {
    chatId = 'chat_' + Math.random().toString(36).substring(2, 10);
    localStorage.setItem('chat_id', chatId);
  }

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

  const iframe = document.createElement('iframe');
  iframe.src = `${config.widgetUrl}/?iframe=true&chatId=${chatId}&theme=${config.theme}&v=${Date.now()}`;
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
  iframe.allow = 'clipboard-write; camera; microphone';

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

  // Create modal for image preview
  const modal = document.createElement('div');
  modal.style.display = 'none';
  modal.style.position = 'fixed';
  modal.style.top = '0';
  modal.style.left = '0';
  modal.style.width = '100%';
  modal.style.height = '100%';
  modal.style.backgroundColor = 'rgba(0,0,0,0.8)';
  modal.style.zIndex = '10000';
  modal.style.alignItems = 'center';
  modal.style.justifyContent = 'center';

  const modalContent = document.createElement('div');
  modalContent.style.position = 'relative';
  modalContent.style.maxWidth = '90%';
  modalContent.style.maxHeight = '90%';
  modalContent.style.backgroundColor = 'white';
  modalContent.style.borderRadius = '12px';
  modalContent.style.overflow = 'hidden';

  const modalImage = document.createElement('img');
  modalImage.style.maxWidth = '100%';
  modalImage.style.maxHeight = '100%';
  modalImage.style.objectFit = 'contain';

  const closeButton = document.createElement('div');
  closeButton.style.position = 'absolute';
  closeButton.style.top = '10px';
  closeButton.style.right = '10px';
  closeButton.style.padding = '8px';
  closeButton.style.backgroundColor = 'rgba(0,0,0,0.6)';
  closeButton.style.borderRadius = '50%';
  closeButton.style.cursor = 'pointer';
  closeButton.innerHTML = '<svg width="24" height="24" fill="white" viewBox="0 0 24 24"><path d="M12 10.586l4.95-4.95 1.414 1.414-4.95 4.95 4.95 4.95-1.414 1.414-4.95-4.95-4.95 4.95-1.414-1.414 4.95-4.95-4.95-4.95L6.464 6.05l4.95 4.95z"/></svg>';

  closeButton.onclick = () => {
    modal.style.display = 'none';
  };

  modalContent.appendChild(modalImage);
  modalContent.appendChild(closeButton);
  modal.appendChild(modalContent);
  document.body.appendChild(modal);

  // Listen for messages from iframe to show image
  window.addEventListener('message', (event) => {
    if (event.origin !== config.widgetUrl) return;
    if (event.data.type === 'showImage') {
      modalImage.src = event.data.imageSrc;
      modal.style.display = 'flex';
    }
  });

  window.addEventListener('resize', adjustIframeSize);
  document.body.appendChild(button);
  document.body.appendChild(iframe);
  adjustIframeSize();
})();