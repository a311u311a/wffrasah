/*
  Run this in Chrome DevTools Console while an Omolaat store page is open.
  It copies a JSON payload that can be imported with:

    node tool/import_omolaat_payload.mjs /path/to/payload.json
*/

(() => {
  const clean = (value) => String(value ?? '').replace(/\s+/g, ' ').trim();
  const pageText = clean(document.body.innerText);
  const lines = document.body.innerText
    .split('\n')
    .map(clean)
    .filter(Boolean);

  const readAfterLabel = (label) => {
    const index = lines.findIndex((line) => line.includes(label));
    if (index === -1) return '';
    return lines[index + 1] || '';
  };

  const firstMatch = (...patterns) => {
    for (const pattern of patterns) {
      const match = pageText.match(pattern);
      if (match?.[1]) return clean(match[1]);
    }
    return '';
  };

  const isStoreName = (value) => {
    const text = clean(value);
    if (!text) return false;
    if (/[./]/.test(text)) return false;
    if (text.length > 40) return false;
    if (/^(رابط المتجر|التصنيف|نبذة عن المتجر|كوبوناتي|تحت التفعيل)$/.test(text)) {
      return false;
    }
    return /[\u0600-\u06FF]/.test(text);
  };

  const isEnglishText = (value) => /^[\x00-\x7F\s.,:;'"!?%&()/-]+$/.test(clean(value));

  const selectedStore =
    document.querySelector('[role="combobox"]')?.innerText ||
    document.querySelector('button[aria-haspopup="listbox"]')?.innerText ||
    '';

  const storeLinkIndex = lines.findIndex((line) => line.includes('رابط المتجر'));
  const nearbyStoreName =
    storeLinkIndex >= 0
      ? lines
          .slice(Math.max(0, storeLinkIndex - 8), storeLinkIndex)
          .reverse()
          .find(isStoreName) || ''
      : '';
  const selectedStoreName = isStoreName(selectedStore)
    ? clean(selectedStore).split(' ')[0]
    : '';
  const storeName =
    selectedStoreName ||
    nearbyStoreName ||
    firstMatch(/متجر\s+([^\s]+)/) ||
    '';
  const storeUrl = firstMatch(
    /([a-z0-9-]+\.[a-z]{2,}(?:\/[^\s]*)?)/i,
  );
  const readCouponCode = () => {
    const direct = firstMatch(
      /كوبوناتي المسجلة\s*\(\d+\)\s*([A-Z0-9_-]+)/i,
      /([A-Z]{2,}[A-Z0-9_-]*)\s*تحت التفعيل/i,
    );
    if (direct) return direct;

    const activeIndex = lines.findIndex((line) => line.includes('تحت التفعيل'));
    const windowText = lines
      .slice(Math.max(0, activeIndex - 4), activeIndex + 4)
      .join(' ');
    const match = windowText.match(/\b([A-Z]{2,}[A-Z0-9_-]{2,})\b/i);
    return match?.[1] || '';
  };

  const couponCode = readCouponCode();
  const discount = firstMatch(/خصم الكوبون\s*([0-9٠-٩]+%)/);
  const category = readAfterLabel('التصنيف');
  const storeDescription = readAfterLabel('نبذة عن المتجر');
  const expiryDate = firstMatch(/تاريخ الانتهاء\s*([0-9]{4}-[0-9]{2}-[0-9]{2})/);
  const payload = {
    coupons: [
      {
        store_id: storeName ? storeName.toLowerCase().replace(/\s+/g, '-') : '',
        store_name_ar: storeName,
        store_name_en: isEnglishText(storeName) ? storeName : '',
        store_description_ar: storeDescription,
        store_description_en: isEnglishText(storeDescription) ? storeDescription : '',
        store_image: '',
        category_name: category,
        code: couponCode,
        discount,
        web: storeUrl ? `https://${storeUrl.replace(/^https?:\/\//, '')}` : '',
        affiliate_url: '',
        expiry_date: expiryDate || null,
        tags: category ? [category] : [],
      },
    ],
  };

  const json = JSON.stringify(payload, null, 2);
  try {
    copy(json);
  } catch (_) {
    // Chrome may block clipboard access in some DevTools contexts.
  }

  const blob = new Blob([json], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `omolaat-${payload.coupons[0]?.store_id || 'payload'}.json`;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);

  console.log('Omolaat payload:', json);
  console.log('Omolaat payload download started:', payload);
})();
