<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="false"%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Painel Contábil</title>
<!--
  DASHBOARD HTML5 - PAINEL CONTABIL (AGRISAN)
  - HUB DE ACESSO AOS DASHBOARDS DA CONTABILIDADE (SUBSTITUI O DASHBOARD 343 EM XML)
  - CLIQUE NO CARTAO: ABRE O DASHBOARD NO SANKHYA ("/mge/system.jsp#app/" + Base64(RESOURCE-ID))
  - CTRL/SHIFT + CLIQUE OU BOTAO DO MEIO: ABRE EM NOVA ABA DO NAVEGADOR
  - BUSCA (ATALHO "/") E FILTRO POR GRUPO; "ACESSADOS RECENTEMENTE" GUARDADO NO NAVEGADOR (localStorage)
  - PARA INCLUIR UM DASHBOARD NOVO: ADICIONAR UMA LINHA NA LISTA "PAINEIS" ABAIXO (nuDsb = CODIGO DO DASHBOARD)
    E PREENCHER inc:'AAAA-MM-DD' COM A DATA DA INCLUSAO -> O SELO "NOVO" APARECE POR DIAS_NOVO (90) DIAS E SOME SOZINHO
  - ESCONDE A MOLDURA NATIVA DO GADGET (BARRA DE TITULO/ICONES, MENU DE IMPRESSAO E BARRA LATERAL DE FILTROS):
    O IFRAME DO HTML5 E ESTICADO SOBRE A TELA DO GADGET (VER esconderMolduraSankhya)
  OBS: NAO USAR TEMPLATE LITERALS COM CIFRAO+CHAVE NO JS (O JSP INTERPRETA COMO EL).
