import { imageType, normalizeItems, safeUrl, searchLinks, validateCreate } from './core.ts';
const check = (value: unknown, message='Assertion failed') => { if(!value) throw Error(message); };
Deno.test('Gemini y-x boxes are normalized, clamped, and degenerate objects rejected',()=>{
  const items = normalizeItems([{label:'Sofa',query:'olive sofa',box_2d:[100,200,800,900]},{label:'bad',query:'x',box_2d:[900,400,200,800]},{label:'Lamp',query:'brass lamp',box_2d:[-20,800,600,1100]}]);
  check(items.length===2); check(items[0].x===.2 && items[0].y===.1); check(Math.abs(items[0].width-.7)<.0001); check(items[1].x+items[1].width===1);
});
Deno.test('Untrusted links reject scripts, HTTP and embedded credentials',()=>{
  check(safeUrl('javascript:alert(1)')===null);check(safeUrl('http://shop.example/a')===null);check(safeUrl('https://x:y@shop.example')===null);check(safeUrl('https://shop.example/item')!==null);
});
Deno.test('Search links encode text without letting it modify the host',()=>{
  const links=searchLinks('chair & q=other #red','pk'); const u=new URL(links[0].url);
  check(u.hostname==='www.google.com'); check(u.searchParams.get('q')==='chair & q=other #red');check(new URL(links[1].url).searchParams.get('q')?.startsWith('site:daraz.pk '));
});
Deno.test('Uploads cannot reference another owner and consent is mandatory',()=>{
  const user='11111111-1111-4111-8111-111111111111', id='22222222-2222-4222-8222-222222222222';
  const good={id,title:'Room',roomType:'Living room',style:'Modern vintage',brief:'Warm lighting',country:'pk',sourcePath:`${user}/${id}/source.jpg`,consent:true};
  check(validateCreate(good,user).id===id);
  for (const bad of [{...good,sourcePath:`other/${id}/source.jpg`},{...good,consent:false},{...good,country:'zz'}]) {let threw=false;try{validateCreate(bad,user);}catch{threw=true;}check(threw);}
});
Deno.test('File magic is checked independently of a filename',()=>{
  check(imageType(new Uint8Array([255,216,255,0,0,0,0,0,0,0,0,0]))==='image/jpeg');check(imageType(new TextEncoder().encode('<html>not an image</html>'))===null);
});
