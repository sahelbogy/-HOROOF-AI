'use strict';
const fs=require('fs/promises'),os=require('os'),path=require('path'),{execFile}=require('child_process'),{promisify}=require('util');
const run=promisify(execFile);let busy=false;
// Local OCR: untrusted PDFs should be processed inside a hardened sandbox in production.
async function ocrPdf(buffer,pages){
 if(process.env.OCR_ENABLED!=='1')throw Error('This PDF contains pages with no extractable text. OCR is not enabled on the server.');
 if(!Array.isArray(pages)||pages.length>10)throw Error('OCR supports at most 10 image-only pages per document.');
 if(busy)throw Error('OCR is busy. Please retry this document shortly.');
 const languages=process.env.OCR_LANGUAGES||'ara+fra+eng';if(!/^[A-Za-z0-9_+]{1,80}$/.test(languages))throw Error('OCR language configuration is invalid.');
 busy=true;let dir;
 try{
  dir=await fs.mkdtemp(path.join(os.tmpdir(),'horoof-ocr-'));const input=path.join(dir,'document.pdf');await fs.writeFile(input,buffer,{mode:0o600});let result=[];
  for(const n of pages){if(!Number.isInteger(n)||n<1||n>50)throw Error('Invalid PDF page number.');let prefix=path.join(dir,'page-'+n);await run('pdftoppm',['-f',String(n),'-l',String(n),'-singlefile','-scale-to','2000','-png',input,prefix],{timeout:30000,maxBuffer:1024*1024});let o=await run('tesseract',[prefix+'.png','stdout','-l',languages,'--psm','3'],{timeout:45000,maxBuffer:4*1024*1024});result.push({page:n,text:o.stdout.trim()})}
  return result;
 }catch(e){if(e.code==='ENOENT')throw Error('OCR tools are not installed. Install Tesseract, language packs and Poppler.');if(e.killed||e.signal)throw Error('OCR exceeded its processing time limit.');throw Error('OCR failed. Check the document and installed OCR language packs.');}
 finally{if(dir)await fs.rm(dir,{recursive:true,force:true}).catch(()=>{});busy=false}
}
module.exports={ocrPdf};