-->
<style>
  :root{
    --bg:#f3f5f8; --card:#ffffff; --line:#e4e8ee; --line-soft:#eef1f5;
    --text:#1d2633; --muted:#6b7686; --muted-2:#97a1af;
    --primary:#0f7b6c; --primary-600:#0b6457; --primary-50:#e7f4f1;
    --hover:#f6f9fb;
    --radius:14px; --shadow:0 1px 2px rgba(16,24,40,.05),0 1px 3px rgba(16,24,40,.07);
    --shadow-lg:0 10px 24px -6px rgba(16,24,40,.14),0 4px 8px -4px rgba(16,24,40,.08);
    --font:"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif;
    /* CORES DOS GRUPOS */
    --g1:#0f7b6c; --g1-50:#e7f4f1;
    --g2:#2563eb; --g2-50:#eaf1fe;
    --g3:#b45309; --g3-50:#fdf3e2;
    --g4:#7c3aed; --g4-50:#f1ebfe;
  }
  *{box-sizing:border-box}
  html,body{height:100%}
  body{margin:0;background:var(--bg);color:var(--text);font:13px/1.45 var(--font);-webkit-font-smoothing:antialiased}
  button,input{font:inherit;color:inherit}
  .app{min-height:100%;padding:8px 10px 10px;display:flex;flex-direction:column;gap:8px}

  /* CABECALHO (COMPACTO) */
  .hero{position:relative;overflow:hidden;border-radius:12px;padding:8px 12px;color:#fff;
    background:linear-gradient(120deg,#014530 0%,#03583c 50%,#0b7a4f 100%);box-shadow:var(--shadow);border-bottom:3px solid #f26b0f;
    display:flex;flex-wrap:wrap;align-items:center;gap:8px 14px}
  .hero:before{content:"";position:absolute;border-radius:50%;background:rgba(255,255,255,.06);pointer-events:none;width:200px;height:200px;right:-50px;top:-120px}
  /* LOGO AGRISAN (PNG 128x128 EMBUTIDO EM BASE64 - ARQUIVO ORIGINAL EM logo.png) */
  .hero .logo{width:40px;height:40px;border-radius:10px;flex:none;display:block;position:relative;
    box-shadow:0 0 0 2px rgba(255,255,255,.18),0 2px 6px rgba(0,0,0,.25)}
  .hero h1{margin:0;font-size:17px;font-weight:700;letter-spacing:-.01em;line-height:1.2}
  .hero p{margin:1px 0 0;opacity:.8;font-size:12px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
  .hero .ttl{flex:1;min-width:160px;position:relative}
  .search{position:relative;flex:0 1 260px;min-width:180px}
  .search svg{position:absolute;left:10px;top:50%;width:14px;height:14px;transform:translateY(-50%);color:var(--muted);pointer-events:none}
  .search input{width:100%;height:30px;border:0;border-radius:8px;padding:0 30px 0 30px;background:#fff;color:var(--text);font-size:12.5px}
  .search input:focus{outline:none;box-shadow:0 0 0 3px rgba(255,255,255,.45)}
  .search kbd{position:absolute;right:8px;top:50%;transform:translateY(-50%);font:10px var(--font);color:var(--muted);
    border:1px solid var(--line);border-radius:4px;padding:0 5px;background:var(--hover)}

  /* BARRA DE FILTROS + RECENTES */
  .tools{display:flex;flex-wrap:wrap;align-items:center;justify-content:space-between;gap:6px 16px}

  /* FILTRO POR GRUPO */
  .chips{display:flex;flex-wrap:wrap;gap:6px}
  .chip{border:1px solid var(--line);background:var(--card);border-radius:999px;padding:4px 11px;cursor:pointer;font-weight:600;font-size:12px;
    display:inline-flex;align-items:center;gap:7px;color:var(--muted);transition:all .15s}
  .chip:hover{border-color:#cfd6df;color:var(--text)}
  .chip .dot{width:8px;height:8px;border-radius:50%;background:var(--c,var(--muted-2))}
  .chip .n{font-weight:600;font-size:11px;color:var(--muted-2)}
  .chip[aria-pressed=true]{background:var(--text);border-color:var(--text);color:#fff}
  .chip[aria-pressed=true] .n{color:rgba(255,255,255,.65)}
  .chip:focus-visible{outline:2px solid var(--primary);outline-offset:2px}

  /* GRADE UNICA (GRUPOS EM SEQUENCIA, IDENTIFICADOS PELA COR DO CARTAO) */
  .grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(205px,1fr));gap:8px}

  /* CARTOES */
  .card{position:relative;display:flex;align-items:flex-start;gap:12px;text-align:left;width:100%;cursor:pointer;
    background:var(--card);border:1px solid var(--line);border-top:3px solid var(--c);border-radius:10px;padding:8px 10px 9px;box-shadow:var(--shadow);
    transition:transform .15s,box-shadow .15s,border-color .15s}
  .card:hover{transform:translateY(-2px);box-shadow:var(--shadow-lg);border-color:var(--c)}
  .card:focus-visible{outline:2px solid var(--c);outline-offset:2px}
  .card .ic{width:48px;height:48px;margin-top:1px;border-radius:12px;display:grid;place-items:center;flex:none;background:var(--c50);color:var(--c);transition:background .15s,color .15s}
  .card:hover .ic{background:var(--c);color:#fff}
  .card .ic svg{width:28px;height:28px}
  .card .tx{min-width:0;flex:1}
  .card .eb{display:flex;justify-content:space-between;gap:6px;font-size:9.5px;font-weight:700;letter-spacing:.06em;text-transform:uppercase;color:var(--c);margin-bottom:1px}
  .card .eb .cod{color:var(--muted-2);letter-spacing:.02em}
  .card .t{display:block;font-weight:650;font-size:13px;line-height:1.25;color:var(--text)}
  .card .d{display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden;margin-top:2px;font-size:11.5px;color:var(--muted);line-height:1.3}
  .card .new{display:inline-block;margin-left:5px;padding:0 6px;border-radius:999px;font-size:9.5px;font-weight:700;vertical-align:1px;
    background:#f26b0f;color:#fff;letter-spacing:.03em}
  mark{background:#fff1a8;color:inherit;border-radius:2px;padding:0 1px}

  /* RECENTES */
  .recent{display:flex;flex-wrap:wrap;align-items:center;gap:6px}
  .recent .lbl{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.06em;margin-right:2px}
  .rc{border:1px solid var(--line);background:var(--card);border-radius:7px;padding:3px 9px;cursor:pointer;font-size:11.5px;font-weight:600;
    display:inline-flex;align-items:center;gap:6px}
  .rc:hover{border-color:var(--c);color:var(--c)}
  .rc .dot{width:7px;height:7px;border-radius:50%;background:var(--c)}
  .rc:focus-visible{outline:2px solid var(--primary);outline-offset:2px}

  .empty{padding:40px 10px;text-align:center;color:var(--muted)}
  .empty b{display:block;color:var(--text);font-size:14px;margin-bottom:4px}
  .foot{margin-top:auto;text-align:center;font-size:10.5px;color:var(--muted-2)}

  .toast{position:fixed;left:50%;bottom:18px;transform:translate(-50%,20px);background:#1f2937;color:#fff;padding:9px 14px;border-radius:9px;
    font-size:12px;box-shadow:0 10px 25px rgba(0,0,0,.25);opacity:0;pointer-events:none;transition:all .2s;max-width:90vw;z-index:50}
  .toast.show{opacity:1;transform:translate(-50%,0)}

  @media (max-width:560px){
    .app{padding:6px}
    .hero p{display:none}
    .search{flex-basis:100%}
    .search kbd{display:none}
  }
  @media (prefers-reduced-motion:reduce){*{transition:none!important}}
</style>
</head>
<body>
<div class="app">
  <header class="hero">
    <img class="logo" src="data:image/png;base64,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" alt="Agrisan" width="64" height="64">
    <div class="ttl">
      <h1>Painel Contábil</h1>
      <p>Acesso rápido aos dashboards de contabilização, auditoria, impostos e conciliação</p>
    </div>
    <label class="search">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></svg>
      <input id="q" type="search" placeholder="Buscar dashboard..." autocomplete="off" aria-label="Buscar dashboard">
      <kbd>/</kbd>
    </label>
  </header>

  <div class="tools">
    <div class="chips" id="chips" role="group" aria-label="Filtrar por grupo"></div>
    <div class="recent" id="recent" hidden></div>
  </div>
  <main id="list"></main>

  <div class="foot">Clique para abrir · Ctrl + clique para abrir em nova aba</div>
</div>
<div class="toast" id="toast" role="status" aria-live="polite"></div>

<script>
(function(){
  'use strict';

  /* GRUPOS */
  var GRUPOS = [
    {id:'cont', nome:'Contabilização',            c:'var(--g1)', c50:'var(--g1-50)'},
    {id:'aud',  nome:'Auditoria e Consultas',     c:'var(--g2)', c50:'var(--g2-50)'},
    {id:'imp',  nome:'Impostos',                  c:'var(--g3)', c50:'var(--g3-50)'},
    {id:'conc', nome:'Conciliação e Relatórios',  c:'var(--g4)', c50:'var(--g4-50)'}
  ];

  /* DASHBOARDS
     nuDsb = CODIGO DO DASHBOARD NO SANKHYA | g = GRUPO | ic = ICONE | t = TITULO | d = DESCRICAO
     inc   = DATA DE INCLUSAO NO PAINEL ('AAAA-MM-DD'): EXIBE O SELO "NOVO" POR DIAS_NOVO DIAS A PARTIR DESSA DATA */
  var DIAS_NOVO = 90;
  var PAINEIS = [
    {nuDsb:203, g:'cont', ic:'doc',    t:'Notas Não Contabilizadas',                     d:'Notas fiscais pendentes de contabilização'},
    {nuDsb:205, g:'cont', ic:'down',   t:'Baixas Não Contabilizadas',                    d:'Baixas financeiras sem lançamento contábil'},
    {nuDsb:204, g:'cont', ic:'coin',   t:'Financeiro Não Contabilizado',                 d:'Títulos financeiros pendentes de contabilização'},
    {nuDsb:206, g:'cont', ic:'swap',   t:'Transferências Bancárias Não Contabilizadas',  d:'Transferências entre contas sem lançamento'},
    {nuDsb:207, g:'cont', ic:'check',  t:'Controle de Contabilização',                   d:'Acompanhamento geral da contabilização'},
    {nuDsb:294, g:'cont', ic:'alert',  t:'Auditoria de Movimentos Não Contabilizados',   d:'Movimentos que não geraram lançamento contábil', inc:'2026-11-13'},

    {nuDsb:212, g:'aud',  ic:'shield', t:'Auditoria de Dados',                           d:'Conferência e consistência de cadastros e lançamentos'},
    {nuDsb:297, g:'aud',  ic:'book',   t:'Auditoria Notas Não Geradas no Livro',         d:'Notas sem registro nos livros fiscais', inc:'2026-11-13'},
    {nuDsb:210, g:'aud',  ic:'clock',  t:'Notas Não Confirmadas',                        d:'Notas pendentes de confirmação'},
    {nuDsb:208, g:'aud',  ic:'hash',   t:'Consulta Nº Único',                            d:'Localiza um lançamento pelo número único'},
    {nuDsb:211, g:'aud',  ic:'list',   t:'Movimentos por TOP',                           d:'Movimentação agrupada por tipo de operação'},
    {nuDsb:213, g:'aud',  ic:'box',    t:'Consulta Estoque',                             d:'Posição e movimentação de estoque'},

    {nuDsb:202, g:'imp',  ic:'pct',    t:'Impostos nas Notas',                           d:'Impostos destacados nas notas fiscais'},
    {nuDsb:209, g:'imp',  ic:'receipt',t:'Impostos Retidos dos Serviços Tomados',        d:'Retenções sobre serviços contratados'},

    {nuDsb:296, g:'conc', ic:'scale',  t:'Financeiro em Aberto (Conciliação)',           d:'Títulos em aberto para conciliar com a contabilidade', inc:'2026-11-13'},
    {nuDsb:298, g:'conc', ic:'scale',  t:'Razão Auxiliar de Conta - Conciliação Financeiro', d:'Razão auxiliar confrontado com o financeiro', inc:'2026-11-13'},
    {nuDsb:300, g:'conc', ic:'sheet',  t:'Relatório Razão Analítico (Excel)',            d:'Razão analítico para exportação em Excel', inc:'2026-11-13'},
    {nuDsb:299, g:'conc', ic:'sheet',  t:'Registro de Inventário (Excel)',               d:'Registro de inventário para exportação em Excel', inc:'2026-11-13'}
  ];

  /* ICONES (SVG 24x24, TRACO) */
  var P = {
    doc:'<path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5M9 13h6M9 17h4"/>',
    down:'<path d="M12 4v12M6 10l6 6 6-6M5 20h14"/>',
    coin:'<circle cx="12" cy="12" r="8"/><path d="M14.5 9.5c-.4-.9-1.4-1.5-2.5-1.5-1.5 0-2.5.8-2.5 2s1 1.7 2.5 2 2.5.8 2.5 2-1 2-2.5 2c-1.1 0-2.1-.6-2.5-1.5M12 6.5V8M12 16v1.5"/>',
    swap:'<path d="M7 4L3 8l4 4M3 8h14M17 20l4-4-4-4M21 16H7"/>',
    check:'<path d="M9 11l3 3 8-8"/><path d="M20 12v7a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h9"/>',
    alert:'<path d="M10.3 3.9L1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z"/><path d="M12 9v4M12 17h.01"/>',
    shield:'<path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"/><path d="M9 12l2 2 4-4"/>',
    book:'<path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20V3H6.5A2.5 2.5 0 0 0 4 5.5z"/><path d="M4 19.5A2.5 2.5 0 0 0 6.5 22H20v-5"/><path d="M14 7l-4 4M10 7l4 4"/>',
    clock:'<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    hash:'<path d="M5 9h14M5 15h14M10 3L8 21M16 3l-2 18"/>',
    list:'<path d="M9 6h11M9 12h11M9 18h11"/><path d="M4 6h.01M4 12h.01M4 18h.01"/>',
    box:'<path d="M21 8l-9-5-9 5 9 5z"/><path d="M3 8v8l9 5 9-5V8M12 13v8"/>',
    pct:'<path d="M19 5L5 19"/><circle cx="6.5" cy="6.5" r="2.5"/><circle cx="17.5" cy="17.5" r="2.5"/>',
    receipt:'<path d="M5 3v18l2.5-1.5L10 21l2-1.5 2 1.5 2.5-1.5L19 21V3l-2.5 1.5L14 3l-2 1.5L10 3 7.5 4.5z"/><path d="M9 9h6M9 13h6"/>',
    scale:'<path d="M12 3v18M7 21h10M5 7h14"/><path d="M5 7l-3 7a3.5 3.5 0 0 0 6 0zM19 7l-3 7a3.5 3.5 0 0 0 6 0z"/>',
    sheet:'<rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 9h18M3 15h18M9 3v18"/>',
    go:'<path d="M7 17L17 7M8 7h9v9"/>'
  };
  function svg(k){ return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + P[k] + '</svg>'; }

  var $ = function(id){ return document.getElementById(id); };
  var grupoPorId = {};
  GRUPOS.forEach(function(g){ grupoPorId[g.id] = g; });
  var porNu = {};
  var hoje = new Date(); hoje.setHours(0, 0, 0, 0);
  PAINEIS.forEach(function(p){
    porNu[p.nuDsb] = p;
    p.novo = false;
    var m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(p.inc || '');
    if(m){
      var dias = (hoje - new Date(+m[1], +m[2] - 1, +m[3])) / 86400000;
      p.novo = dias >= 0 && dias < DIAS_NOVO;
    }
  });

  var state = { q:'', g:'' };
  var RECENT_KEY = 'agrisan.painelContabil.recentes';

  /* UTILITARIOS */
  var ACENTOS = new RegExp('[' + String.fromCharCode(0x300) + '-' + String.fromCharCode(0x36f) + ']', 'g');
  function norm(s){ return String(s || '').normalize('NFD').replace(ACENTOS, '').toLowerCase(); }
  function esc(s){ return String(s).replace(/[&<>"']/g, function(ch){ return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]; }); }
  function hl(txt, q){
    if(!q) return esc(txt);
    var n = norm(txt), i = n.indexOf(q);
    if(i < 0) return esc(txt);
    return esc(txt.slice(0, i)) + '<mark>' + esc(txt.slice(i, i + q.length)) + '</mark>' + esc(txt.slice(i + q.length));
  }
  function toast(msg){
    var t = $('toast');
    t.textContent = msg;
    t.classList.add('show');
    clearTimeout(toast._t);
    toast._t = setTimeout(function(){ t.classList.remove('show'); }, 3200);
  }
  function lerRecentes(){
    try{ return JSON.parse(localStorage.getItem(RECENT_KEY) || '[]').filter(function(n){ return porNu[n]; }); }catch(e){ return []; }
  }
  function gravarRecente(nu){
    var r = lerRecentes().filter(function(n){ return n !== nu; });
    r.unshift(nu);
    try{ localStorage.setItem(RECENT_KEY, JSON.stringify(r.slice(0, 4))); }catch(e){}
  }

  /* ABRE O DASHBOARD - MESMO FORMATO DO LINK DO MENU: /mge/system.jsp#app/ + Base64("br.com.sankhya.menu.adicional.nuDsb.<COD>.1") */
  function link(nu){ return '/mge/system.jsp#app/' + btoa('br.com.sankhya.menu.adicional.nuDsb.' + nu + '.1'); }
  function abrir(nu, novaAba){
    var p = porNu[nu];
    if(!p) return;
    gravarRecente(nu);
    renderRecentes();
    var url = link(nu);
    var dentroSankhya = /\/mge\//.test(location.pathname);
    if(!dentroSankhya){ toast('Demonstração: abriria "' + p.t + '" (' + url + ')'); return; }
    if(novaAba){ window.open(url, '_blank'); return; }
    try{ window.top.location.href = url; }catch(e){ window.open(url, '_blank'); }
  }

  /* RENDER */
  function filtrados(){
    return PAINEIS.filter(function(p){
      if(state.g && p.g !== state.g) return false;
      if(!state.q) return true;
      return norm(p.t + ' ' + p.d + ' ' + grupoPorId[p.g].nome + ' ' + p.nuDsb + (p.novo ? ' novo' : '')).indexOf(state.q) >= 0;
    });
  }

  function renderChips(){
    var html = '<button class="chip" type="button" data-g="" aria-pressed="' + (!state.g) + '">Todos <span class="n">' + PAINEIS.length + '</span></button>';
    GRUPOS.forEach(function(g){
      var n = PAINEIS.filter(function(p){ return p.g === g.id; }).length;
      html += '<button class="chip" type="button" data-g="' + g.id + '" aria-pressed="' + (state.g === g.id) + '" style="--c:' + g.c + '">'
        + '<span class="dot"></span>' + esc(g.nome) + ' <span class="n">' + n + '</span></button>';
    });
    $('chips').innerHTML = html;
  }

  function cardHtml(p){
    var g = grupoPorId[p.g];
    return '<button class="card" type="button" data-nu="' + p.nuDsb + '" style="--c:' + g.c + ';--c50:' + g.c50 + '" title="Abrir dashboard ' + p.nuDsb + '">'
      + '<span class="ic">' + svg(p.ic) + '</span>'
      + '<span class="tx"><span class="eb"><span>' + esc(g.nome) + '</span><span class="cod">#' + p.nuDsb + '</span></span>'
      + '<span class="t">' + hl(p.t, state.q) + (p.novo ? '<span class="new">NOVO</span>' : '') + '</span>'
      + '<span class="d">' + hl(p.d, state.q) + '</span></span>'
      + '</button>';
  }

  function renderLista(){
    var itens = filtrados();
    if(!itens.length){
      $('list').innerHTML = '<div class="empty"><b>Nenhum dashboard encontrado</b>Tente outro termo de busca ou selecione "Todos".</div>';
      return;
    }
    //ORDENA PELA ORDEM DOS GRUPOS, MANTENDO A ORDEM DA LISTA DENTRO DE CADA GRUPO
    var html = '';
    GRUPOS.forEach(function(g){
      html += itens.filter(function(p){ return p.g === g.id; }).map(cardHtml).join('');
    });
    $('list').innerHTML = '<div class="grid">' + html + '</div>';
  }

  function renderRecentes(){
    var r = lerRecentes();
    var box = $('recent');
    if(!r.length){ box.hidden = true; return; }
    box.hidden = false;
    box.innerHTML = '<span class="lbl">Recentes</span>' + r.map(function(nu){
      var p = porNu[nu], g = grupoPorId[p.g];
      return '<button class="rc" type="button" data-nu="' + nu + '" style="--c:' + g.c + '"><span class="dot"></span>' + esc(p.t) + '</button>';
    }).join('');
  }

  function render(){ renderChips(); renderLista(); }

  /* EVENTOS */
  $('q').addEventListener('input', function(){ state.q = norm(this.value.trim()); renderLista(); });
  $('q').addEventListener('keydown', function(e){
    if(e.key === 'Escape'){ this.value = ''; state.q = ''; renderLista(); }
    if(e.key === 'Enter'){
      var f = filtrados();
      if(f.length === 1) abrir(f[0].nuDsb, e.ctrlKey || e.shiftKey);
    }
  });
  $('chips').addEventListener('click', function(e){
    var b = e.target.closest('.chip');
    if(!b) return;
    state.g = b.getAttribute('data-g');
    render();
  });
  function onAbrir(e){
    var b = e.target.closest('[data-nu]');
    if(!b) return;
    abrir(parseInt(b.getAttribute('data-nu'), 10), e.ctrlKey || e.metaKey || e.shiftKey || e.button === 1);
  }
  $('list').addEventListener('click', onAbrir);
  $('recent').addEventListener('click', onAbrir);
  $('list').addEventListener('auxclick', function(e){ if(e.button === 1){ e.preventDefault(); onAbrir(e); } });
  document.addEventListener('keydown', function(e){
    if(e.key === '/' && document.activeElement !== $('q')){ e.preventDefault(); $('q').focus(); }
  });

  /* ESCONDE A MOLDURA NATIVA DO GADGET (BARRA "PAINEL CONTABIL (HTML5)" + ICONES, MENU DE IMPRESSAO E BARRA LATERAL DE FILTROS).
     O HTML5 RODA NUM IFRAME DENTRO DA TELA DO GADGET (MESMO DOMINIO): O IFRAME E FIXADO SOBRE TODA A TELA DO GADGET,
     COBRINDO ESSES ELEMENTOS. SO ATUA QUANDO A TELA DO GADGET E ELA PROPRIA UM IFRAME DO SISTEMA (NUNCA MEXE NAS ABAS/MENU DO SANKHYA). */
  function esconderMolduraSankhya(){
    try{
      var fe = window.frameElement;
      if(!fe || window.parent === window.top) return;
      var pd = fe.ownerDocument;
      fe.setAttribute('data-agrisan-full', '1');
      if(!pd.getElementById('agrisan-full-css')){
        var st = pd.createElement('style');
        st.id = 'agrisan-full-css';
        st.textContent = 'iframe[data-agrisan-full]{position:fixed!important;left:0!important;top:0!important;right:auto!important;bottom:auto!important;'
          + 'width:100%!important;height:100%!important;max-width:none!important;max-height:none!important;margin:0!important;padding:0!important;'
          + 'border:0!important;transform:none!important;z-index:2147483000!important;background:#f3f5f8!important;visibility:visible!important}'
          + 'html,body{overflow:hidden!important}';
        (pd.head || pd.documentElement).appendChild(st);
      }
    }catch(e){}
  }

  esconderMolduraSankhya();
  render();
  renderRecentes();
})();
</script>
</body>
</html>
