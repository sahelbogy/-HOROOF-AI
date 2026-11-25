'use strict';
const AR=Array.from('ابتثجحخدذرزسشصضطظعغفقكلمنهوي'),FR=Array.from('ABCDEFGHIJKLMNOPQRSTUVWXYZ');
function alphabet(code){return code==='ar'?AR:code==='fr'?FR:null}
function canonicalLetter(value){if(typeof value!=='string')return null;let v=value.trim().toUpperCase();return AR.includes(v)||FR.includes(v)?v:null}
function startsWithLetter(answer,letter){if(typeof answer!=='string')return false;let a=answer.trim();return FR.includes(letter)?a.normalize('NFD').replace(/[\u0300-\u036f]/g,'').toUpperCase().startsWith(letter):a.startsWith(letter)}
module.exports={alphabet,canonicalLetter,startsWithLetter,AR,FR};
