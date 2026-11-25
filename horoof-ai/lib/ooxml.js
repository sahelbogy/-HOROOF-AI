'use strict';
const yauzl=require('yauzl');
const {XMLParser}=require('fast-xml-parser');
const MAX_SELECTED_BYTES=20*1024*1024, MAX_ENTRIES=3000, MAX_SLIDES=200;
function decodeXml(text){return String(text).replace(/&(#x[0-9a-f]+|#[0-9]+|amp|lt|gt|quot|apos);/gi,(whole,entity)=>{const named={amp:'&',lt:'<',gt:'>',quot:'"',apos:"'"};if(entity[0]!=='#')return named[entity.toLowerCase()]||whole;let n=entity[1].toLowerCase()==='x'?parseInt(entity.slice(2),16):parseInt(entity.slice(1),10);return Number.isInteger(n)&&n>0&&n<=0x10ffff&&!(n>=0xd800&&n<=0xdfff)?String.fromCodePoint(n):whole})}
function textOfXml(xml,prefix){
  const parser=new XMLParser({preserveOrder:true,ignoreAttributes:true,processEntities:false});
  const parsed=parser.parse(xml);let fragments=[];
  function visit(node){if(!node||typeof node!=='object')return;if(Array.isArray(node)){for(const v of node)visit(v);return}for(const [key,val] of Object.entries(node)){if(key===prefix+':t'){if(Array.isArray(val)){for(const part of val)if(part&&typeof part['#text']!=='undefined')fragments.push(decodeXml(part['#text']))}else if(typeof val==='string')fragments.push(decodeXml(val))}else if(key!==':@')visit(val);if(key===prefix+':p')fragments.push('\n')}}
  visit(parsed);return fragments.join(' ').replace(/ *\n */g,'\n').replace(/\n{3,}/g,'\n\n').trim();
}
function extractOOXML(buffer,kind){return new Promise((resolve,reject)=>{
  if(!['docx','pptx'].includes(kind))return reject(Error('Unsupported document format.'));
  yauzl.fromBuffer(buffer,{lazyEntries:true,validateEntrySizes:true,strictFileNames:true},(err,zip)=>{
    if(err)return reject(Error('Invalid Office document archive.'));let done=false,seen=0,total=0,selected=[],types=false;
    function fail(message){if(done)return;done=true;zip.close();reject(Error(message))}
    zip.on('error',()=>fail('Invalid or unsafe Office document archive.'));
    zip.on('entry',entry=>{
      if(++seen>MAX_ENTRIES)return fail('Office document has too many archive entries.');
      let name=entry.fileName;if(name==='[Content_Types].xml')types=true;
      let selectedEntry=kind==='docx'?name==='word/document.xml':/^ppt\/slides\/slide[1-9]\d*\.xml$/.test(name);
      if(!selectedEntry)return zip.readEntry();
      if(selected.some(x=>x.name===name))return fail('Office document has duplicate parts.');
      if(kind==='pptx'&&selected.length>=MAX_SLIDES)return fail('Presentation exceeds the 200-slide limit.');
      total+=entry.uncompressedSize;
      if(total>MAX_SELECTED_BYTES||entry.uncompressedSize>MAX_SELECTED_BYTES||entry.uncompressedSize>Math.max(1024,entry.compressedSize)*100)return fail('Office document exceeds safe extraction limits.');
      zip.openReadStream(entry,(e,stream)=>{if(e)return fail('Unable to extract Office document.');let pieces=[],count=0;stream.on('error',()=>fail('Unable to extract Office document.'));stream.on('data',chunk=>{count+=chunk.length;if(count>entry.uncompressedSize||count>MAX_SELECTED_BYTES){stream.destroy();return fail('Office document exceeded extraction limits.')}pieces.push(chunk)});stream.on('end',()=>{if(done)return;selected.push({name,xml:Buffer.concat(pieces).toString('utf8')});zip.readEntry()})});
    });
    zip.on('end',()=>{if(done)return;done=true;if(!types||!selected.length)return reject(Error('Office document does not contain the expected content.'));try{selected.sort((a,b)=>Number((a.name.match(/slide(\d+)/)||[])[1]||0)-Number((b.name.match(/slide(\d+)/)||[])[1]||0));let pages=selected.map(p=>({page:kind==='pptx'?Number(p.name.match(/slide(\d+)/)[1]):null,text:textOfXml(p.xml,kind==='pptx'?'a':'w')}));if(!pages.some(p=>p.text.trim()))throw Error('No extractable text found in this document.');resolve(pages)}catch(e){reject(Error(e.message||'Office document extraction failed.'))}});
    zip.readEntry();
  });
})}
module.exports={extractOOXML,textOfXml};
