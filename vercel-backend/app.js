'use strict';
const express=require('express'),path=require('path'),fs=require('fs'),helmet=require('helmet');
const {Pool}=require('pg');const {poolConfig}=require('./db-config');const {createAiApi,createOpenAiProvider}=require('./ai-api');const {createDocumentsApi}=require('./documents-api');const {createGameApi}=require('./game-api');const {createAuthApi,makeProvider}=require('./auth-api');
function createServerlessApp({db,verifyToken,provider,aiProvider=null,aiModel}){
 const app=express();app.disable('x-powered-by');
 // No inline scripts: allow the same-origin application bundle only. Inline styles
 // are currently needed by the UI; generated QR images use data URLs.
 app.use(helmet({frameguard:false,crossOriginEmbedderPolicy:false,contentSecurityPolicy:{useDefaults:false,directives:{defaultSrc:["'self'"],scriptSrc:["'self'"],styleSrc:["'self'","'unsafe-inline'",'https://fonts.googleapis.com'],fontSrc:["'self'",'https://fonts.gstatic.com'],imgSrc:["'self'",'data:'],connectSrc:["'self'"],objectSrc:["'none'"],baseUri:["'none'"],formAction:["'self'"]}}}));
 app.use('/api',(req,res,next)=>{res.set('Cache-Control','no-store');res.vary('Authorization');next()});
 app.use('/api/auth',createAuthApi({provider,db}));
 app.use('/api/game',createGameApi({db,verifyToken}));
 app.use('/api/docs',createDocumentsApi({db,verifyToken}));
 app.use('/api/ai',createAiApi({db,verifyToken,provider:aiProvider,model:aiModel}));
 app.use('/api',(req,res)=>res.status(501).json({error:'This feature is not yet available in the serverless version.'}));
 const dir=path.join(__dirname,'../static');
 app.get('/',(req,res)=>{let html=fs.readFileSync(path.join(dir,'index.html'),'utf8').replace('<script src="/socket.io/socket.io.js"></script>','<script src="/serverless-mode.js"></script>');res.set('Cache-Control','no-store').type('html').send(html)});
 app.use(express.static(dir,{index:false}));return app;
}
function createConfiguredApp(){
 const {DATABASE_URL,SUPABASE_URL,SUPABASE_ANON_KEY}=process.env;if(!DATABASE_URL||!SUPABASE_URL||!SUPABASE_ANON_KEY)throw Error('Missing server-side configuration.');
 const url=new URL(SUPABASE_URL);if(url.protocol!=='https:'||!url.hostname.endsWith('.supabase.co'))throw Error('Invalid Supabase URL.');
 const db=new Pool(poolConfig(DATABASE_URL));
 async function verifyToken(token){const response=await fetch(url.origin+'/auth/v1/user',{headers:{apikey:SUPABASE_ANON_KEY,authorization:'Bearer '+token},signal:AbortSignal.timeout(5000)});if([401,403].includes(response.status))return null;if(!response.ok)throw Error('Authentication provider unavailable.');return response.json()}
 return createServerlessApp({db,verifyToken,provider:makeProvider(url.origin,SUPABASE_ANON_KEY),aiProvider:createOpenAiProvider(process.env.OPENAI_API_KEY),aiModel:process.env.OPENAI_MODEL});
}
module.exports={createServerlessApp,createConfiguredApp};
