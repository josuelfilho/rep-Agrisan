<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="false"%>
<%@ taglib uri="http://java.sun.com/jstl/core_rt" prefix="c" %>
<%@ taglib prefix="snk" uri="/WEB-INF/tld/sankhyaUtil.tld" %>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Notas de Compra x CT-e</title>
<snk:load/>
<!--
  DASHBOARD HTML5 - NOTAS DE COMPRA x CT-e (AGRISAN)
  - LISTA NFs DE COMPRA (TIPMOV 'C', MODELO <> 57) COM VLRFRETE > 0
  - 1 CLIQUE NA NF: CARREGA O(S) CT-e VINCULADO(S) VIA TGFNCT (MESMO VINCULO DO cabEPJ / replicaRateioNFxCTEJob)
  - 2 CLIQUES NA NF (OU NO CT-e): ABRE A CENTRAL (LINK NO MESMO PADRAO DO geraMsgLinks)
  - "VER RATEIO": POP UP COMPARANDO O RATEIO (TGFRAV ORIGEM 'E') DAS NFs x CT-e
  OBS: NAO USAR TEMPLATE LITERALS COM CIFRAO+CHAVE NO JS (O JSP INTERPRETA COMO EL).
-->
<style>
  :root{
    --bg:#f3f5f8; --card:#ffffff; --line:#e4e8ee; --line-soft:#eef1f5;
    --text:#1d2633; --muted:#6b7686; --muted-2:#97a1af;
    --primary:#0f7b6c; --primary-600:#0b6457; --primary-50:#e7f4f1;
    --blue:#2563eb; --blue-50:#eaf1fe;
    --ok:#15803d; --ok-50:#e8f6ec; --warn:#b45309; --warn-50:#fdf3e2; --err:#c0262d; --err-50:#fdecec;
    --sel:#e3f1ee; --hover:#f6f9fb;
    --radius:12px; --shadow:0 1px 2px rgba(16,24,40,.05),0 1px 3px rgba(16,24,40,.07);
    --font:"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif;
    --mono:"Cascadia Mono",Consolas,"Courier New",monospace;
  }
  *{box-sizing:border-box}
  html,body{height:100%}
  body{margin:0;background:var(--bg);color:var(--text);font:13px/1.4 var(--font);-webkit-font-smoothing:antialiased}
  button,input,select{font:inherit;color:inherit}
  .app{display:flex;flex-direction:column;gap:12px;min-height:100%;padding:14px 16px}

  /* CABECALHO */
  .top{display:flex;align-items:center;justify-content:space-between;gap:12px;flex-wrap:wrap}
  .top h1{margin:0;font-size:18px;font-weight:650;letter-spacing:-.01em;display:flex;align-items:center;gap:10px}
  .top h1 .logo{width:30px;height:30px;border-radius:8px;background:var(--primary);color:#fff;display:grid;place-items:center}
  .top .sub{color:var(--muted);font-size:12px;margin-top:2px}
  .top .actions{display:flex;gap:8px;align-items:center}
  .demo{background:var(--warn-50);color:var(--warn);border:1px solid #f3d9a8;padding:3px 9px;border-radius:999px;font-size:11px;font-weight:600}

  .btn{border:1px solid var(--line);background:var(--card);border-radius:8px;padding:7px 12px;cursor:pointer;display:inline-flex;align-items:center;gap:6px;font-weight:550;transition:background .15s,border-color .15s,box-shadow .15s}
  .btn:hover{background:var(--hover);border-color:#d4dae3}
  .btn:focus-visible{outline:2px solid var(--primary);outline-offset:1px}
  .btn.primary{background:var(--primary);border-color:var(--primary);color:#fff}
  .btn.primary:hover{background:var(--primary-600)}
  .btn.sm{padding:4px 9px;font-size:12px;border-radius:7px}
  .btn svg{width:15px;height:15px;flex:none}

  /* FILTROS */
  .filters{background:var(--card);border:1px solid var(--line);border-radius:var(--radius);box-shadow:var(--shadow);padding:12px 14px;display:flex;flex-wrap:wrap;gap:12px 16px;align-items:flex-end}
  .f{display:flex;flex-direction:column;gap:4px}
  .f label,.f .lbl{font-size:11px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.04em}
  .range{display:flex;align-items:center;gap:6px}
  .range span{color:var(--muted-2)}
  .inp{height:32px;border:1px solid var(--line);border-radius:8px;padding:0 9px;background:#fff;min-width:0}
  .inp:focus{outline:none;border-color:var(--primary);box-shadow:0 0 0 3px var(--primary-50)}
  input[type=date].inp{width:130px}
  .chk{display:flex;align-items:center;gap:8px;height:32px;cursor:pointer;user-select:none;font-weight:550}
  .chk input{position:absolute;opacity:0;pointer-events:none}
  .chk .sw{width:34px;height:20px;border-radius:999px;background:#cfd6df;position:relative;transition:background .15s;flex:none}
  .chk .sw:after{content:"";position:absolute;top:2px;left:2px;width:16px;height:16px;border-radius:50%;background:#fff;box-shadow:0 1px 2px rgba(0,0,0,.2);transition:transform .15s}
  .chk input:checked + .sw{background:var(--primary)}
  .chk input:checked + .sw:after{transform:translateX(14px)}
  .chk input:focus-visible + .sw{outline:2px solid var(--primary);outline-offset:2px}
  .filters .grow{flex:1}
  .chks{gap:0}
  .chks .chk{height:24px;font-size:12px}
  .chks .chk .sw{width:30px;height:18px}
  .chks .chk .sw:after{width:14px;height:14px}
  .chks .chk input:checked + .sw:after{transform:translateX(12px)}

  /* ICONE DO PAINEL + TOOLTIP */
  .brand{position:relative;z-index:45;align-self:center;outline:none;cursor:help}
  .brand .logo{width:38px;height:38px;border-radius:10px;background:var(--primary);color:#fff;display:grid;place-items:center;box-shadow:0 2px 6px rgba(15,123,108,.3);transition:transform .15s}
  .brand:hover .logo,.brand:focus .logo{transform:translateY(-1px)}
  .brand .demo-dot{position:absolute;top:-3px;right:-3px;width:11px;height:11px;border-radius:50%;background:#f59e0b;border:2px solid #fff}
  .brand .tip{position:absolute;z-index:40;top:calc(100% + 10px);left:0;width:310px;background:#1f2937;color:#e5e7eb;border-radius:10px;padding:11px 13px;font-size:12px;line-height:1.5;box-shadow:0 12px 30px rgba(0,0,0,.25);opacity:0;visibility:hidden;transform:translateY(-4px);transition:opacity .15s,transform .15s,visibility .15s;pointer-events:none}
  .brand .tip:before{content:"";position:absolute;top:-6px;left:14px;width:12px;height:12px;background:#1f2937;transform:rotate(45deg)}
  .brand:hover .tip,.brand:focus .tip{opacity:1;visibility:visible;transform:none}
  .brand .tip b{display:block;color:#fff;font-size:13px;margin-bottom:3px}
  .brand .tip ul{margin:6px 0 0;padding-left:16px}
  .brand .tip .upd{display:block;margin-top:6px;color:#9ca3af;font-size:11px}

  /* MULTILIST */
  .ms{position:relative;width:220px}
  .ms-btn{width:100%;height:32px;border:1px solid var(--line);border-radius:8px;background:#fff;display:flex;align-items:center;justify-content:space-between;gap:6px;padding:0 9px;cursor:pointer;text-align:left}
  .ms-btn:focus{outline:none;border-color:var(--primary);box-shadow:0 0 0 3px var(--primary-50)}
  .ms-btn .txt{white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
  .ms-btn .cnt{background:var(--primary-50);color:var(--primary);border-radius:999px;padding:0 7px;font-size:11px;font-weight:700}
  .ms-pop{position:absolute;z-index:30;top:36px;left:0;width:340px;max-width:90vw;background:#fff;border:1px solid var(--line);border-radius:10px;box-shadow:0 12px 32px rgba(16,24,40,.16);padding:8px;display:none}
  .ms.open .ms-pop{display:block}
  .ms-pop .inp{width:100%;margin-bottom:6px}
  .ms-tools{display:flex;justify-content:space-between;padding:2px 4px 6px;font-size:12px}
  .ms-tools a{color:var(--primary);cursor:pointer;font-weight:600}
  .ms-list{max-height:260px;overflow:auto}
  .ms-item{display:flex;align-items:center;gap:8px;padding:5px 6px;border-radius:6px;cursor:pointer}
  .ms-item:hover{background:var(--hover)}
  .ms-item input{accent-color:var(--primary);margin:0}
  .ms-item b{font-variant-numeric:tabular-nums;color:var(--muted);font-weight:600;min-width:38px}

  /* KPIs */
  .kpis{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:12px}
  .kpi{background:var(--card);border:1px solid var(--line);border-radius:var(--radius);box-shadow:var(--shadow);padding:11px 14px}
  .kpi .k{font-size:11px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.04em}
  .kpi .v{font-size:20px;font-weight:700;margin-top:3px;font-variant-numeric:tabular-nums;letter-spacing:-.01em}
  .kpi .h{font-size:11.5px;color:var(--muted);margin-top:1px}
  .kpi.ok .v{color:var(--ok)} .kpi.warn .v{color:var(--warn)}

  /* PAINEIS */
  .split{display:flex;flex-direction:column;gap:12px;flex:1;min-height:440px}
  #cardNF{flex:1 1 0;min-height:300px}
  #cardCTe{flex:0 0 270px;display:none}
  .split.has-cte #cardCTe{display:flex;animation:up .18s ease-out}
  .cte-grid{display:grid;grid-template-columns:340px minmax(0,1fr);height:100%;min-height:0}
  .cte-l{border-right:1px solid var(--line);overflow:auto;padding-bottom:10px}
  .cte-r{overflow:auto;min-width:0}
  .cte-r .empty{padding:24px}
  .acts{display:flex;gap:6px}
  .card{background:var(--card);border:1px solid var(--line);border-radius:var(--radius);box-shadow:var(--shadow);display:flex;flex-direction:column;min-height:0;min-width:0;position:relative;overflow:hidden}
  .card-h{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:11px 14px;border-bottom:1px solid var(--line)}
  .card-h h2{margin:0;font-size:14px;font-weight:650;display:flex;align-items:center;gap:8px}
  .pill{background:var(--line-soft);color:var(--muted);border-radius:999px;padding:1px 8px;font-size:11.5px;font-weight:650}
  .card-h .tools{display:flex;gap:8px;align-items:center}
  .search{position:relative}
  .search svg{position:absolute;left:8px;top:8px;width:15px;height:15px;color:var(--muted-2)}
  .search .inp{padding-left:28px;width:210px}
  .card-b{flex:1;min-height:0;overflow:auto}
  .hint{font-size:11.5px;color:var(--muted);padding:6px 14px;border-top:1px solid var(--line);background:#fbfcfd}

  /* TABELAS */
  table.grid{border-collapse:separate;border-spacing:0;width:100%;font-variant-numeric:tabular-nums}
  .grid th{position:sticky;top:0;z-index:2;background:#f8fafc;color:var(--muted);font-size:11px;font-weight:650;text-transform:uppercase;letter-spacing:.03em;text-align:left;padding:8px 10px;border-bottom:1px solid var(--line);white-space:nowrap;cursor:pointer;user-select:none}
  .grid th:hover{color:var(--text)}
  .grid th .ar{opacity:.35;margin-left:3px}
  .grid th.sorted .ar{opacity:1;color:var(--primary)}
  .grid td{padding:7px 10px;border-bottom:1px solid var(--line-soft);white-space:nowrap;max-width:280px;overflow:hidden;text-overflow:ellipsis}
  .grid tbody tr{cursor:pointer;transition:background .1s}
  .grid tbody tr:hover td{background:var(--hover)}
  .grid tbody tr.sel td{background:var(--sel)}
  .grid tbody tr.sel td:first-child{box-shadow:inset 3px 0 0 var(--primary)}
  .grid .num{text-align:right}
  .grid .mono{font-family:var(--mono);font-size:11.5px;color:#475467}
  .grid .cd{color:var(--muted);margin-right:4px}
  .grid tfoot td{position:sticky;bottom:0;background:#f8fafc;font-weight:700;border-top:1px solid var(--line);border-bottom:0}
  .badge{display:inline-flex;align-items:center;gap:4px;border-radius:999px;padding:1px 8px;font-size:11.5px;font-weight:650}
  .badge.ok{background:var(--ok-50);color:var(--ok)}
  .badge.no{background:var(--line-soft);color:var(--muted)}
  .badge.warn{background:var(--warn-50);color:var(--warn)}
  .badge.err{background:var(--err-50);color:var(--err)}
  .badge.blue{background:var(--blue-50);color:var(--blue)}

  /* LADO DIREITO */
  .nfbox{margin:12px 14px 4px;border:1px solid var(--line);border-radius:10px;padding:10px 12px;background:linear-gradient(180deg,#fbfdfc,#f6faf9)}
  .nfbox .t{font-weight:650;display:flex;justify-content:space-between;gap:8px;align-items:center}
  .nfbox .p{color:var(--muted);font-size:12px;margin-top:2px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
  .cmp{display:grid;grid-template-columns:repeat(3,1fr);gap:8px;margin-top:9px}
  .cmp div{background:#fff;border:1px solid var(--line-soft);border-radius:8px;padding:6px 9px}
  .cmp span{display:block;font-size:10.5px;color:var(--muted);text-transform:uppercase;font-weight:600;letter-spacing:.03em}
  .cmp b{font-size:14px;font-variant-numeric:tabular-nums}
  .sect{padding:10px 14px 6px;font-size:11px;font-weight:650;color:var(--muted);text-transform:uppercase;letter-spacing:.04em}
  .btn-rat{border:1px solid var(--primary);color:var(--primary);background:#fff;border-radius:7px;padding:3px 9px;font-size:12px;font-weight:650;cursor:pointer;display:inline-flex;align-items:center;gap:5px}
  .btn-rat:hover{background:var(--primary);color:#fff}
  .btn-rat svg{width:13px;height:13px}

  .empty{display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center;gap:8px;color:var(--muted);padding:40px 24px;height:100%}
  .empty svg{width:42px;height:42px;color:#c3cad4}
  .empty b{color:var(--text);font-size:14px}

  /* LOADING */
  .loading{position:absolute;inset:0;background:rgba(255,255,255,.65);display:none;align-items:center;justify-content:center;z-index:5}
  .card.busy .loading{display:flex}
  .spin{width:26px;height:26px;border:3px solid var(--primary-50);border-top-color:var(--primary);border-radius:50%;animation:sp .7s linear infinite}
  @keyframes sp{to{transform:rotate(360deg)}}

  /* MODAL RATEIO */
  .ov{position:fixed;inset:0;background:rgba(15,23,42,.45);display:none;align-items:center;justify-content:center;z-index:50;padding:16px}
  .ov.open{display:flex;animation:fd .15s ease-out}
  @keyframes fd{from{opacity:0}to{opacity:1}}
  .modal{background:#fff;border-radius:14px;width:min(1280px,100%);max-height:100%;display:flex;flex-direction:column;box-shadow:0 24px 60px rgba(15,23,42,.3);animation:up .18s ease-out;position:relative;overflow:hidden}
  @keyframes up{from{transform:translateY(8px)}to{transform:none}}
  .modal-h{display:flex;justify-content:space-between;align-items:flex-start;gap:12px;padding:14px 18px;border-bottom:1px solid var(--line)}
  .modal-h h3{margin:0;font-size:16px;font-weight:650;display:flex;align-items:center;gap:10px;flex-wrap:wrap}
  .modal-h .s{color:var(--muted);font-size:12px;margin-top:3px}
  .x{border:0;background:transparent;cursor:pointer;width:32px;height:32px;border-radius:8px;display:grid;place-items:center;color:var(--muted)}
  .x:hover{background:var(--hover);color:var(--text)}
  .modal-b{overflow:auto;padding:14px 18px 18px;display:flex;flex-direction:column;gap:14px}
  .two{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:14px}
  .pane{border:1px solid var(--line);border-radius:10px;overflow:hidden;min-width:0}
  .pane-h{padding:9px 12px;font-weight:650;display:flex;justify-content:space-between;align-items:center;background:#f8fafc;border-bottom:1px solid var(--line)}
  .pane-b{overflow:auto;max-height:44vh}
  .pane .grid th{cursor:default;padding:7px 8px}
  .pane .grid th .ar,#cteWrap .grid th .ar{display:none}
  .pane .grid td{white-space:normal;max-width:220px;padding:6px 8px;vertical-align:top}
  .pane .grid td.num{white-space:nowrap}
  .pane .grid tbody tr{cursor:default}
  .grid td.mono{max-width:170px}
  .grid tr.dif td{background:var(--err-50)!important}
  .grid tr.okr td.st{color:var(--ok)}
  .diff-pos{color:var(--err);font-weight:650}
  .muted{color:var(--muted)}

  /* TOAST */
  .toast{position:fixed;right:16px;bottom:16px;z-index:60;background:#1f2937;color:#fff;padding:10px 14px;border-radius:10px;box-shadow:0 10px 30px rgba(0,0,0,.25);max-width:520px;display:none;font-size:12.5px}
  .toast.err{background:var(--err)}
  .toast.show{display:block;animation:up .2s ease-out}

  @media (max-width:1100px){
    .kpis{grid-template-columns:repeat(3,minmax(0,1fr))}
    .two{grid-template-columns:minmax(0,1fr)}
    .cte-grid{grid-template-columns:minmax(0,1fr)}
    .cte-l{border-right:0;border-bottom:1px solid var(--line)}
    #cardCTe{flex-basis:auto;max-height:520px}
  }
  @media (max-width:640px){
    .app{padding:12px}
    .kpis{grid-template-columns:repeat(2,minmax(0,1fr))}
    .ms,.ms-pop{width:100%}
    .search .inp{width:150px}
  }
</style>
</head>
<body>
<div class="app">

  <!-- FILTROS (O ICONE DE FRETE FAZ O PAPEL DO CABECALHO: PASSAR O MOUSE MOSTRA A IDEIA DO PAINEL) -->
  <div class="filters" id="filters">
    <div class="brand" tabindex="0" aria-describedby="brandTip">
      <span class="logo"><svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 7h11v9H3z"/><path d="M14 10h4l3 3v3h-7"/><circle cx="7" cy="18" r="2"/><circle cx="17" cy="18" r="2"/></svg></span>
      <span class="demo-dot" id="demoTag" style="display:none" title="Modo demonstração"></span>
      <div class="tip" role="tooltip" id="brandTip">
        <b>Notas de Compra x CT-e</b>
        Acompanha o frete das notas de compra: mostra o CT-e vinculado a cada nota (TGFNCT) e compara o rateio da NF com o rateio do CT-e.
        <ul>
          <li>1 clique na nota: CT-e vinculado abaixo</li>
          <li>2 cliques: abre a nota na Central</li>
          <li>Ver Rateio: comparativo NF x CT-e</li>
        </ul>
        <span class="upd" id="lastUpd"></span>
      </div>
    </div>
    <div class="f">
      <label for="dtEntIni">Período Entrada</label>
      <div class="range"><input type="date" class="inp" id="dtEntIni"><span>até</span><input type="date" class="inp" id="dtEntFin"></div>
    </div>
    <div class="f">
      <label for="dtNegIni">Período Negociação</label>
      <div class="range"><input type="date" class="inp" id="dtNegIni"><span>até</span><input type="date" class="inp" id="dtNegFin"></div>
    </div>
    <div class="f">
      <span class="lbl">TOPs Compra</span>
      <div class="ms" id="msTop">
        <button type="button" class="ms-btn" id="msTopBtn"><span class="txt">Todas as TOPs</span><span class="cnt" style="display:none"></span><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m6 9 6 6 6-6"/></svg></button>
        <div class="ms-pop">
          <input type="text" class="inp" id="msTopSearch" placeholder="Buscar TOP...">
          <div class="ms-tools"><a id="msAll">Marcar todas</a><a id="msNone">Limpar</a></div>
          <div class="ms-list" id="msTopList"></div>
        </div>
      </div>
    </div>
    <div class="f chks">
      <label class="chk"><input type="checkbox" id="apenasCte"><span class="sw"></span>Apenas NF-e com CT-e?</label>
      <label class="chk"><input type="checkbox" id="apenasSemRat"><span class="sw"></span>Apenas NF-e com CT-e sem rateio?</label>
    </div>
    <div class="grow"></div>
    <div class="f">
      <div style="display:flex;gap:8px">
        <button class="btn" id="btnLimpar">Limpar</button>
        <button class="btn" id="btnCsv" title="Exportar a lista de notas (CSV)"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3v12"/><path d="m7 10 5 5 5-5"/><path d="M5 21h14"/></svg></button>
        <button class="btn primary" id="btnAplicar"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 5h18l-7 8v6l-4-2v-4z"/></svg>Aplicar</button>
      </div>
    </div>
  </div>

  <!-- KPIs -->
  <div class="kpis">
    <div class="kpi"><div class="k">Notas de compra</div><div class="v" id="kQtd">-</div><div class="h">com valor de frete</div></div>
    <div class="kpi"><div class="k">Valor das notas</div><div class="v" id="kVlr">-</div><div class="h" id="kVlrH">&nbsp;</div></div>
    <div class="kpi"><div class="k">Frete nas notas</div><div class="v" id="kFrete">-</div><div class="h" id="kFreteH">&nbsp;</div></div>
    <div class="kpi ok"><div class="k">Com CT-e vinculado</div><div class="v" id="kCom">-</div><div class="h" id="kComH">&nbsp;</div></div>
    <div class="kpi warn"><div class="k">Sem CT-e vinculado</div><div class="v" id="kSem">-</div><div class="h" id="kSemH">&nbsp;</div></div>
  </div>

  <!-- PAINEIS: NF (TOPO) / CTE (INFERIOR, APARECE AO CLICAR NA NF) -->
  <div class="split" id="split">
    <div class="card" id="cardNF">
      <div class="card-h">
        <h2>Notas de Compra <span class="pill" id="nfCount">0</span></h2>
        <div class="tools">
          <div class="search"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg><input type="text" class="inp" id="nfSearch" placeholder="Filtrar na lista..."></div>
        </div>
      </div>
      <div class="card-b" id="nfWrap"></div>
      <div class="hint">1 clique: mostra o CT-e vinculado abaixo &middot; 2 cliques: abre a nota na Central</div>
      <div class="loading"><div class="spin"></div></div>
    </div>

    <div class="card" id="cardCTe">
      <div class="card-h">
        <h2>CT-e vinculado <span class="pill" id="cteCount">0</span> <span class="muted" id="cteNfRef" style="font-weight:500;font-size:12.5px"></span></h2>
        <button class="x" id="cteClose" title="Fechar e voltar à lista completa (Esc)"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 6 6 18M6 6l12 12"/></svg></button>
      </div>
      <div class="card-b" id="cteWrap"></div>
      <div class="hint">Ver Rateio: compara o rateio da NF x CT-e &middot; Abrir CT-e (ou 2 cliques na linha): abre o CT-e na Central</div>
      <div class="loading"><div class="spin"></div></div>
    </div>
  </div>
</div>

<!-- POP UP RATEIO -->
<div class="ov" id="ovRat" role="dialog" aria-modal="true" aria-labelledby="ratTitle">
  <div class="modal">
    <div class="modal-h">
      <div>
        <h3 id="ratTitle">Rateio NF x CT-e</h3>
        <div class="s" id="ratSub"></div>
      </div>
      <button class="x" id="ratClose" title="Fechar (Esc)"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 6 6 18M6 6l12 12"/></svg></button>
    </div>
    <div class="modal-b" id="ratBody"></div>
    <div class="loading" id="ratLoading"><div class="spin"></div></div>
  </div>
</div>

<div class="toast" id="toast"></div>

<script>
(function(){
  'use strict';

  /* =========================================================================
     CONFIGURACAO
     ========================================================================= */
  var CFG = {
    //RESOURCE ID DA CENTRAL DE COMPRAS (CONFIRMADO NO AMBIENTE AGRISAN), USADO PARA ABRIR NF E CT-e
    TELA_CENTRAL: 'br.com.sankhya.com.mov.CentralNotas_COMPRA',
    MAX_LINHAS: 3000,
    TOL_PERC: 0.01,  //TOLERANCIA (PONTOS PERCENTUAIS) PARA CONSIDERAR O RATEIO DIVERGENTE
    //COMO EXECUTAR AS CONSULTAS: 'auto' (executeQuery DO COMPONENTE E, SE O RETORNO NAO FOR ENTENDIDO, DbExplorerSP),
    //'executeQuery' (SO O COMPONENTE) OU 'dbexplorer' (SO O SERVICO DbExplorerSP.executeQuery)
    FONTE: 'auto'
  };

  /* =========================================================================
     CONSULTAS (ORACLE). VALORES DOS FILTROS SAO VALIDADOS ANTES DE ENTRAR NO SQL
     VINCULO NF x CTE: TGFNCT (NCT.NUNOTA = CTE / NCT.CHAVENFE + NCT.NUMERO = NF)
     ========================================================================= */
  var SQL = {
    tops: function(){
      //TOPs DE COMPRA MODELO 55 (NF-e), NA VERSAO MAIS RECENTE
      return "SELECT T.CODTIPOPER, T.DESCROPER, T.CODMODDOC\n"
        + "FROM TGFTOP T\n"
        + "WHERE T.DHALTER = (SELECT MAX(DHALTER) FROM TGFTOP WHERE CODTIPOPER = T.CODTIPOPER)\n"
        + "AND T.TIPMOV = 'C'\n"
        + "AND T.CODMODDOC = 55\n"
        + "ORDER BY 2";
    },

    //COLUNAS COMUNS DAS GRADES NF E CTE (ALIAS N = NOTA)
    colunas: function(chave){
      return "N.NUNOTA, N.NUMNOTA, N.SERIENOTA, N.CODEMP, " + chave + " AS CHAVE,\n"
        + "TO_CHAR(N.DTNEG, 'DD/MM/YYYY') AS DTNEG, TO_CHAR(N.DTENTSAI, 'DD/MM/YYYY') AS DTENTSAI,\n"
        + "N.CODNAT, NAT.DESCRNAT, N.CODCENCUS, CUS.DESCRCENCUS, N.CODPROJ, PRJ.IDENTIFICACAO AS DESCRPROJ,\n"
        + "N.VLRNOTA, NVL(N.VLRFRETE, 0) AS VLRFRETE, N.CODTIPOPER, TPO.DESCROPER,\n"
        + "CASE WHEN N.STATUSNOTA = 'L' THEN 'Sim' ELSE 'Não' END AS CONFIRMADA,\n"
        + "N.CODPARC, PAR.NOMEPARC\n";
    },
    joins: function(){
      return "INNER JOIN TGFTOP TPO ON TPO.CODTIPOPER = N.CODTIPOPER AND TPO.DHALTER = N.DHTIPOPER\n"
        + "INNER JOIN TGFPAR PAR ON PAR.CODPARC = N.CODPARC\n"
        + "LEFT JOIN TGFNAT NAT ON NAT.CODNAT = N.CODNAT\n"
        + "LEFT JOIN TSICUS CUS ON CUS.CODCENCUS = N.CODCENCUS\n"
        + "LEFT JOIN TCSPRJ PRJ ON PRJ.CODPROJ = N.CODPROJ\n";
    },

    nfs: function(f){
      var w = [];
      if(f.entIni) w.push("AND N.DTENTSAI >= " + toDateSql(f.entIni));
      if(f.entFin) w.push("AND N.DTENTSAI < " + toDateSql(f.entFin) + " + 1");
      if(f.negIni) w.push("AND N.DTNEG >= " + toDateSql(f.negIni));
      if(f.negFin) w.push("AND N.DTNEG < " + toDateSql(f.negFin) + " + 1");
      if(f.tops.length) w.push("AND N.CODTIPOPER IN (" + f.tops.join(",") + ")");

      //SEM SUBCONSULTAS CORRELACIONADAS: OS FILTROS RODAM UMA VEZ NA CTE "NF", O VINCULO COM A TGFNCT
      //E RESOLVIDO EM UM UNICO JOIN (HASH) E AGREGADO POR NF. O SELECT EXTERNO MANTEM O SQL INICIANDO
      //COM SELECT (ALGUMAS APIS DO SANKHYA SO ACEITAM SELECT) E APLICA O LIMITE DE LINHAS
      return "SELECT * FROM (\n"
        + "WITH NF AS (\n"
        + "  SELECT /*+ MATERIALIZE */\n"
        + "         N.NUNOTA, N.NUMNOTA, N.SERIENOTA, N.CODEMP, N.CHAVENFE, N.DTNEG, N.DTENTSAI,\n"
        + "         N.CODNAT, N.CODCENCUS, N.CODPROJ, N.VLRNOTA, N.VLRFRETE, N.CODTIPOPER,\n"
        + "         N.STATUSNOTA, N.CODPARC, TPO.DESCROPER\n"
        + "    FROM TGFCAB N\n"
        + "   INNER JOIN TGFTOP TPO ON TPO.CODTIPOPER = N.CODTIPOPER AND TPO.DHALTER = N.DHTIPOPER\n"
        + "   WHERE N.TIPMOV = 'C'\n"
        + "     AND N.VLRFRETE <> 0\n"
        + "     AND NVL(TPO.CODMODDOC, 0) <> 57\n"
        + "     " + w.join("\n     ") + "\n"
        + "),\n"
        + "VINC AS (\n"
        + "  SELECT DISTINCT NF.NUNOTA AS NUNOTANF, CTE.NUNOTA AS NUNOTACTE, NVL(CTE.VLRNOTA, 0) AS VLRCTE\n"
        + "    FROM NF\n"
        + "   INNER JOIN TGFNCT NCT ON NCT.CHAVENFE = NF.CHAVENFE\n"
        + "   INNER JOIN TGFCAB CTE ON CTE.NUNOTA = NCT.NUNOTA AND CTE.TIPMOV = 'C'\n"
        + "   WHERE NF.CHAVENFE IS NOT NULL\n"
        + "     AND TO_NUMBER(NCT.NUMERO) = NF.NUMNOTA\n"
        + "),\n"
        //CTEs DO PERIODO QUE POSSUEM RATEIO (TGFRAV ORIGEM 'E')
        + "RATCTE AS (\n"
        + "  SELECT RAV.NUFIN AS NUNOTACTE\n"
        + "    FROM (SELECT DISTINCT NUNOTACTE FROM VINC) V\n"
        + "   INNER JOIN TGFRAV RAV ON RAV.ORIGEM = 'E' AND RAV.NUFIN = V.NUNOTACTE\n"
        + "   GROUP BY RAV.NUFIN\n"
        + "),\n"
        + "RESUMO AS (\n"
        + "  SELECT V.NUNOTANF, COUNT(*) AS QTDCTE, SUM(V.VLRCTE) AS VLRCTE,\n"
        + "         SUM(CASE WHEN RC.NUNOTACTE IS NULL THEN 1 ELSE 0 END) AS QTDCTESEMRAT\n"
        + "    FROM VINC V\n"
        + "    LEFT JOIN RATCTE RC ON RC.NUNOTACTE = V.NUNOTACTE\n"
        + "   GROUP BY V.NUNOTANF\n"
        + ")\n"
        + "SELECT N.NUNOTA, N.NUMNOTA, N.SERIENOTA, N.CODEMP, N.CHAVENFE AS CHAVE,\n"
        + "       TO_CHAR(N.DTNEG, 'DD/MM/YYYY') AS DTNEG, TO_CHAR(N.DTENTSAI, 'DD/MM/YYYY') AS DTENTSAI,\n"
        + "       N.CODNAT, NAT.DESCRNAT, N.CODCENCUS, CUS.DESCRCENCUS, N.CODPROJ, PRJ.IDENTIFICACAO AS DESCRPROJ,\n"
        + "       N.VLRNOTA, NVL(N.VLRFRETE, 0) AS VLRFRETE, N.CODTIPOPER, N.DESCROPER,\n"
        + "       CASE WHEN N.STATUSNOTA = 'L' THEN 'Sim' ELSE 'Não' END AS CONFIRMADA,\n"
        + "       N.CODPARC, PAR.NOMEPARC,\n"
        + "       NVL(R.QTDCTE, 0) AS QTDCTE, NVL(R.VLRCTE, 0) AS VLRCTE, NVL(R.QTDCTESEMRAT, 0) AS QTDCTESEMRAT\n"
        + "  FROM NF N\n"
        + "  " + (f.apenasCte || f.apenasSemRat ? "INNER" : "LEFT") + " JOIN RESUMO R ON R.NUNOTANF = N.NUNOTA\n"
        + " INNER JOIN TGFPAR PAR ON PAR.CODPARC = N.CODPARC\n"
        + "  LEFT JOIN TGFNAT NAT ON NAT.CODNAT = N.CODNAT\n"
        + "  LEFT JOIN TSICUS CUS ON CUS.CODCENCUS = N.CODCENCUS\n"
        + "  LEFT JOIN TCSPRJ PRJ ON PRJ.CODPROJ = N.CODPROJ\n"
        + (f.apenasSemRat ? " WHERE R.QTDCTESEMRAT > 0\n" : "")
        + ") X\n"
        + "WHERE ROWNUM <= " + (CFG.MAX_LINHAS + 1);
    },

    //CTE(S) VINCULADO(S) A NF (MESMO JOIN DO cabEPJ, INVERTIDO)
    ctes: function(nuNotaNF){
      return "SELECT " + SQL.colunas("NVL(N.CHAVECTE, N.CHAVENFE)") + ",\n"
        + "(SELECT COUNT(1) FROM TGFRAV RAV WHERE RAV.ORIGEM = 'E' AND RAV.NUFIN = N.NUNOTA) AS QTDRAT,\n"
        + "(SELECT COUNT(1) FROM TGFNCT NC2 WHERE NC2.NUNOTA = N.NUNOTA) AS QTDNF\n"
        + "FROM TGFCAB N\n"
        + SQL.joins()
        + "WHERE N.TIPMOV = 'C'\n"
        + "AND TPO.CODMODDOC = 57\n"
        + "AND N.NUNOTA IN (SELECT NCT.NUNOTA\n"
        + "                   FROM TGFNCT NCT\n"
        + "                   INNER JOIN TGFCAB NF ON NF.NUMNOTA = TO_NUMBER(NCT.NUMERO) AND NF.CHAVENFE = NCT.CHAVENFE\n"
        + "                  WHERE NF.NUNOTA = " + int(nuNotaNF) + ")\n"
        + "ORDER BY N.DTNEG, N.NUNOTA";
    },

    //RATEIO (TGFRAV ORIGEM 'E') DE TODAS AS NFs DO CTE + RATEIO DO CTE.
    //NOTA SEM RATEIO ENTRA COM 100% NA NATUREZA/CR/PROJETO DO CABECALHO (MESMA REGRA DO replicaRateioNFxCTE)
    rateio: function(nuNotaCTe){
      var cte = int(nuNotaCTe);
      var linhas = function(origem){
        return "SELECT '" + origem + "' AS ORIGEM, N.NUNOTA, N.NUMNOTA, NVL(N.VLRNOTA, 0) AS VLRNOTA,\n"
          + "CASE WHEN RAV.NUFIN IS NULL THEN 'S' ELSE 'N' END AS SEMRATEIO,\n"
          + "NVL(RAV.CODNAT, N.CODNAT) AS CODNAT, NAT.DESCRNAT,\n"
          + "NVL(RAV.CODCENCUS, N.CODCENCUS) AS CODCENCUS, CUS.DESCRCENCUS,\n"
          + "NVL(RAV.CODPROJ, N.CODPROJ) AS CODPROJ, PRJ.IDENTIFICACAO AS DESCRPROJ,\n"
          + "NVL(RAV.PERCRATEIO, 100) AS PERCRATEIO,\n"
          + "ROUND(NVL(N.VLRNOTA, 0) * NVL(RAV.PERCRATEIO, 100) / 100, 2) AS VLRRATEIO,\n"
          + "NVL(RAV.CODPARC, N.CODPARC) AS CODPARC\n"
          + "FROM TGFCAB N\n"
          + "LEFT JOIN TGFRAV RAV ON RAV.ORIGEM = 'E' AND RAV.NUFIN = N.NUNOTA\n"
          + "LEFT JOIN TGFNAT NAT ON NAT.CODNAT = NVL(RAV.CODNAT, N.CODNAT)\n"
          + "LEFT JOIN TSICUS CUS ON CUS.CODCENCUS = NVL(RAV.CODCENCUS, N.CODCENCUS)\n"
          + "LEFT JOIN TCSPRJ PRJ ON PRJ.CODPROJ = NVL(RAV.CODPROJ, N.CODPROJ)\n";
      };
      return linhas("NF")
        + "WHERE N.NUNOTA IN (SELECT NF.NUNOTA\n"
        + "                     FROM TGFNCT NCT\n"
        + "                     INNER JOIN TGFCAB NF ON NF.NUMNOTA = TO_NUMBER(NCT.NUMERO) AND NF.CHAVENFE = NCT.CHAVENFE AND NF.TIPMOV = 'C'\n"
        + "                    WHERE NCT.NUNOTA = " + cte + ")\n"
        + "UNION ALL\n"
        + linhas("CTE")
        + "WHERE N.NUNOTA = " + cte + "\n"
        + "ORDER BY ORIGEM DESC, NUNOTA, PERCRATEIO DESC";
    }
  };

  /* =========================================================================
     UTILITARIOS
     ========================================================================= */
  var $ = function(id){ return document.getElementById(id); };
  var DEMO = typeof window.executeQuery !== 'function';

  function int(v){
    var n = parseInt(v, 10);
    if(isNaN(n)) throw new Error('Valor numérico inválido: ' + v);
    return n;
  }
  //yyyy-mm-dd (input date) -> TO_DATE('dd/mm/yyyy')
  function toDateSql(iso){
    var m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(iso || '');
    if(!m) throw new Error('Data inválida: ' + iso);
    return "TO_DATE('" + m[3] + "/" + m[2] + "/" + m[1] + "', 'DD/MM/YYYY')";
  }
  function isoDate(d){
    var p = function(n){ return (n < 10 ? '0' : '') + n; };
    return d.getFullYear() + '-' + p(d.getMonth() + 1) + '-' + p(d.getDate());
  }
  function esc(v){
    if(v === null || v === undefined) return '';
    return String(v).replace(/[&<>"']/g, function(c){ return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]; });
  }
  function num(v){ var n = typeof v === 'number' ? v : parseFloat(String(v === null || v === undefined ? '' : v).replace(',', '.')); return isNaN(n) ? 0 : n; }
  var fmtMoney = new Intl.NumberFormat('pt-BR', {minimumFractionDigits:2, maximumFractionDigits:2});
  var fmtPerc = new Intl.NumberFormat('pt-BR', {minimumFractionDigits:2, maximumFractionDigits:4});
  var fmtInt = new Intl.NumberFormat('pt-BR');
  function money(v){ return fmtMoney.format(num(v)); }
  function brl(v){ return 'R$ ' + money(v); }
  function perc(v){ return fmtPerc.format(num(v)) + '%'; }
  function dateKey(s){ var m = /^(\d{2})\/(\d{2})\/(\d{4})/.exec(s || ''); return m ? m[3] + m[2] + m[1] : ''; }
  function codDesc(cod, desc){
    if(cod === null || cod === undefined || cod === '') return '';
    return '<span class="cd">' + esc(cod) + '</span>' + esc(desc || '');
  }
  function codDescTxt(cod, desc){ return (cod === null || cod === undefined || cod === '') ? '' : cod + ' - ' + (desc || ''); }

  /* NORMALIZA O RETORNO DO executeQuery PARA [{COLUNA: valor}] COM CHAVES EM MAIUSCULO.
     ACEITA OS FORMATOS CONHECIDOS DO SANKHYA:
     - ARRAY DE OBJETOS                         [{"NUNOTA":1}]
     - METADADOS + LINHAS EM ARRAY              {"fieldsMetadata":[{"name":"NUNOTA"}],"rows":[[1]]}
     - ENVELOPADO EM responseBody / OUTROS NIVEIS
     - VALORES NO PADRAO XML->JSON DO SANKHYA   {"NUNOTA":{"$":"1"}}
     - STRING XML (<rows><row>...</row></rows>) */
  var CHAVES_LINHAS = ['rows', 'row', 'data', 'records', 'result', 'resultSet', 'resultset', 'entities', 'entity'];
  var CHAVES_META = ['fieldsMetadata', 'fieldsMetaData', 'fieldMetadata', 'metadata', 'metaData', 'columns', 'fields', 'campos'];

  function unwrap(v){
    if(v && typeof v === 'object' && !Array.isArray(v) && Object.prototype.hasOwnProperty.call(v, '$')) return v.$;
    return v;
  }
  function nomeColuna(m, i){
    m = unwrap(m);
    if(typeof m === 'string') return m;
    if(m && typeof m === 'object') return unwrap(m.name || m.fieldName || m.nome || m.label || m.description || m.columnName) || ('C' + i);
    return 'C' + i;
  }
  //PROCURA O PRIMEIRO ARRAY CUJA CHAVE ESTA NA LISTA (NO NIVEL ATUAL E DEPOIS NOS NIVEIS ABAIXO)
  function acha(d, chaves, prof){
    if(!d || typeof d !== 'object' || prof > 5) return undefined;
    for(var i = 0; i < chaves.length; i++){
      if(Object.prototype.hasOwnProperty.call(d, chaves[i]) && Array.isArray(d[chaves[i]])) return d[chaves[i]];
    }
    var ks = Object.keys(d);
    for(var j = 0; j < ks.length; j++){
      var r = acha(d[ks[j]], chaves, (prof || 0) + 1);
      if(r !== undefined) return r;
    }
    return undefined;
  }
  function primeiroArray(d, prof){
    if(Array.isArray(d)) return d;
    if(!d || typeof d !== 'object' || prof > 5) return null;
    var ks = Object.keys(d);
    for(var j = 0; j < ks.length; j++){
      var r = primeiroArray(d[ks[j]], (prof || 0) + 1);
      if(r) return r;
    }
    return null;
  }
  function xmlParaLinhas(txt){
    var doc = new DOMParser().parseFromString(txt, 'text/xml');
    var metas = [].slice.call(doc.getElementsByTagName('fieldMetadata')).concat([].slice.call(doc.getElementsByTagName('field')));
    var nomes = metas.map(function(m, i){ return m.getAttribute('name') || m.getAttribute('nome') || m.textContent || ('C' + i); });
    return [].slice.call(doc.getElementsByTagName('row')).map(function(row){
      var o = {};
      [].slice.call(row.children).forEach(function(c, i){
        var k = /^f\d+$/i.test(c.tagName) && nomes.length ? nomes[parseInt(c.tagName.substring(1), 10)] : (nomes[i] && /^(f|c|v)$/i.test(c.tagName) ? nomes[i] : c.tagName);
        o[String(k).toUpperCase()] = c.textContent;
      });
      return o;
    });
  }

  //RETORNA AS LINHAS; A PROPRIEDADE "reconhecido" INDICA SE O FORMATO FOI ENTENDIDO
  //(UM ARRAY VAZIO RECONHECIDO = CONSULTA SEM REGISTROS; NAO RECONHECIDO = TENTA OUTRA FORMA DE CONSULTA)
  function normalize(raw){
    var vazio = []; vazio.reconhecido = false;
    if(raw === null || raw === undefined || raw === '') return vazio;
    var d = raw;
    if(d && d.nodeType) d = new XMLSerializer().serializeToString(d);
    if(typeof d === 'string'){
      var t = d.trim();
      if(t.charAt(0) === '<'){
        var x = xmlParaLinhas(t);
        x.reconhecido = x.length > 0 || /<rows|<fieldsMetadata|<fieldMetadata/i.test(t);
        return x;
      }
      d = JSON.parse(t);
      if(typeof d === 'string') d = JSON.parse(d); //JSON SERIALIZADO DUAS VEZES
    }
    var linhas = Array.isArray(d) ? d : acha(d, CHAVES_LINHAS, 0);
    var meta = Array.isArray(d) ? null : acha(d, CHAVES_META, 0);
    var reconhecido = !!linhas;
    if(!linhas){
      linhas = primeiroArray(d, 0) || [];
      if(linhas === meta) linhas = [];
      reconhecido = linhas.length > 0;
    }
    var nomes = meta ? meta.map(nomeColuna) : null;

    var out = linhas.map(function(r){
      var o = {};
      if(Array.isArray(r)){
        r.forEach(function(v, i){ o[String(nomes && nomes[i] ? nomes[i] : 'C' + i).toUpperCase()] = unwrap(v); });
      }else if(r && typeof r === 'object'){
        Object.keys(r).forEach(function(k){ o[k.toUpperCase()] = unwrap(r[k]); });
      }
      return o;
    });
    out.reconhecido = reconhecido;
    return out;
  }

  /* CONSULTA DIRETA NO SERVICO DbExplorerSP.executeQuery (JSON), MESMA SESSAO DO USUARIO.
     USADA QUANDO O executeQuery DO COMPONENTE FALHA OU DEVOLVE UM FORMATO NAO RECONHECIDO.
     RETORNO: {"status":"1","responseBody":{"fieldsMetadata":[{"name":...}],"rows":[[...]]}} */
  function mgeSession(){
    var re = /[?&]mgeSession=([^&#]+)/;
    var m = re.exec(location.search);
    try{ if(!m) m = re.exec(window.parent.location.search); }catch(e){}
    try{ if(!m) m = re.exec(window.top.location.search); }catch(e){}
    return m ? m[1] : '';
  }
  function decodeMsg(s){
    if(!s) return '';
    s = String(s);
    if(/^[A-Za-z0-9+\/=\s]+$/.test(s) && s.length % 4 === 0){
      try{ return decodeURIComponent(escape(atob(s.replace(/\s/g, '')))); }catch(e){}
    }
    return s;
  }
  function viaDbExplorer(sql){
    var sess = mgeSession();
    var url = '/mge/service.sbr?serviceName=DbExplorerSP.executeQuery&outputType=json' + (sess ? '&mgeSession=' + sess : '');
    return fetch(url, {
      method: 'POST', credentials: 'include',
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: JSON.stringify({serviceName: 'DbExplorerSP.executeQuery', requestBody: {sql: sql}})
    }).then(function(r){ return r.text(); }).then(function(txt){
      var j;
      try{ j = JSON.parse(txt); }catch(e){ throw new Error('DbExplorer: resposta não é JSON (' + txt.substring(0, 200) + ')'); }
      if(String(j.status) !== '1') throw new Error('DbExplorer: ' + (decodeMsg(j.statusMessage) || 'status ' + j.status));
      return j;
    });
  }

  //DIAGNOSTICO: O ULTIMO RETORNO BRUTO DE CADA CONSULTA FICA EM window.NFXCTE_RETORNOS (VER NO CONSOLE - F12)
  window.NFXCTE_RETORNOS = {};
  window.NFXCTE_NORMALIZA = normalize;

  function runQuery(nome, sql, ctx){
    return new Promise(function(resolve, reject){
      if(DEMO){
        setTimeout(function(){ resolve(Mock.query(nome, ctx || {})); }, 220);
        return;
      }
      var info = window.NFXCTE_RETORNOS[nome] = {sql: sql, args: null, erro: null, fonte: null, dbexplorer: null};
      var log = function(fonte, rows, bruto){
        info.fonte = fonte;
        if(window.console) console.log('[NFxCTe] ' + nome + ' via ' + fonte + ': ' + rows.length + ' linha(s)', {bruto: bruto, linhas: rows});
        if(rows.length && rows[0].NUNOTA === undefined && rows[0].CODTIPOPER === undefined && rows[0].ORIGEM === undefined){
          toast('Consulta ' + nome + ': colunas não reconhecidas. Use "Ver retorno da consulta".', true);
        }
      };
      //PLANO B: SERVICO DbExplorerSP (JSON)
      var fallback = function(motivo){
        viaDbExplorer(sql).then(function(j){
          info.dbexplorer = j;
          var rows = normalize(j);
          log('DbExplorerSP', rows, j);
          resolve(rows);
        }).catch(function(e){
          info.dbexplorer = {erro: e.message};
          reject(new Error('Consulta ' + nome + ': ' + motivo + ' | ' + e.message));
        });
      };
      if(CFG.FONTE === 'dbexplorer' || typeof window.executeQuery !== 'function'){ fallback('executeQuery não utilizado'); return; }
      try{
        window.executeQuery(sql, [], function(value){
          info.args = [].slice.call(arguments);
          var rows;
          try{ rows = normalize(value); }catch(e){ rows = []; rows.reconhecido = false; }
          if(rows.reconhecido || CFG.FONTE === 'executeQuery'){ log('executeQuery', rows, value); resolve(rows); return; }
          console.warn('[NFxCTe] ' + nome + ': retorno do executeQuery não reconhecido, tentando DbExplorerSP', value);
          fallback('retorno do executeQuery não reconhecido');
        }, function(err){
          info.erro = [].slice.call(arguments);
          console.error('[NFxCTe] erro no executeQuery em ' + nome + ':', err);
          var msg = err && err.message ? err.message : (typeof err === 'object' ? JSON.stringify(err) : err);
          if(CFG.FONTE === 'executeQuery') reject(new Error('Erro na consulta ' + nome + ': ' + msg));
          else fallback('executeQuery: ' + msg);
        });
      }catch(e){ fallback('executeQuery: ' + e.message); }
    });
  }

  var toastTimer;
  function toast(msg, isErr){
    var t = $('toast');
    t.textContent = msg;
    t.className = 'toast show' + (isErr ? ' err' : '');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function(){ t.className = 'toast'; }, isErr ? 7000 : 3000);
  }
  function busy(id, on){ $(id).classList.toggle('busy', !!on); }

  //ABRE A NOTA (NF OU CTE) NA CENTRAL DE COMPRAS - MESMO FORMATO DO LINK GERADO PELO SANKHYA:
  //"/mge/system.jsp#app/" + Base64(TELA) + "/" + Base64({"NUNOTA":n, "TIPMOV":"C", "ehPedidoW":false, "CODTIPOPER":t, "TIPOPORTAL":"PC", "forceNewHash":ts}) + "&pk-refresh=" + ts
  function abrirCentral(nuNota){
    var nu = int(nuNota);
    var reg = state.nfs.concat(state.ctes).filter(function(r){ return num(r.NUNOTA) === nu; })[0] || {};
    var ts = Date.now();
    var filtro = '{"NUNOTA":' + nu + ', "TIPMOV":"C", "ehPedidoW":false'
      + (reg.CODTIPOPER !== undefined && reg.CODTIPOPER !== null && reg.CODTIPOPER !== '' ? ', "CODTIPOPER":' + int(reg.CODTIPOPER) : '')
      + ', "TIPOPORTAL":"PC", "forceNewHash":' + ts + '}';
    var link = '/mge/system.jsp#app/' + btoa(CFG.TELA_CENTRAL) + '/' + btoa(filtro) + '&pk-refresh=' + ts;
    if(DEMO){ toast('Demonstração: abriria ' + link); return; }
    try{
      window.top.location.href = link;
    }catch(e){
      window.open(link, '_blank');
    }
  }

  /* =========================================================================
     ESTADO
     ========================================================================= */
  var state = {
    tops: [], topsSel: {},
    nfs: [], nfView: [], nfSort: {k:'DTENTSAI', dir:-1}, nfSearch: '',
    nfSel: null, ctes: [], cacheCte: {}
  };

  /* =========================================================================
     COLUNAS DAS GRADES
     ========================================================================= */
  var COLS_BASE = [
    {k:'NUNOTA', t:'Nro. Único', num:true},
    {k:'NUMNOTA', t:'Nro. Nota', num:true},
    {k:'SERIENOTA', t:'Série'},
    {k:'CODEMP', t:'Cód. Empresa', num:true},
    {k:'CHAVE', t:'Chave', cls:'mono'},
    {k:'DTNEG', t:'Dt. Neg.', date:true},
    {k:'DTENTSAI', t:'Dt. Entrada/Saída', date:true},
    {k:'CODNAT', t:'Natureza', html:function(r){ return codDesc(r.CODNAT, r.DESCRNAT); }, txt:function(r){ return codDescTxt(r.CODNAT, r.DESCRNAT); }},
    {k:'CODCENCUS', t:'Centro de Resultado', html:function(r){ return codDesc(r.CODCENCUS, r.DESCRCENCUS); }, txt:function(r){ return codDescTxt(r.CODCENCUS, r.DESCRCENCUS); }},
    {k:'CODPROJ', t:'Projeto', html:function(r){ return codDesc(r.CODPROJ, r.DESCRPROJ); }, txt:function(r){ return codDescTxt(r.CODPROJ, r.DESCRPROJ); }},
    {k:'VLRNOTA', t:'Valor da Nota', num:true, money:true},
    {k:'CODTIPOPER', t:'Cód. TOP', num:true},
    {k:'DESCROPER', t:'Tipo Operação'},
    {k:'CONFIRMADA', t:'Confirmada?', html:function(r){ return r.CONFIRMADA === 'Sim' ? '<span class="badge ok">Sim</span>' : '<span class="badge no">Não</span>'; }},
    {k:'CODPARC', t:'Cód. Parceiro', num:true},
    {k:'NOMEPARC', t:'Parceiro'}
  ];

  //NF: COLUNAS BASE + FRETE + STATUS DO CTE (LOGO APOS O VALOR DA NOTA)
  var COLS_NF = (function(){
    var c = COLS_BASE.slice();
    c[4] = {k:'CHAVE', t:'Chave NF-e', cls:'mono'};
    var i = c.map(function(x){ return x.k; }).indexOf('VLRNOTA') + 1;
    c.splice(i, 0,
      {k:'VLRFRETE', t:'Valor Frete', num:true, money:true},
      {k:'QTDCTE', t:'CT-e', num:true, html:function(r){
        var q = num(r.QTDCTE);
        if(!q) return '<span class="badge warn">Sem CT-e</span>';
        var sr = num(r.QTDCTESEMRAT);
        return '<span class="badge ok">' + q + ' vinculado' + (q > 1 ? 's' : '') + '</span>'
          + (sr ? ' <span class="badge err" title="CT-e sem rateio (TGFRAV)">' + (q > 1 ? sr + ' ' : '') + 'sem rateio</span>' : '');
      }, txt:function(r){ return num(r.QTDCTE) + (num(r.QTDCTESEMRAT) ? ' (' + num(r.QTDCTESEMRAT) + ' sem rateio)' : ''); }}
    );
    return c;
  })();

  var COLS_CTE = (function(){
    var c = COLS_BASE.slice();
    c[4] = {k:'CHAVE', t:'Chave CT-e', cls:'mono'};
    c.unshift({k:'_RAT', t:'', nosort:true, html:function(r){
      return '<div class="acts">'
        + '<button class="btn-rat" data-rat="' + esc(r.NUNOTA) + '" title="Comparar o rateio NF x CT-e"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14"/><path d="m13 6 6 6-6 6"/></svg>Ver Rateio</button>'
        + '<button class="btn sm" data-open="' + esc(r.NUNOTA) + '" title="Abrir o CT-e na Central"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 4h6v6"/><path d="M20 4 10 14"/><path d="M18 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h5"/></svg>Abrir CT-e</button>'
        + '</div>';
    }});
    c.splice(2, 0, {k:'QTDRAT', t:'Rateio', html:function(r){
      return num(r.QTDRAT) > 0 ? '<span class="badge blue">' + num(r.QTDRAT) + ' linha' + (num(r.QTDRAT) > 1 ? 's' : '') + '</span>' : '<span class="badge no">Sem rateio</span>';
    }});
    return c;
  })();

  function cellHtml(col, r){
    if(col.html) return col.html(r);
    var v = r[col.k];
    if(col.money) return money(v);
    if(col.num && v !== null && v !== undefined && v !== '') return esc(v);
    return esc(v);
  }
  function cellTxt(col, r){
    if(col.txt) return col.txt(r);
    var v = r[col.k];
    return v === null || v === undefined ? '' : String(v);
  }

  function renderTable(cols, rows, opts){
    opts = opts || {};
    var h = '<table class="grid"><thead><tr>';
    cols.forEach(function(c){
      var sorted = opts.sort && opts.sort.k === c.k;
      var arrow = c.nosort ? '' : '<span class="ar">' + (sorted ? (opts.sort.dir > 0 ? '&#9650;' : '&#9660;') : '&#8693;') + '</span>';
      h += '<th data-k="' + c.k + '" class="' + (c.num ? 'num ' : '') + (sorted ? 'sorted' : '') + '">' + esc(c.t) + arrow + '</th>';
    });
    h += '</tr></thead><tbody>';
    rows.forEach(function(r){
      var sel = opts.selKey && String(r.NUNOTA) === String(opts.selKey);
      h += '<tr data-nu="' + esc(r.NUNOTA) + '"' + (sel ? ' class="sel"' : '') + '>';
      cols.forEach(function(c){
        var title = c.html ? '' : ' title="' + esc(cellTxt(c, r)) + '"';
        h += '<td class="' + (c.num ? 'num ' : '') + (c.cls || '') + '"' + title + '>' + cellHtml(c, r) + '</td>';
      });
      h += '</tr>';
    });
    h += '</tbody>';
    if(opts.foot) h += '<tfoot><tr>' + opts.foot + '</tr></tfoot>';
    return h + '</table>';
  }

  function emptyHtml(icon, title, text){
    var icons = {
      doc:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"/><path d="M14 3v6h6"/><path d="M8 13h8M8 17h5"/></svg>',
      truck:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M3 7h11v9H3z"/><path d="M14 10h4l3 3v3h-7"/><circle cx="7" cy="18" r="2"/><circle cx="17" cy="18" r="2"/></svg>',
      click:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="m9 9 5 12 1.8-5.2L21 14z"/><path d="M7.2 2.2 8 5.1M5.1 8 2.2 7.2M14 4.1 12 6.2M6.2 12l-2.1 2"/></svg>'
    };
    return '<div class="empty">' + icons[icon] + '<b>' + esc(title) + '</b><div>' + esc(text) + '</div></div>';
  }

  /* =========================================================================
     FILTROS
     ========================================================================= */
  function defaultFilters(){
    var hoje = new Date();
    $('dtEntIni').value = isoDate(new Date(hoje.getFullYear(), hoje.getMonth(), 1));
    $('dtEntFin').value = isoDate(hoje);
    $('dtNegIni').value = '';
    $('dtNegFin').value = '';
    $('apenasCte').checked = false;
    $('apenasSemRat').checked = false;
    state.topsSel = {};
    renderTops();
  }

  function readFilters(){
    var f = {
      entIni: $('dtEntIni').value, entFin: $('dtEntFin').value,
      negIni: $('dtNegIni').value, negFin: $('dtNegFin').value,
      tops: Object.keys(state.topsSel).filter(function(k){ return state.topsSel[k]; }).map(int),
      apenasCte: $('apenasCte').checked,
      apenasSemRat: $('apenasSemRat').checked
    };
    if(f.entIni && f.entFin && f.entIni > f.entFin) throw new Error('Período de entrada: data inicial maior que a final.');
    if(f.negIni && f.negFin && f.negIni > f.negFin) throw new Error('Período de negociação: data inicial maior que a final.');
    if(!f.entIni && !f.entFin && !f.negIni && !f.negFin) throw new Error('Informe ao menos um período (entrada ou negociação).');
    return f;
  }

  //MULTILIST DE TOPs
  function renderTops(){
    var term = ($('msTopSearch').value || '').toLowerCase();
    var html = '';
    state.tops.forEach(function(t){
      var label = t.CODTIPOPER + ' ' + (t.DESCROPER || '');
      if(term && label.toLowerCase().indexOf(term) < 0) return;
      var ck = state.topsSel[t.CODTIPOPER] ? ' checked' : '';
      html += '<label class="ms-item"><input type="checkbox" value="' + esc(t.CODTIPOPER) + '"' + ck + '><b>' + esc(t.CODTIPOPER) + '</b><span>' + esc(t.DESCROPER) + '</span></label>';
    });
    $('msTopList').innerHTML = html || ('<div class="muted" style="padding:8px">Nenhuma TOP encontrada.</div>'
      + (DEMO || state.tops.length ? '' : '<div style="padding:0 8px 6px"><button type="button" class="btn sm" id="btnDiagTop">Ver retorno da consulta</button></div>'));

    var sel = state.tops.filter(function(t){ return state.topsSel[t.CODTIPOPER]; });
    var btn = $('msTopBtn');
    btn.querySelector('.txt').textContent = !sel.length ? 'Todas as TOPs'
      : sel.length === 1 ? sel[0].CODTIPOPER + ' - ' + sel[0].DESCROPER
      : sel.map(function(t){ return t.CODTIPOPER; }).join(', ');
    var cnt = btn.querySelector('.cnt');
    cnt.style.display = sel.length > 1 ? '' : 'none';
    cnt.textContent = sel.length;
  }

  function loadTops(){
    return runQuery('tops', SQL.tops()).then(function(rows){
      state.tops = rows;
      renderTops();
    });
  }

  /* =========================================================================
     NOTAS DE COMPRA
     ========================================================================= */
  function loadNFs(){
    var f;
    try{ f = readFilters(); }catch(e){ toast(e.message, true); return Promise.resolve(); }
    busy('cardNF', true);
    return runQuery('nfs', SQL.nfs(f), f).then(function(rows){
      if(rows.length > CFG.MAX_LINHAS){
        rows = rows.slice(0, CFG.MAX_LINHAS);
        toast('Mais de ' + fmtInt.format(CFG.MAX_LINHAS) + ' notas no período. Refine os filtros.', true);
      }
      state.nfs = rows;
      //MANTEM A NF SELECIONADA SE ELA CONTINUAR NA LISTA
      if(state.nfSel && !rows.some(function(r){ return String(r.NUNOTA) === String(state.nfSel.NUNOTA); })){
        state.nfSel = null; state.ctes = [];
      }
      state.cacheCte = {};
      applyNfView();
      renderKpis();
      if(state.nfSel){
        state.nfSel = rows.filter(function(r){ return String(r.NUNOTA) === String(state.nfSel.NUNOTA); })[0];
        loadCTes(state.nfSel);
      }else{
        renderCTes();
      }
      $('lastUpd').textContent = (DEMO ? 'Modo demonstração · ' : '') + 'Atualizado às ' + new Date().toLocaleTimeString('pt-BR', {hour:'2-digit', minute:'2-digit'});
    }).catch(function(e){
      toast(e.message, true);
    }).then(function(){ busy('cardNF', false); });
  }

  function applyNfView(){
    var term = state.nfSearch.toLowerCase();
    var rows = state.nfs;
    if(term){
      rows = rows.filter(function(r){
        return COLS_NF.some(function(c){ return cellTxt(c, r).toLowerCase().indexOf(term) >= 0; });
      });
    }
    var s = state.nfSort, col = COLS_NF.filter(function(c){ return c.k === s.k; })[0] || {};
    rows = rows.slice().sort(function(a, b){
      var x = a[s.k], y = b[s.k];
      if(col.date){ x = dateKey(x); y = dateKey(y); }
      else if(col.num){ x = num(x); y = num(y); }
      else { x = String(x || '').toLowerCase(); y = String(y || '').toLowerCase(); }
      return (x > y ? 1 : x < y ? -1 : 0) * s.dir || (num(b.NUNOTA) - num(a.NUNOTA));
    });
    state.nfView = rows;
    renderNFs();
  }

  function renderNFs(){
    var rows = state.nfView;
    $('nfCount').textContent = fmtInt.format(rows.length) + (rows.length !== state.nfs.length ? ' de ' + fmtInt.format(state.nfs.length) : '');
    if(!state.nfs.length){
      $('nfWrap').innerHTML = emptyHtml('doc', 'Nenhuma nota encontrada', 'Ajuste os filtros de período, TOP ou CT-e e clique em Aplicar.')
        + (DEMO ? '' : '<div style="text-align:center;margin-top:-20px"><button class="btn sm" id="btnDiag">Ver retorno da consulta</button></div>');
      return;
    }
    if(!rows.length){
      $('nfWrap').innerHTML = emptyHtml('doc', 'Nada corresponde ao filtro', 'Nenhuma nota contém "' + state.nfSearch + '".');
      return;
    }
    var tVlr = 0, tFrete = 0;
    rows.forEach(function(r){ tVlr += num(r.VLRNOTA); tFrete += num(r.VLRFRETE); });
    var foot = '';
    COLS_NF.forEach(function(c, i){
      foot += '<td class="' + (c.num ? 'num' : '') + '">'
        + (i === 0 ? 'Total' : c.k === 'VLRNOTA' ? money(tVlr) : c.k === 'VLRFRETE' ? money(tFrete) : '') + '</td>';
    });
    $('nfWrap').innerHTML = renderTable(COLS_NF, rows, {sort:state.nfSort, selKey:state.nfSel && state.nfSel.NUNOTA, foot:foot});
  }

  function renderKpis(){
    var rows = state.nfs, vlr = 0, frete = 0, com = 0, freteCom = 0, semRat = 0;
    rows.forEach(function(r){
      vlr += num(r.VLRNOTA); frete += num(r.VLRFRETE);
      if(num(r.QTDCTE) > 0){ com++; freteCom += num(r.VLRFRETE); }
      if(num(r.QTDCTESEMRAT) > 0) semRat++;
    });
    var sem = rows.length - com;
    var pc = function(a){ return rows.length ? Math.round(a * 100 / rows.length) + '% das notas' : ' '; };
    $('kQtd').textContent = fmtInt.format(rows.length);
    $('kVlr').textContent = brl(vlr);
    $('kVlrH').textContent = rows.length ? 'média ' + brl(vlr / rows.length) : ' ';
    $('kFrete').textContent = brl(frete);
    $('kFreteH').textContent = vlr ? fmtMoney.format(frete * 100 / vlr) + '% do valor das notas' : ' ';
    $('kCom').textContent = fmtInt.format(com);
    $('kComH').textContent = rows.length ? pc(com) + ' · ' + fmtInt.format(semRat) + ' com CT-e sem rateio' : ' ';
    $('kSem').textContent = fmtInt.format(sem);
    $('kSemH').textContent = rows.length ? pc(sem) + ' · frete ' + brl(frete - freteCom) : ' ';
  }

  /* =========================================================================
     CT-e VINCULADO
     ========================================================================= */
  function selectNF(nu){
    var r = state.nfs.filter(function(x){ return String(x.NUNOTA) === String(nu); })[0];
    if(!r || (state.nfSel && String(state.nfSel.NUNOTA) === String(nu))) return;
    state.nfSel = r;
    var trs = $('nfWrap').querySelectorAll('tbody tr'), alvo = null;
    for(var i = 0; i < trs.length; i++){
      var on = trs[i].getAttribute('data-nu') === String(nu);
      trs[i].classList.toggle('sel', on);
      if(on) alvo = trs[i];
    }
    $('split').classList.add('has-cte');
    //A LISTA DE NOTAS DIMINUI QUANDO O PAINEL DO CTE ABRE: MANTEM A LINHA SELECIONADA VISIVEL
    if(alvo) setTimeout(function(){
      var wrap = $('nfWrap');
      wrap.scrollTop = Math.max(0, alvo.offsetTop - (wrap.clientHeight - alvo.offsetHeight) / 2);
    }, 0);
    state.ctes = [];
    renderCTes();
    loadCTes(r);
  }

  //FECHA O PAINEL DO CTE E VOLTA A LISTA COMPLETA DE NOTAS
  function closeCTe(){
    state.nfSel = null; state.ctes = [];
    $('split').classList.remove('has-cte');
    var sel = $('nfWrap').querySelector('tbody tr.sel');
    if(sel) sel.classList.remove('sel');
    renderCTes();
  }

  function loadCTes(nf){
    var key = String(nf.NUNOTA);
    if(state.cacheCte[key]){ state.ctes = state.cacheCte[key]; renderCTes(); return; }
    busy('cardCTe', true);
    runQuery('ctes', SQL.ctes(nf.NUNOTA), {nunota:nf.NUNOTA}).then(function(rows){
      state.cacheCte[key] = rows;
      if(state.nfSel && String(state.nfSel.NUNOTA) === key){ state.ctes = rows; renderCTes(); }
    }).catch(function(e){ toast(e.message, true); })
      .then(function(){ busy('cardCTe', false); });
  }

  function renderCTes(){
    var nf = state.nfSel, w = $('cteWrap');
    $('split').classList.toggle('has-cte', !!nf);
    if(!nf){
      $('cteCount').textContent = '0';
      $('cteNfRef').textContent = '';
      w.innerHTML = '';
      return;
    }
    $('cteNfRef').textContent = '· NF ' + nf.NUMNOTA + ' (NU ' + nf.NUNOTA + ')';
    var rows = state.ctes, totCte = 0;
    rows.forEach(function(r){ totCte += num(r.VLRNOTA); });
    var dif = totCte - num(nf.VLRFRETE);
    var difCls = !rows.length ? 'muted' : Math.abs(dif) < 0.01 ? '' : 'diff-pos';
    $('cteCount').textContent = rows.length;

    var esq = '<div class="nfbox"><div class="t"><span>NF ' + esc(nf.NUMNOTA) + (nf.SERIENOTA ? '/' + esc(nf.SERIENOTA) : '') + ' <span class="muted" style="font-weight:500">· NU ' + esc(nf.NUNOTA) + '</span></span></div>'
      + '<div class="p" title="' + esc(nf.NOMEPARC) + '">' + esc(nf.CODPARC) + ' - ' + esc(nf.NOMEPARC) + '</div>'
      + '<div class="p">Entrada ' + esc(nf.DTENTSAI || '-') + ' · Valor ' + money(nf.VLRNOTA) + '</div>'
      + '<div class="cmp"><div><span>Frete NF</span><b>' + money(nf.VLRFRETE) + '</b></div>'
      + '<div><span>Valor CT-e</span><b>' + (rows.length ? money(totCte) : '-') + '</b></div>'
      + '<div><span>Diferença</span><b class="' + difCls + '">' + (rows.length ? money(dif) : '-') + '</b></div></div></div>';

    var dir = rows.length
      ? renderTable(COLS_CTE, rows, {})
      : emptyHtml('truck', 'Nenhum CT-e vinculado', 'Não há CT-e com esta nota na aba de notas do conhecimento (TGFNCT).');
    w.innerHTML = '<div class="cte-grid"><div class="cte-l">' + esq + '</div><div class="cte-r">' + dir + '</div></div>';
  }

  /* =========================================================================
     POP UP RATEIO NF x CT-e
     ========================================================================= */
  function chaveRateio(r){ return [num(r.CODNAT), num(r.CODCENCUS), num(r.CODPROJ)].join('|'); }

  function openRateio(nuCte){
    var cte = state.ctes.filter(function(c){ return String(c.NUNOTA) === String(nuCte); })[0] || {NUNOTA:nuCte};
    $('ratTitle').innerHTML = 'Rateio NF x CT-e <span class="muted" style="font-weight:500;font-size:13px">CT-e ' + esc(cte.NUMNOTA || '') + ' · NU ' + esc(cte.NUNOTA) + '</span>';
    $('ratSub').textContent = (cte.NOMEPARC ? cte.CODPARC + ' - ' + cte.NOMEPARC + ' · ' : '') + 'Valor CT-e ' + brl(cte.VLRNOTA);
    $('ratBody').innerHTML = '<div style="height:160px"></div>';
    $('ovRat').classList.add('open');
    $('ratLoading').style.display = 'flex';
    runQuery('rateio', SQL.rateio(nuCte), {nunotaCte:nuCte}).then(function(rows){
      renderRateio(rows);
    }).catch(function(e){
      $('ratBody').innerHTML = emptyHtml('doc', 'Erro ao carregar o rateio', e.message);
    }).then(function(){ $('ratLoading').style.display = 'none'; });
  }

  function closeRateio(){ $('ovRat').classList.remove('open'); }

  //DIAGNOSTICO: MOSTRA NA TELA O RETORNO BRUTO DO executeQuery (PARA COPIAR E AJUSTAR A LEITURA)
  function textoSeguro(v){
    var vistos = [];
    try{
      if(v && v.nodeType) return new XMLSerializer().serializeToString(v);
      return JSON.stringify(v, function(k, x){
        if(x && x.nodeType) return '[XML] ' + new XMLSerializer().serializeToString(x);
        if(typeof x === 'function') return '[function]';
        if(x && typeof x === 'object'){ if(vistos.indexOf(x) >= 0) return '[circular]'; vistos.push(x); }
        return x;
      }, 1);
    }catch(e){ return 'Falha ao serializar: ' + e.message + ' | ' + String(v); }
  }
  function showDiag(){
    var r = window.NFXCTE_RETORNOS, txt = '';
    Object.keys(r).forEach(function(nome){
      var i = r[nome];
      txt += '===== ' + nome + ' =====\n'
        + 'executeQuery: ' + (typeof window.executeQuery) + '\n'
        + 'tipo do retorno: ' + (i.args ? i.args.map(function(a){ return Object.prototype.toString.call(a); }).join(', ') : '-') + '\n'
        + 'retorno: ' + (i.args ? textoSeguro(i.args) : '(callback de sucesso não chamado)') + '\n'
        + 'erro: ' + (i.erro ? textoSeguro(i.erro) : '-') + '\n'
        + 'fonte usada: ' + (i.fonte || '-') + '\n'
        + 'DbExplorerSP: ' + (i.dbexplorer ? textoSeguro(i.dbexplorer).substring(0, 4000) : '-') + '\n\n';
    });
    $('ratTitle').textContent = 'Retorno das consultas (diagnóstico)';
    $('ratSub').textContent = 'Copie o conteúdo abaixo e envie para ajuste da leitura.';
    $('ratBody').innerHTML = '<textarea id="diagTxt" readonly style="width:100%;height:55vh;font:11.5px/1.4 var(--mono);border:1px solid var(--line);border-radius:8px;padding:10px"></textarea>'
      + '<div><button class="btn primary" id="diagCopy">Copiar</button></div>';
    $('diagTxt').value = txt.substring(0, 60000);
    $('diagCopy').onclick = function(){ $('diagTxt').select(); try{ document.execCommand('copy'); toast('Copiado.'); }catch(e){} };
    $('ratLoading').style.display = 'none';
    $('ovRat').classList.add('open');
  }

  function renderRateio(rows){
    var nfRows = rows.filter(function(r){ return r.ORIGEM === 'NF'; });
    var cteRows = rows.filter(function(r){ return r.ORIGEM === 'CTE'; });

    //RATEIO ESPERADO PARA O CTE = RATEIO DAS NFs PONDERADO PELO VLRNOTA (MESMA REGRA DO replicaRateioNFxCTE)
    var nfs = {}, totNF = 0;
    nfRows.forEach(function(r){ if(!nfs[r.NUNOTA]){ nfs[r.NUNOTA] = num(r.VLRNOTA); totNF += num(r.VLRNOTA); } });
    var qtdNF = Object.keys(nfs).length;
    var esperado = {}, atual = {}, desc = {};
    nfRows.forEach(function(r){
      var peso = totNF ? nfs[r.NUNOTA] / totNF : 1 / qtdNF;
      var k = chaveRateio(r);
      esperado[k] = (esperado[k] || 0) + num(r.PERCRATEIO) * peso;
      desc[k] = desc[k] || r;
    });
    cteRows.forEach(function(r){
      var k = chaveRateio(r);
      atual[k] = (atual[k] || 0) + num(r.PERCRATEIO);
      desc[k] = desc[k] || r;
    });
    var chaves = Object.keys(desc);
    var divergentes = {};
    chaves.forEach(function(k){
      if(Math.abs((esperado[k] || 0) - (atual[k] || 0)) > CFG.TOL_PERC) divergentes[k] = true;
    });
    var qtdDiv = Object.keys(divergentes).length;
    var nfSemRat = nfRows.length && nfRows.every(function(r){ return r.SEMRATEIO === 'S'; });
    var cteSemRat = cteRows.length && cteRows.every(function(r){ return r.SEMRATEIO === 'S'; });

    var status = !nfRows.length ? '<span class="badge warn">CT-e sem NF vinculada</span>'
      : qtdDiv ? '<span class="badge err">Divergente · ' + qtdDiv + ' linha' + (qtdDiv > 1 ? 's' : '') + '</span>'
      : '<span class="badge ok">Rateio conferido</span>';
    var t = $('ratTitle');
    if(!t.querySelector('.badge')) t.insertAdjacentHTML('beforeend', status);

    var cols = [
      {k:'ORIGEM', t:'Origem', html:function(r){
        var o = '<div style="white-space:nowrap;font-weight:600">' + (r.ORIGEM === 'NF' ? 'NF ' : 'CT-e ') + esc(r.NUMNOTA) + '</div>'
          + '<div class="muted" style="font-size:11px;white-space:nowrap">NU ' + esc(r.NUNOTA) + '</div>';
        return r.SEMRATEIO === 'S' ? o + '<span class="badge no" title="Nota sem rateio: considerado 100% no cabeçalho">cabeçalho</span>' : o;
      }},
      {k:'CODNAT', t:'Natureza', html:function(r){ return codDesc(r.CODNAT, r.DESCRNAT); }},
      {k:'CODCENCUS', t:'Centro de Resultado', html:function(r){ return codDesc(r.CODCENCUS, r.DESCRCENCUS); }},
      {k:'CODPROJ', t:'Projeto', html:function(r){ return codDesc(r.CODPROJ, r.DESCRPROJ); }},
      {k:'PERCRATEIO', t:'Perc. Rateio', num:true, html:function(r){ return perc(r.PERCRATEIO); }},
      {k:'VLRRATEIO', t:'Valor Rateio', num:true, money:true},
      {k:'CODPARC', t:'Cód. Parceiro', num:true}
    ];

    function pane(titulo, lista, marcaDiv){
      var tot = 0, totP = 0;
      lista.forEach(function(r){ tot += num(r.VLRRATEIO); totP += num(r.PERCRATEIO); });
      var html = '<div class="pane"><div class="pane-h"><span>' + titulo + '</span><span class="pill">' + lista.length + ' linha' + (lista.length !== 1 ? 's' : '') + '</span></div><div class="pane-b">';
      if(!lista.length){
        html += emptyHtml('doc', 'Sem linhas', 'Nenhuma nota encontrada.');
      }else{
        var t = renderTable(cols, lista, {});
        if(marcaDiv){
          //DESTACA AS LINHAS DO CTE QUE DIVERGEM DO ESPERADO
          var i = 0;
          t = t.replace(/<tr data-nu="[^"]*"/g, function(m){ var r = lista[i++]; return m + (divergentes[chaveRateio(r)] ? ' class="dif"' : ''); });
        }
        var foot = '<td>Total</td><td></td><td></td><td></td><td class="num">' + (qtdNF > 1 && !marcaDiv ? '' : perc(totP)) + '</td><td class="num">' + money(tot) + '</td><td></td>';
        html += t.replace('</tbody>', '</tbody><tfoot><tr>' + foot + '</tr></tfoot>');
      }
      return html + '</div></div>';
    }

    var h = '';
    if(nfSemRat && cteSemRat){
      h += '<div class="muted">NF e CT-e sem rateio: a comparação usa a natureza, o centro de resultado e o projeto do cabeçalho das notas.</div>';
    }
    h += '<div class="two">'
      + pane('Notas de Compra' + (qtdNF > 1 ? ' <span class="muted" style="font-weight:500">(' + qtdNF + ' NFs, ponderadas pelo valor)</span>' : ''), nfRows, false)
      + pane('CT-e', cteRows, true)
      + '</div>';

    //COMPARATIVO POR NATUREZA / CR / PROJETO
    chaves.sort(function(a, b){ return (esperado[b] || atual[b] || 0) - (esperado[a] || atual[a] || 0); });
    var comp = '<div class="pane"><div class="pane-h"><span>Comparativo NF x CT-e (Natureza · Centro de Resultado · Projeto)</span>'
      + (qtdDiv ? '<span class="badge err">' + qtdDiv + ' divergência' + (qtdDiv > 1 ? 's' : '') + '</span>' : '<span class="badge ok">Sem divergências</span>')
      + '</div><div class="pane-b"><table class="grid"><thead><tr><th>Natureza</th><th>Centro de Resultado</th><th>Projeto</th>'
      + '<th class="num">% esperado (NF)</th><th class="num">% no CT-e</th><th class="num">Diferença</th><th class="num">Valor esperado</th><th class="num">Valor no CT-e</th><th>Situação</th></tr></thead><tbody>';
    var vlrCte = cteRows.length ? num(cteRows[0].VLRNOTA) : 0;
    chaves.forEach(function(k){
      var d = desc[k], e = esperado[k] || 0, a = atual[k] || 0, dv = divergentes[k];
      comp += '<tr class="' + (dv ? 'dif' : 'okr') + '">'
        + '<td>' + codDesc(d.CODNAT, d.DESCRNAT) + '</td><td>' + codDesc(d.CODCENCUS, d.DESCRCENCUS) + '</td><td>' + codDesc(d.CODPROJ, d.DESCRPROJ) + '</td>'
        + '<td class="num">' + perc(e) + '</td><td class="num">' + perc(a) + '</td>'
        + '<td class="num' + (dv ? ' diff-pos' : '') + '">' + perc(a - e) + '</td>'
        + '<td class="num">' + money(vlrCte * e / 100) + '</td><td class="num">' + money(vlrCte * a / 100) + '</td>'
        + '<td class="st">' + (dv ? (!a ? '<span class="badge err">Falta no CT-e</span>' : !e ? '<span class="badge err">Não existe na NF</span>' : '<span class="badge err">% diferente</span>') : '<span class="badge ok">OK</span>') + '</td></tr>';
    });
    comp += '</tbody></table></div></div>';
    h += comp;

    $('ratBody').innerHTML = h;
  }

  /* =========================================================================
     CSV
     ========================================================================= */
  function exportCsv(){
    var rows = state.nfView;
    if(!rows.length){ toast('Não há notas para exportar.'); return; }
    var cols = COLS_NF;
    var q = function(v){ v = String(v === null || v === undefined ? '' : v); return /[";\n]/.test(v) ? '"' + v.replace(/"/g, '""') + '"' : v; };
    var lines = [cols.map(function(c){ return q(c.t); }).join(';')];
    rows.forEach(function(r){
      lines.push(cols.map(function(c){
        if(c.money) return q(money(r[c.k]).replace(/\./g, ''));
        if(c.k === 'CHAVE') return q(r.CHAVE ? '​' + r.CHAVE : '');
        return q(cellTxt(c, r));
      }).join(';'));
    });
    var blob = new Blob(['﻿' + lines.join('\r\n')], {type:'text/csv;charset=utf-8'});
    var a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = 'notas_compra_x_cte_' + isoDate(new Date()) + '.csv';
    document.body.appendChild(a); a.click(); a.remove();
    setTimeout(function(){ URL.revokeObjectURL(a.href); }, 1000);
  }

  /* =========================================================================
     EVENTOS
     ========================================================================= */
  function bind(){
    $('btnAplicar').addEventListener('click', loadNFs);
    $('apenasSemRat').addEventListener('change', loadNFs);
    $('btnLimpar').addEventListener('click', function(){ defaultFilters(); loadNFs(); });
    $('btnCsv').addEventListener('click', exportCsv);
    $('filters').addEventListener('keydown', function(e){ if(e.key === 'Enter' && e.target.id !== 'msTopSearch') loadNFs(); });
    $('apenasCte').addEventListener('change', loadNFs);

    //MULTILIST
    var ms = $('msTop');
    $('msTopBtn').addEventListener('click', function(){
      ms.classList.toggle('open');
      if(ms.classList.contains('open')) setTimeout(function(){ $('msTopSearch').focus(); }, 0);
    });
    document.addEventListener('mousedown', function(e){ if(!ms.contains(e.target)) ms.classList.remove('open'); });
    $('msTopSearch').addEventListener('input', renderTops);
    $('msTopList').addEventListener('click', function(e){
      if(e.target.closest('#btnDiagTop')){ ms.classList.remove('open'); showDiag(); }
    });
    $('msTopList').addEventListener('change', function(e){
      if(e.target.type !== 'checkbox') return;
      state.topsSel[e.target.value] = e.target.checked;
      renderTops();
    });
    $('msAll').addEventListener('click', function(){
      var term = ($('msTopSearch').value || '').toLowerCase();
      state.tops.forEach(function(t){ if(!term || (t.CODTIPOPER + ' ' + t.DESCROPER).toLowerCase().indexOf(term) >= 0) state.topsSel[t.CODTIPOPER] = true; });
      renderTops();
    });
    $('msNone').addEventListener('click', function(){ state.topsSel = {}; renderTops(); });

    //GRADE NF: 1 CLIQUE SELECIONA / 2 CLIQUES ABRE A CENTRAL / CABECALHO ORDENA
    var nfWrap = $('nfWrap');
    nfWrap.addEventListener('click', function(e){
      if(e.target.closest('#btnDiag')){ showDiag(); return; }
      var th = e.target.closest('th');
      if(th){
        var k = th.getAttribute('data-k');
        state.nfSort = {k:k, dir: state.nfSort.k === k ? -state.nfSort.dir : 1};
        applyNfView();
        return;
      }
      var tr = e.target.closest('tbody tr');
      if(tr) selectNF(tr.getAttribute('data-nu'));
    });
    nfWrap.addEventListener('dblclick', function(e){
      var tr = e.target.closest('tbody tr');
      if(tr) abrirCentral(tr.getAttribute('data-nu'));
    });

    var t;
    $('nfSearch').addEventListener('input', function(e){
      clearTimeout(t);
      t = setTimeout(function(){ state.nfSearch = e.target.value.trim(); applyNfView(); }, 150);
    });

    //GRADE CTE
    var cteWrap = $('cteWrap');
    cteWrap.addEventListener('click', function(e){
      var b = e.target.closest('[data-rat]');
      if(b){ openRateio(b.getAttribute('data-rat')); return; }
      var o = e.target.closest('[data-open]');
      if(o) abrirCentral(o.getAttribute('data-open'));
    });
    cteWrap.addEventListener('dblclick', function(e){
      if(e.target.closest('button')) return;
      var tr = e.target.closest('tbody tr');
      if(tr) abrirCentral(tr.getAttribute('data-nu'));
    });

    $('cteClose').addEventListener('click', closeCTe);

    //POP UP
    $('ratClose').addEventListener('click', closeRateio);
    $('ovRat').addEventListener('mousedown', function(e){ if(e.target === this) closeRateio(); });
    document.addEventListener('keydown', function(e){
      if(e.key !== 'Escape') return;
      //ESC FECHA O QUE ESTIVER POR CIMA: POP UP > LISTA DE TOPs > PAINEL DO CTE
      if($('ovRat').classList.contains('open')) closeRateio();
      else if(ms.classList.contains('open')) ms.classList.remove('open');
      else if(state.nfSel) closeCTe();
    });
  }

  /* =========================================================================
     DADOS DE DEMONSTRACAO (SO QUANDO ABERTO FORA DO SANKHYA - SEM executeQuery)
     ========================================================================= */
  var Mock = (function(){
    var seed = 7;
    function rnd(){ seed = (seed * 9301 + 49297) % 233280; return seed / 233280; }
    function pick(a){ return a[Math.floor(rnd() * a.length)]; }
    var nats = [[1010101, 'INSUMOS AGRICOLAS'], [1010205, 'FERTILIZANTES'], [1020301, 'PECAS E MANUTENCAO']];
    var crs = [[10101, 'FAZENDA SANTA RITA'], [10102, 'FAZENDA BOA VISTA'], [20101, 'ADMINISTRATIVO']];
    var prjs = [[0, '<SEM PROJETO>'], [101, 'SAFRA 26/27'], [102, 'IRRIGACAO PIVO 3']];
    var parcs = [[1201, 'AGRO INSUMOS LTDA'], [1388, 'FERTILIZANTES DO CERRADO SA'], [1502, 'SEMENTES BRASIL LTDA'], [1610, 'NUTRI SOLO COMERCIO']];
    var transp = [[3001, 'TRANSPORTES RAPIDO SUL LTDA'], [3002, 'LOGISTICA CENTRO OESTE']];
    var tops = [{CODTIPOPER:100, DESCROPER:'COMPRA DE INSUMOS'}, {CODTIPOPER:101, DESCROPER:'COMPRA P/ USO E CONSUMO'}, {CODTIPOPER:105, DESCROPER:'COMPRA DE ATIVO IMOBILIZADO'}, {CODTIPOPER:110, DESCROPER:'COMPRA P/ INDUSTRIALIZACAO'}];
    function chave(){ var s = '5126'; while(s.length < 44) s += Math.floor(rnd() * 10); return s; }
    function dt(d){ var x = new Date(); x.setDate(x.getDate() - d); var p = function(n){ return (n < 10 ? '0' : '') + n; }; return p(x.getDate()) + '/' + p(x.getMonth() + 1) + '/' + x.getFullYear(); }
    function nota(nu, n, parc, top, vlr, frete, dias, nat, cr, prj, chaveDoc){
      return {NUNOTA:nu, NUMNOTA:n, SERIENOTA:'1', CODEMP:1, CHAVE:chaveDoc, DTNEG:dt(dias + 1), DTENTSAI:dt(dias),
        CODNAT:nat[0], DESCRNAT:nat[1], CODCENCUS:cr[0], DESCRCENCUS:cr[1], CODPROJ:prj[0], DESCRPROJ:prj[1],
        VLRNOTA:vlr, VLRFRETE:frete, CODTIPOPER:top.CODTIPOPER, DESCROPER:top.DESCROPER,
        CONFIRMADA: rnd() > .15 ? 'Sim' : 'Não', CODPARC:parc[0], NOMEPARC:parc[1]};
    }
    var NF = [], CTE = {}, RAT = {};
    for(var i = 0; i < 26; i++){
      var nat = pick(nats), cr = pick(crs), prj = pick(prjs);
      var vlr = Math.round((8000 + rnd() * 120000) * 100) / 100, frete = Math.round(vlr * (0.02 + rnd() * 0.05) * 100) / 100;
      var nf = nota(84000 + i * 7, 15230 + i, pick(parcs), pick(tops), vlr, frete, Math.floor(rnd() * 28), nat, cr, prj, chave());
      var rateada = i % 2 === 0;
      var linhasNF = rateada
        ? [{n:nat, c:crs[0], p:prjs[1], perc:60}, {n:nat, c:crs[1], p:prjs[1], perc:40}]
        : [{n:nat, c:cr, p:prj, perc:100, sem:true}];
      RAT[nf.NUNOTA] = linhasNF.map(function(l){ return {ORIGEM:'NF', NUNOTA:nf.NUNOTA, NUMNOTA:nf.NUMNOTA, VLRNOTA:nf.VLRNOTA, SEMRATEIO:l.sem ? 'S' : 'N',
        CODNAT:l.n[0], DESCRNAT:l.n[1], CODCENCUS:l.c[0], DESCRCENCUS:l.c[1], CODPROJ:l.p[0], DESCRPROJ:l.p[1], PERCRATEIO:l.perc,
        VLRRATEIO:Math.round(nf.VLRNOTA * l.perc) / 100, CODPARC:nf.CODPARC}; });
      var temCte = i % 4 !== 3;
      nf.QTDCTE = temCte ? 1 : 0;
      NF.push(nf);
      if(temCte){
        var tr = pick(transp), vc = i % 5 === 0 ? Math.round(frete * 0.93 * 100) / 100 : frete;
        var c = nota(90000 + i * 5, 7700 + i, tr, {CODTIPOPER:120, DESCROPER:'CT-E ENTRADA (FRETE S/ COMPRA)'}, vc, 0, Math.floor(rnd() * 3), nat, nf.CODCENCUS ? cr : cr, prj, chave());
        var linhasCte = linhasNF.map(function(l){ return {n:l.n, c:l.c, p:l.p, perc:l.perc, sem:l.sem}; });
        if(i % 6 === 0 && rateada){ linhasCte[0].perc = 70; linhasCte[1].perc = 30; }
        if(i % 10 === 4){ linhasCte = [{n:nat, c:cr, p:prj, perc:100, sem:true}]; }
        c.QTDRAT = linhasCte[0].sem ? 0 : linhasCte.length; c.QTDNF = 1;
        nf.QTDCTESEMRAT = c.QTDRAT ? 0 : 1;
        CTE[nf.NUNOTA] = [c];
        RAT['C' + c.NUNOTA] = {nf:nf.NUNOTA, linhas:linhasCte.map(function(l){ return {ORIGEM:'CTE', NUNOTA:c.NUNOTA, NUMNOTA:c.NUMNOTA, VLRNOTA:c.VLRNOTA, SEMRATEIO:l.sem ? 'S' : 'N',
          CODNAT:l.n[0], DESCRNAT:l.n[1], CODCENCUS:l.c[0], DESCRCENCUS:l.c[1], CODPROJ:l.p[0], DESCRPROJ:l.p[1], PERCRATEIO:l.perc,
          VLRRATEIO:Math.round(c.VLRNOTA * l.perc) / 100, CODPARC:c.CODPARC}; })};
      }
    }
    NF.forEach(function(n){ n.VLRCTE = CTE[n.NUNOTA] ? CTE[n.NUNOTA][0].VLRNOTA : 0; });
    return {
      query: function(nome, ctx){
        if(nome === 'tops') return tops;
        if(nome === 'nfs') return NF.filter(function(n){
          return (!ctx.apenasCte || n.QTDCTE > 0) && (!ctx.apenasSemRat || n.QTDCTESEMRAT > 0) && (!ctx.tops || !ctx.tops.length || ctx.tops.indexOf(n.CODTIPOPER) >= 0);
        });
        if(nome === 'ctes') return CTE[ctx.nunota] || [];
        if(nome === 'rateio'){ var r = RAT['C' + ctx.nunotaCte]; return r ? RAT[r.nf].concat(r.linhas) : []; }
        return [];
      }
    };
  })();

  /* =========================================================================
     INICIO
     ========================================================================= */
  function init(){
    if(DEMO) $('demoTag').style.display = '';
    bind();
    defaultFilters();
    renderCTes();
    loadTops().catch(function(e){ toast(e.message, true); }).then(loadNFs);
  }
  if(document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init); else init();
})();
</script>
</body>
</html>
