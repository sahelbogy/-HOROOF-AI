'use strict';
const fs=require('fs'),path=require('path');
// Public Supabase Root 2021 CA: downloaded from Supabase's official SSL distribution.
// Rotate this before its 2031 expiry, following Supabase's published guidance.
function poolConfig(connectionString){
 if(typeof connectionString!=='string'||!connectionString)throw Error('DATABASE_URL is required.');
 let url;try{url=new URL(connectionString)}catch{throw Error('Invalid database URL.')}
 if(!['postgres:','postgresql:'].includes(url.protocol))throw Error('Invalid database protocol.');
 const host=url.hostname.toLowerCase();const supabase=host.endsWith('.pooler.supabase.com')||host.endsWith('.supabase.co');
 if(!supabase&&!['localhost','127.0.0.1','::1','[::1]'].includes(host))throw Error('Unsupported database host.');
 const securityParameters=['ssl','sslcert','sslkey','sslrootcert','sslnegotiation','uselibpqcompat'];
 if(securityParameters.some(p=>url.searchParams.has(p)))throw Error('Configure TLS through the application, not the database URL.');
 let modes=url.searchParams.getAll('sslmode');if(modes.length>1||modes.some(x=>!['require','verify-full','verify-ca'].includes(x)))throw Error('Insecure or ambiguous database TLS mode.');
 url.searchParams.delete('sslmode');
 const config={connectionString:url.toString(),max:2,connectionTimeoutMillis:5000,idleTimeoutMillis:10000};
 if(supabase)config.ssl={ca:fs.readFileSync(path.join(__dirname,'../certs/supabase-root-2021.crt'),'utf8'),rejectUnauthorized:true};
 return config;
}
module.exports={poolConfig};
