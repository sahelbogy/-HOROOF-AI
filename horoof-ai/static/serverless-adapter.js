(function(global){
'use strict';
function mapRequest(url,opts={}){
  let method=(opts.method||'GET').toUpperCase(),body=opts.body||{},match;
  if(['/register','/login','/logout'].includes(url))return {path:'/api/auth'+url,body};
  if(url==='/parties'&&method==='POST')return {path:'/api/game/rooms',body};
  if(url==='/parties/join')return {path:'/api/game/rooms/join',body};
  match=/^\/parties\/(HOR-[A-F0-9]{6,12})(?:\/(\w+))?(\?.*)?$/.exec(url);
  if(match){let code=match[1],action=match[2],query=match[3]||'';
    if(!action&&method==='GET')return {path:'/api/game/rooms/'+code+'/snapshot',body,kind:'snapshot'};
    if(action==='qr')return {path:'/api/game/rooms/'+code+'/qr'+query,body};
    if(['ready','team','leave'].includes(action))return {path:'/api/game/rooms/'+code+'/lobby',body:{action,...body}};
    if(action==='close')return {path:'/api/game/rooms/'+code+(opts.roomStatus==='playing'?'/end':'/lobby'),body:opts.roomStatus==='playing'?{}:{action:'close'}};
    if(action==='skip')return {path:'/api/game/rooms/'+code+'/reset',body};
    if(action==='select')return {path:'/api/game/rooms/'+code+'/select',body:{cell:body.index},kind:'action'};
    if(['start','buzz','answer'].includes(action))return {path:'/api/game/rooms/'+code+'/'+action,body,kind:action==='answer'?'action':undefined};
  }
  match=/^\/subjects\/(\d+)\/(documents|search)(\?.*)?$/.exec(url);
  if(match)return {path:'/api/docs/collections/'+match[1]+'/'+match[2]+(match[3]||''),body};
  match=/^\/documents\/(\d+)(?:\/(reprocess))?$/.exec(url);
  if(match)return {path:'/api/docs/documents/'+match[1]+(match[2]?'/'+match[2]:''),body};
  if(['/ai/generate','/ai/save'].includes(url))return {path:'/api'+url,body};
  match=/^\/documents\/(\d+)\/(generate|drafts)$/.exec(url);
  if(match)return {path:'/api/ai/documents/'+match[1]+'/'+match[2],body};
  match=/^\/drafts\/(\d+)\/review$/.exec(url);
  if(match)return {path:'/api/ai/drafts/'+match[1]+'/review',body};
  if(url==='/me')return {path:'/api/game/me',body,kind:'me'};
  if(['/subjects','/profile','/statistics/me','/leaderboard'].includes(url)||/^\/subjects\/\d+\/questions$/.test(url))return {path:'/api/game'+url,body};
  return {unsupported:true};
}
function mapResponse(kind,data){
 if(kind==='me')return {user:data};
 if(kind==='action')return data.result||{};
 if(kind==='snapshot'){
  let r=data.room,g=data.game;
  return {code:r.code,status:r.status,hostId:r.host_id,questionLanguage:r.question_language,boardAlphabet:r.board_alphabet,subject:{id:r.subject_id,name:r.subject_name},players:data.players.map(p=>({id:p.user_id,username:p.username||'Player',team:p.team,ready:p.ready,score:p.score})),game:g?{board:g.board,activeCell:g.active_cell,question:g.question_id?{id:g.question_id,letter:g.letter,question:g.question}:null,winnerUser:g.winner_user,answerDeadline:g.answer_deadline?Date.parse(g.answer_deadline):null,turnTeam:g.turn_team,round:g.round_version,result:g.result}:null};
 }
 return data;
}
const adapter={mapRequest,mapResponse};if(typeof module!=='undefined'&&module.exports)module.exports=adapter;else global.HoroofServerlessAdapter=adapter;
})(typeof window!=='undefined'?window:globalThis);
