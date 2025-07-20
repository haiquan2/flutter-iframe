(function () {
  const scriptTag = document.currentScript;

  const buttonColor = scriptTag.dataset.buttonColor || '#6366F1';
  const iframeWidth = scriptTag.dataset.iframeWidth || '400';
  const iframeHeight = scriptTag.dataset.iframeHeight || '600';
  const widgetUrl = scriptTag.dataset.widgetUrl || 'https://flutter-iframe.vercel.app';

  // ✅ B1. Tạo hoặc lấy chatId từ localStorage
  let chatId = localStorage.getItem('chat_id');
  if (!chatId) {
    chatId = 'chat_' + Math.random().toString(36).substring(2, 10);
    localStorage.setItem('chat_id', chatId);
  }

  // ✅ B2. Tạo nút chat nổi
  const button = document.createElement('div');
  button.style.position = 'fixed';
  button.style.bottom = '24px';
  button.style.right = '24px';
  button.style.width = '60px';
  button.style.height = '60px';
  button.style.backgroundColor = buttonColor;
  button.style.borderRadius = '50%';
  button.style.boxShadow = '0 4px 12px rgba(0,0,0,0.1)';
  button.style.cursor = 'pointer';
  button.style.zIndex = '9999';
  button.style.display = 'flex';
  button.style.alignItems = 'center';
  button.style.justifyContent = 'center';
  button.innerHTML = `
    <svg fill="white" width="28" height="28" viewBox="0 0 24 24">
      <path d="M2 21l1.5-5.5c-1.33-1.44-2-3.28-2-5.5
        0-4.42 3.58-8 8-8s8 3.58 8 8-3.58 8-8 8c-2.22
        0-4.06-.84-5.5-2L2 21z"/>
    </svg>`;

  // ✅ B3. Tạo iframe ẩn
  const iframe = document.createElement('iframe');
  iframe.src = `${widgetUrl}/?iframe=true&chatId=${chatId}`;
  iframe.style.position = 'fixed';
  iframe.style.bottom = '24px';
  iframe.style.right = '24px';
  iframe.style.width = '0px';
  iframe.style.height = '0px';
  iframe.style.border = 'none';
  iframe.style.borderRadius = '12px';
  iframe.style.zIndex = '9998';
  iframe.style.transition = 'all 0.3s ease';
  iframe.style.backgroundColor = 'white';
  iframe.allow = 'clipboard-write';

  // ✅ B4. Toggle mở/đóng iframe
  let isOpen = false;
  button.onclick = () => {
    isOpen = !isOpen;
    iframe.style.width = isOpen ? `${iframeWidth}px` : '0px';
    iframe.style.height = isOpen ? `${iframeHeight}px` : '0px';
  };

  // ✅ B5. Gắn vào DOM
  document.body.appendChild(button);
  document.body.appendChild(iframe);
})();
