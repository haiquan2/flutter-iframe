(function () {
  // Get configuration from script tag
  const script = document.currentScript;
  const config = {
    apiUrl: script.getAttribute('data-api-url') || 'flutter-iframe.vercel.app',
    buttonColor: script.getAttribute('data-button-color') || '#6366F1',
    buttonSize: parseInt(script.getAttribute('data-button-size')) || 60,
    iframeWidth: parseInt(script.getAttribute('data-iframe-width')) || 400,
    iframeHeight: parseInt(script.getAttribute('data-iframe-height')) || 600,
    buttonIcon: script.getAttribute('data-button-icon') || '💬',
  };

  // Create floating button
  const button = document.createElement('div');
  button.style.position = 'fixed';
  button.style.bottom = '20px';
  button.style.right = '20px';
  button.style.width = `${config.buttonSize}px`;
  button.style.height = `${config.buttonSize}px`;
  button.style.backgroundColor = config.buttonColor;
  button.style.borderRadius = '50%'; // Always circular
  button.style.display = 'flex';
  button.style.alignItems = 'center';
  button.style.justifyContent = 'center';
  button.style.cursor = 'pointer';
  button.style.boxShadow = '0 4px 8px rgba(0,0,0,0.2)';
  button.style.zIndex = '10000';
  button.innerHTML = `<span style="font-size: 24px;">${config.buttonIcon}</span>`;
  document.body.appendChild(button);

  // Create iframe container
  const iframeContainer = document.createElement('div');
  iframeContainer.style.position = 'fixed';
  iframeContainer.style.bottom = `${config.buttonSize + 30}px`;
  iframeContainer.style.right = '20px';
  iframeContainer.style.width = `${config.iframeWidth}px`;
  iframeContainer.style.height = `${config.iframeHeight}px`;
  iframeContainer.style.display = 'none';
  iframeContainer.style.zIndex = '10001';
  iframeContainer.style.boxShadow = '0 4px 16px rgba(0,0,0,0.3)';
  iframeContainer.style.borderRadius = '8px';
  iframeContainer.style.overflow = 'hidden';
  iframeContainer.style.backgroundColor = '#FFFFFF';
  document.body.appendChild(iframeContainer);

  // Create iframe
  const iframe = document.createElement('iframe');
  iframe.src = config.apiUrl;
  iframe.style.width = '100%';
  iframe.style.height = '100%';
  iframe.style.border = 'none';
  iframe.allow = 'clipboard-write';
  iframeContainer.appendChild(iframe);

  // Toggle iframe visibility
  let isOpen = false;
  button.addEventListener('click', () => {
    isOpen = !isOpen;
    iframeContainer.style.display = isOpen ? 'block' : 'none';
    button.style.backgroundColor = isOpen ? '#FF4444' : config.buttonColor;
    button.innerHTML = `<span style="font-size: 24px;">${isOpen ? '✖' : config.buttonIcon}</span>`;
  });

  // Handle window resize to keep iframe responsive
  window.addEventListener('resize', () => {
    const maxWidth = Math.min(config.iframeWidth, window.innerWidth - 40);
    const maxHeight = Math.min(config.iframeHeight, window.innerHeight - config.buttonSize - 50);
    iframeContainer.style.width = `${maxWidth}px`;
    iframeContainer.style.height = `${maxHeight}px`;
  });
})();