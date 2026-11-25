const {test}=require('node:test'),assert=require('node:assert/strict');process.env.DB_PATH=':memory:';const {connected,db}=require('../server');
test('green wins by horizontal connected path',()=>{const b=Array.from({length:25},()=>({owner:null}));for(let i=0;i<5;i++)b[i].owner='green';assert.equal(connected(b,'green'),true);assert.equal(connected(b,'orange'),false)});
test('orange wins by vertical path using hex neighbors',()=>{const b=Array.from({length:25},()=>({owner:null}));for(let i=0;i<25;i+=5)b[i].owner='orange';assert.equal(connected(b,'orange'),true)});
test('disconnected letters do not win',()=>{const b=Array.from({length:25},()=>({owner:null}));[0,4,10,24].forEach(i=>b[i].owner='green');assert.equal(connected(b,'green'),false)});
test('seed supplies enough distinct letters for 5 by 5',()=>{assert.ok(db.prepare('select count(distinct letter) n from questions').get().n>=25)});
