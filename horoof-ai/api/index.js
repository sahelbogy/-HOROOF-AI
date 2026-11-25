'use strict';
// Serverless entrypoint; deployment is still blocked on live integration,
// credential setup, content review, security and route validation.
const {createConfiguredApp}=require('../vercel-backend/app');
let app;
module.exports=(req,res)=>{try{if(!app)app=createConfiguredApp();return app(req,res)}catch(error){console.error('Server configuration unavailable:',error.message);res.statusCode=503;res.setHeader('Content-Type','application/json');res.end(JSON.stringify({error:'Server configuration is incomplete.'}))}};
