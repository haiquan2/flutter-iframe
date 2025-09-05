(function () {
  const scriptTag = document.currentScript;

  const config = {
    widgetUrl: scriptTag.dataset.widgetUrl || 'http://localhost:5000/',
    buttonColor: scriptTag.dataset.buttonColor || '#6366F1',
    buttonSize: parseInt(scriptTag.dataset.buttonSize) || 60,
    iframeWidth: parseInt(scriptTag.dataset.iframeWidth) || 400,
    iframeHeight: parseInt(scriptTag.dataset.iframeHeight) || 600,
    theme: scriptTag.dataset.theme || 'dark',
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

  // Create iframe container to better control events
  const iframeContainer = document.createElement('div');
  iframeContainer.style.position = 'fixed';
  iframeContainer.style.bottom = '24px';
  iframeContainer.style.right = '24px';
  iframeContainer.style.width = '1px';
  iframeContainer.style.height = '1px';
  iframeContainer.style.zIndex = '9998';
  iframeContainer.style.transition = 'all 0.3s ease';
  iframeContainer.style.overflow = 'hidden';
  iframeContainer.style.borderRadius = '12px';
  iframeContainer.style.boxShadow = '2px 4px 12px rgba(0,0,0,0.2)';

  const iframe = document.createElement('iframe');
  iframe.src = `${config.widgetUrl}/?iframe=true`;
  iframe.style.width = '100%';
  iframe.style.height = '100%';
  iframe.style.border = 'none';
  iframe.style.borderRadius = '12px';
  iframe.style.backgroundColor = 'white';
  iframe.allow = 'clipboard-write; camera; microphone';

  iframeContainer.appendChild(iframe);

  let isOpen = false;
  let isMouseOverIframe = false;
  let originalOverflow = null;
  let iframeSrc = config.widgetUrl;
  if (iframeSrc.includes('?')) {
    iframeSrc += `&iframe=true&theme=${config.theme}`;
  } else {
    iframeSrc += `?iframe=true&theme=${config.theme}`;
  }
  iframe.src = iframeSrc;


  // Track mouse position relative to iframe
  function updateMousePosition(event) {
    if (!isOpen) return;
    
    const rect = iframeContainer.getBoundingClientRect();
    const isInside = (
      event.clientX >= rect.left &&
      event.clientX <= rect.right &&
      event.clientY >= rect.top &&
      event.clientY <= rect.bottom
    );
    
    if (isInside !== isMouseOverIframe) {
      isMouseOverIframe = isInside;
      toggleBodyScroll();
    }
  }

  function toggleBodyScroll() {
    if (isMouseOverIframe && isOpen) {
      // Disable parent page scrolling
      if (originalOverflow === null) {
        originalOverflow = document.body.style.overflow;
      }
      document.body.style.overflow = 'hidden';
      
      // Send message to iframe to enable scrolling
      iframe.contentWindow?.postMessage({
        type: 'enable_scroll',
        enabled: true
      }, config.widgetUrl);
    } else {
      // Re-enable parent page scrolling
      if (originalOverflow !== null) {
        document.body.style.overflow = originalOverflow;
      }
      
      // Send message to iframe to handle scroll appropriately
      iframe.contentWindow?.postMessage({
        type: 'enable_scroll',
        enabled: false
      }, config.widgetUrl);
    }
  }

  // Enhanced wheel event handling
  function handleWheelEvent(event) {
    if (!isOpen || !isMouseOverIframe) return;
    
    // Prevent parent page from scrolling when mouse is over iframe
    event.preventDefault();
    event.stopPropagation();
    
    // Forward the wheel event to iframe
    iframe.contentWindow?.postMessage({
      type: 'wheel_event',
      deltaX: event.deltaX,
      deltaY: event.deltaY,
      deltaZ: event.deltaZ
    }, config.widgetUrl);
  }

  function adjustIframeSize() {
    const maxWidth = window.innerWidth > 500 ? config.iframeWidth : window.innerWidth - 48;
    const maxHeight = window.innerHeight > 700 ? config.iframeHeight : window.innerHeight - 100;
    
    if (isOpen) {
      iframeContainer.style.width = `${Math.min(maxWidth, config.iframeWidth)}px`;
      iframeContainer.style.height = `${Math.min(maxHeight, config.iframeHeight)}px`;
      iframeContainer.style.bottom = `${config.buttonSize + 28}px`;
    } else {
      iframeContainer.style.width = '0px';
      iframeContainer.style.height = '0px';
      iframeContainer.style.bottom = '24px';
      
      // Reset scroll state when closing
      if (originalOverflow !== null) {
        document.body.style.overflow = originalOverflow;
        originalOverflow = null;
      }
      isMouseOverIframe = false;
    }
  }

  button.onclick = () => {
    isOpen = !isOpen;
    adjustIframeSize();
    
    if (!isOpen) {
      // Reset all scroll states when closing
      toggleBodyScroll();
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

  // Event listeners
  document.addEventListener('mousemove', updateMousePosition, { passive: true });
  document.addEventListener('wheel', handleWheelEvent, { passive: false });

  // Listen for messages from iframe
  window.addEventListener('message', (event) => {
    if (event.origin !== config.widgetUrl) return;
    
    if (event.data.type === 'showImage') {
      modalImage.src = event.data.imageSrc;
      modal.style.display = 'flex';
    }
    
    if (event.data.type === 'iframe_ready') {
      // console.log('Iframe ready:', event.data.chatId);
    }
    
    if (event.data.type === 'scroll_request') {
      // Handle scroll requests from iframe
      window.scrollBy(event.data.deltaX || 0, event.data.deltaY || 0);
    }
  });

  // Handle window events
  window.addEventListener('resize', adjustIframeSize);
  
  // Clean up when page unloads
  window.addEventListener('beforeunload', () => {
    if (originalOverflow !== null) {
      document.body.style.overflow = originalOverflow;
    }
  });

  document.body.appendChild(button);
  document.body.appendChild(iframeContainer);
  adjustIframeSize();
})();