export const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
export const countries = ['pk', 'in', 'us', 'gb', 'ae'];
export const roomTypes = ['Living room', 'Bedroom', 'Gaming studio', 'Hall', 'Office', 'Dining room'];
export const styles = ['Modern vintage', 'Minimal', 'Japandi', 'Industrial', 'Bohemian', 'Luxury'];
export type Item = { id: string; label: string; category: string; query: string; x: number; y: number; width: number; height: number };
export function text(value: unknown, max: number): string {
  return typeof value === 'string' ? value.replace(/[\u0000-\u001f]/g, ' ').trim().slice(0, max) : '';
}
export function imageType(bytes: Uint8Array): string | null {
  if (bytes.length < 12) return null;
  if (bytes[0] === 255 && bytes[1] === 216 && bytes[2] === 255) return 'image/jpeg';
  if ([137,80,78,71,13,10,26,10].every((b,i) => bytes[i] === b)) return 'image/png';
  if (new TextDecoder().decode(bytes.slice(0,4)) === 'RIFF' && new TextDecoder().decode(bytes.slice(8,12)) === 'WEBP') return 'image/webp';
  return null;
}
export function safeUrl(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  try { const u = new URL(value); return u.protocol === 'https:' && !u.username && !u.password && u.hostname.includes('.') ? u.href : null; } catch { return null; }
}
export function normalizeItems(value: unknown): Item[] {
  if (!Array.isArray(value)) return [];
  const items: Item[] = [];
  for (const raw of value.slice(0,24)) {
    if (!raw || typeof raw !== 'object') continue;
    const { box_2d: box } = raw;
    if (!Array.isArray(box) || box.length !== 4 || !box.every(v => typeof v === 'number' && Number.isFinite(v))) continue;
    const [top,left,bottom,right] = box.map(v => Math.max(0, Math.min(1000,v)) / 1000);
    const label = text(raw.label,80), query = text(raw.query,180);
    if (!label || !query || right-left < .015 || bottom-top < .015) continue;
    items.push({id: crypto.randomUUID(),label,query,category:text(raw.category,40),x:left,y:top,width:right-left,height:bottom-top});
  }
  return items;
}
export function searchLinks(query: string, country: string) {
  const q = encodeURIComponent(query);
  const marketplace: Record<string,string> = {pk:'daraz.pk',in:'amazon.in',us:'amazon.com',gb:'amazon.co.uk',ae:'amazon.ae'};
  const domain = marketplace[country] ?? marketplace.pk;
  return [
    {title:'Google Shopping',url:`https://www.google.com/search?tbm=shop&q=${q}&gl=${country}`,kind:'search'},
    {title:`Search ${domain}`,url:`https://www.google.com/search?q=${encodeURIComponent(`site:${domain} ${query}`)}`,kind:'search'},
    {title:'Search all stores',url:`https://www.google.com/search?q=${q}`,kind:'search'},
  ];
}
export function validateCreate(body: Record<string,unknown>, user: string) {
  const id = text(body.id,36), title = text(body.title,90), type = text(body.roomType,40), style = text(body.style,40);
  const brief = text(body.brief,1200), country = text(body.country,2), source = text(body.sourcePath,160);
  if (!UUID.test(id) || !title || !roomTypes.includes(type) || !styles.includes(style) || !countries.includes(country) || !brief || body.consent !== true) throw Error('INVALID_INPUT');
  if (![`${user}/${id}/source.jpg`,`${user}/${id}/source.png`,`${user}/${id}/source.webp`].includes(source)) throw Error('INVALID_INPUT');
  return {id,title,type,style,brief,country,source};
}
export function base64(bytes: Uint8Array): string {
  let str = ''; for (let i=0; i<bytes.length; i+=32768) str += String.fromCharCode(...bytes.subarray(i,i+32768));
  return btoa(str);
}
