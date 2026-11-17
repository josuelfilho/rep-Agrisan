<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="false"%>
<%@ taglib uri="http://java.sun.com/jstl/core_rt" prefix="c" %>
<%@ taglib prefix="snk" uri="/WEB-INF/tld/sankhyaUtil.tld" %>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>CT-e x Notas de Compra</title>
<snk:load/>
<!--
  DASHBOARD HTML5 - CT-e x NOTAS DE COMPRA (AGRISAN)
  - LISTA OS CT-e DE ENTRADA (TIPMOV 'C', TOP MODELO 57) DO PERIODO, UMA LINHA POR CT-e
  - 1 CLIQUE NO CT-e: CARREGA A(S) NF-e VINCULADA(S) VIA TGFNCT (MESMO VINCULO DO cabEPJ / replicaRateioNFxCTEJob)
  - 2 CLIQUES NO CT-e OU NA NF-e: ABRE NA CENTRAL DE COMPRAS (CentralNotas_COMPRA)
  - "VER RATEIO": POP UP COMPARANDO O RATEIO (TGFRAV ORIGEM 'E') DAS NFs x CT-e
  - TOTAIS "COM / SEM NF-e VINCULADO" FUNCIONAM COMO FILTRO DA LISTA DE CT-e
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
  .app{display:flex;flex-direction:column;gap:5px;min-height:100%;padding:4px 10px 8px}

  .btn{border:1px solid var(--line);background:var(--card);border-radius:8px;padding:7px 12px;cursor:pointer;display:inline-flex;align-items:center;gap:6px;font-weight:550;transition:background .15s,border-color .15s,box-shadow .15s}
  .btn:hover{background:var(--hover);border-color:#d4dae3}
  .btn:focus-visible{outline:2px solid var(--primary);outline-offset:1px}
  .btn.primary{background:var(--primary);border-color:var(--primary);color:#fff}
  .btn.primary:hover{background:var(--primary-600)}
  .btn.sm{padding:4px 9px;font-size:12px;border-radius:7px}
  .btn svg{width:15px;height:15px;flex:none}
  .btn.sm svg{width:13px;height:13px}

  /* FILTROS */
  .filters{background:var(--card);border:1px solid var(--line);border-radius:var(--radius);box-shadow:var(--shadow);padding:10px 14px;display:flex;flex-wrap:wrap;gap:10px 16px;align-items:flex-end}
  .f{display:flex;flex-direction:column;gap:4px}
  .f label,.f .lbl{font-size:11px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.04em}
  .range{display:flex;align-items:center;gap:6px}
  .range span{color:var(--muted-2)}
  .inp{height:32px;border:1px solid var(--line);border-radius:8px;padding:0 9px;background:#fff;min-width:0}
  .inp:focus{outline:none;border-color:var(--primary);box-shadow:0 0 0 3px var(--primary-50)}
  input[type=date].inp{width:130px}
  .chk{display:flex;align-items:center;gap:8px;height:32px;cursor:pointer;user-select:none;font-weight:550;font-size:12px}
  .chk input{position:absolute;opacity:0;pointer-events:none}
  .chk .sw{width:30px;height:18px;border-radius:999px;background:#cfd6df;position:relative;transition:background .15s;flex:none}
  .chk .sw:after{content:"";position:absolute;top:2px;left:2px;width:14px;height:14px;border-radius:50%;background:#fff;box-shadow:0 1px 2px rgba(0,0,0,.2);transition:transform .15s}
  .chk input:checked + .sw{background:var(--primary)}
  .chk input:checked + .sw:after{transform:translateX(12px)}
  .chk input:focus-visible + .sw{outline:2px solid var(--primary);outline-offset:2px}
  .filters .grow{flex:1}

  /* ICONE DO PAINEL + TOOLTIP */
  .brand{position:relative;z-index:45;align-self:center;outline:none;cursor:help}
  .brand .logo{width:38px;height:38px;border-radius:10px;background:var(--primary);color:#fff;display:grid;place-items:center;box-shadow:0 2px 6px rgba(15,123,108,.3);transition:transform .15s}
  .brand:hover .logo,.brand:focus .logo{transform:translateY(-1px)}
  .brand .demo-dot{position:absolute;top:-3px;right:-3px;width:11px;height:11px;border-radius:50%;background:#f59e0b;border:2px solid #fff}
  .brand .tip{position:absolute;z-index:40;top:calc(100% + 10px);left:0;width:320px;background:#1f2937;color:#e5e7eb;border-radius:10px;padding:11px 13px;font-size:12px;line-height:1.5;box-shadow:0 12px 30px rgba(0,0,0,.25);opacity:0;visibility:hidden;transform:translateY(-4px);transition:opacity .15s,transform .15s,visibility .15s;pointer-events:none}
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

  /* TOTAIS (COMPACTOS). OS DE NF-e FUNCIONAM COMO FILTRO */
  .kpis{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:5px}
  .hint-tot{display:flex;justify-content:space-between;align-items:center;gap:6px 16px;flex-wrap:wrap}
  .hint-tot .tot{display:flex;gap:20px;font-size:12.5px;font-weight:600}
  .hint-tot .tot span{white-space:nowrap}
  .hint-tot .tot b{color:var(--text);font-weight:700;margin-left:4px}
  .kpi{background:var(--card);border:1px solid var(--line);border-radius:10px;box-shadow:var(--shadow);padding:6px 12px;display:flex;flex-direction:column;min-width:0;position:relative}
  .kpi .k{font-size:10.5px;font-weight:650;color:var(--muted);text-transform:uppercase;letter-spacing:.04em;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
  .kpi .row{display:flex;align-items:baseline;gap:8px;min-width:0}
  .kpi .v{font-size:16px;font-weight:700;font-variant-numeric:tabular-nums;letter-spacing:-.01em;white-space:nowrap}
  .kpi .h{font-size:11px;color:var(--muted);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
  .kpi.ok .v{color:var(--ok)} .kpi.warn .v{color:var(--warn)} .kpi.err .v{color:var(--err)}
  .kpi.click{cursor:pointer;transition:border-color .15s,box-shadow .15s,background .15s}
  .kpi.click:hover{border-color:#c9d2dc}
  .kpi.click:focus-visible{outline:2px solid var(--primary);outline-offset:1px}
  .kpi.click .k:after{content:" \25BE";opacity:.0}
  .kpi.click:hover .k:after{opacity:.6}
  .kpi.on{border-color:var(--primary);background:var(--primary-50);box-shadow:0 0 0 1px var(--primary) inset}
  .kpi.on .k{color:var(--primary)}
  .kpi.on:before{content:"Filtro ativo";position:absolute;top:6px;right:10px;font-size:10px;font-weight:700;color:var(--primary);text-transform:uppercase;letter-spacing:.04em}

  /* PAINEIS */
  .split{display:flex;flex-direction:column;gap:5px;flex:1;min-height:440px}
  #cardCTe{flex:1 1 0;min-height:300px}
  #cardNF{flex:0 0 280px;display:none}
  .split.has-nf #cardNF{display:flex;animation:up .18s ease-out}
  .sub-grid{display:grid;grid-template-columns:330px minmax(0,1fr);height:100%;min-height:0}
  .sub-l{border-right:1px solid var(--line);overflow:auto;padding-bottom:10px}
  .sub-r{overflow:auto;min-width:0}
  .sub-r .empty{padding:24px}
  .acts{display:flex;gap:6px;margin-top:10px}
  .card{background:var(--card);border:1px solid var(--line);border-radius:var(--radius);box-shadow:var(--shadow);display:flex;flex-direction:column;min-height:0;min-width:0;position:relative;overflow:hidden}
  .card-h{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:9px 14px;border-bottom:1px solid var(--line)}
  .card-h h2{margin:0;font-size:14px;font-weight:650;display:flex;align-items:center;gap:8px;flex-wrap:wrap}
  .pill{background:var(--line-soft);color:var(--muted);border-radius:999px;padding:1px 8px;font-size:11.5px;font-weight:650}
  .chip{display:inline-flex;align-items:center;gap:4px;background:var(--primary-50);color:var(--primary);border-radius:999px;padding:1px 4px 1px 9px;font-size:11.5px;font-weight:650}
  .chip button{border:0;background:transparent;color:inherit;cursor:pointer;width:18px;height:18px;border-radius:50%;display:grid;place-items:center;padding:0}
  .chip button:hover{background:rgba(15,123,108,.15)}
  .card-h .tools{display:flex;gap:8px;align-items:center}
  .search{position:relative}
  .search svg{position:absolute;left:8px;top:8px;width:15px;height:15px;color:var(--muted-2)}
  .search .inp{padding-left:28px;width:210px}
  .card-b{flex:1;min-height:0;overflow:auto}
  .hint{font-size:11.5px;color:var(--muted);padding:5px 14px;border-top:1px solid var(--line);background:#fbfcfd}

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
  .grid td.mono{max-width:170px}
  .grid .cd{color:var(--muted);margin-right:4px}
  .grid tfoot td{position:sticky;bottom:0;background:#f8fafc;font-weight:700;border-top:1px solid var(--line);border-bottom:0}
  #nfWrap .grid th{cursor:default}
  #nfWrap .grid th .ar{display:none}
  .badge{display:inline-flex;align-items:center;gap:4px;border-radius:999px;padding:1px 8px;font-size:11.5px;font-weight:650}
  .badge.ok{background:var(--ok-50);color:var(--ok)}
  .badge.no{background:var(--line-soft);color:var(--muted)}
  .badge.warn{background:var(--warn-50);color:var(--warn)}
  .badge.err{background:var(--err-50);color:var(--err)}
  .badge.blue{background:var(--blue-50);color:var(--blue)}

  /* RESUMO DO CT-e (PAINEL INFERIOR) */
  .box{margin:12px 14px 4px;border:1px solid var(--line);border-radius:10px;padding:10px 12px;background:linear-gradient(180deg,#fbfdfc,#f6faf9)}
  .box .t{font-weight:650}
  .box .p{color:var(--muted);font-size:12px;margin-top:2px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
  .cmp{display:grid;grid-template-columns:repeat(3,1fr);gap:8px;margin-top:9px}
  .cmp div{background:#fff;border:1px solid var(--line-soft);border-radius:8px;padding:6px 9px;min-width:0}
  .cmp span{display:block;font-size:10.5px;color:var(--muted);text-transform:uppercase;font-weight:600;letter-spacing:.03em;white-space:nowrap}
  .cmp b{font-size:13.5px;font-variant-numeric:tabular-nums}
  .btn-rat{border:1px solid var(--primary);color:var(--primary);background:#fff;border-radius:7px;padding:4px 10px;font-size:12px;font-weight:650;cursor:pointer;display:inline-flex;align-items:center;gap:5px}
  .btn-rat:hover{background:var(--primary);color:#fff}
  .btn-rat svg{width:13px;height:13px}
  .ico{border:1px solid var(--line);background:#fff;border-radius:6px;width:24px;height:22px;display:inline-grid;place-items:center;cursor:pointer;color:var(--muted);vertical-align:middle;margin-left:6px;padding:0}
  .ico:hover{color:var(--primary);border-color:var(--primary)}
  .ico svg{width:12px;height:12px}

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
  .pane-h{padding:9px 12px;font-weight:650;display:flex;justify-content:space-between;align-items:center;gap:8px;background:#f8fafc;border-bottom:1px solid var(--line)}
  .pane-b{overflow:auto;max-height:44vh}
  .pane .grid th{cursor:default;padding:7px 8px}
  .pane .grid th .ar{display:none}
  .pane .grid td{white-space:normal;max-width:220px;padding:6px 8px;vertical-align:top}
  .pane .grid td.num{white-space:nowrap}
  .pane .grid tbody tr{cursor:default}
  .grid tr.dif td{background:var(--err-50)!important}
  .diff-pos{color:var(--err);font-weight:650}
  .muted{color:var(--muted)}

  /* TOAST */
  .toast{position:fixed;right:16px;bottom:16px;z-index:60;background:#1f2937;color:#fff;padding:10px 14px;border-radius:10px;box-shadow:0 10px 30px rgba(0,0,0,.25);max-width:520px;display:none;font-size:12.5px}
  .toast.err{background:var(--err)}
  .toast.show{display:block;animation:up .2s ease-out}

  /* =========================================================================
     DENSIDADE COMPACTA: FONTES E ESPACAMENTOS MENORES PARA CABER MAIS LINHAS DE CT-e
     (SOBRESCREVE OS TAMANHOS DEFINIDOS ACIMA; PARA VOLTAR AO TAMANHO ANTERIOR, REMOVER ESTE BLOCO)
     ========================================================================= */
  body{font-size:11.5px;line-height:1.3}
  .btn{padding:4px 10px;border-radius:7px}
  .btn svg{width:13px;height:13px}
  .btn.sm{padding:2px 7px;font-size:11px}
  .filters{padding:6px 10px;gap:6px 12px}
  .f{gap:2px}
  .f label,.f .lbl{font-size:10px}
  .inp{height:27px;padding:0 7px;border-radius:7px}
  input[type=date].inp{width:118px}
  .ms{width:200px}
  .ms-btn{height:27px;padding:0 7px}
  .brand .logo{width:32px;height:32px;border-radius:8px}
  .kpi{padding:4px 10px}
  .kpi .k{font-size:9.5px}
  .kpi .v{font-size:14px}
  .kpi .h{font-size:10.5px}
  .kpi.on:before{top:4px;font-size:9px}
  .card-h{padding:5px 12px}
  .card-h h2{font-size:12.5px}
  .pill,.chip{font-size:10.5px}
  .search svg{top:6px;width:13px;height:13px}
  .search .inp{width:190px;padding-left:25px}
  .hint{padding:3px 12px;font-size:10.5px}
  .hint-tot .tot{font-size:11.5px}
  .grid th{padding:5px 8px;font-size:10px}
  .grid td{padding:3px 8px;font-size:11.5px}
  .grid .mono{font-size:10.5px}
  .badge{padding:0 6px;font-size:10.5px}
  .box{margin:8px 10px 4px;padding:8px 10px}
  .cmp b{font-size:12.5px}
  .btn-rat{padding:3px 8px;font-size:11px}

  @media (max-width:1100px){
    .kpis{grid-template-columns:repeat(3,minmax(0,1fr))}
    .two{grid-template-columns:minmax(0,1fr)}
    .sub-grid{grid-template-columns:minmax(0,1fr)}
    .sub-l{border-right:0;border-bottom:1px solid var(--line)}
    #cardNF{flex-basis:auto;max-height:540px}
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
        <b>CT-e x Notas de Compra</b>
        Acompanha os CT-e de entrada (frete): mostra a NF-e de compra vinculada a cada CT-e (TGFNCT) e compara o rateio da NF-e com o rateio do CT-e.
        <ul>
          <li>1 clique no CT-e: NF-e vinculada abaixo</li>
          <li>2 cliques no CT-e ou na NF-e: abre na Central</li>
          <li>Ver Rateio: comparativo NF-e x CT-e</li>
          <li>Totais (sem rateio / com / sem NF-e): clique para filtrar a lista</li>
        </ul>
        <span class="upd" id="lastUpd"></span>
      </div>
    </div>
    <div class="f">
      <label for="dtEntIni">Período Entrada</label>
      <div class="range"><input type="date" class="inp" id="dtEntIni"><span>até</span><input type="date" class="inp" id="dtEntFin"></div>
    </div>
    <div class="f">
      <span class="lbl" title="TOP do próprio CT-e (modelo 57)">TOPs Compra (CT-e)</span>
      <div class="ms" id="msTopCte">
        <button type="button" class="ms-btn"><span class="txt">Todas as TOPs</span><span class="cnt" style="display:none"></span><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m6 9 6 6 6-6"/></svg></button>
        <div class="ms-pop">
          <input type="text" class="inp ms-search" placeholder="Buscar TOP...">
          <div class="ms-tools"><a class="ms-all">Marcar todas</a><a class="ms-none">Limpar</a></div>
          <div class="ms-list"></div>
        </div>
      </div>
    </div>
    <div class="f">
      <span class="lbl" title="CT-e vinculados a NF-e destas TOPs (modelo 55)">TOPs Compra (NF-e)</span>
      <div class="ms" id="msTopNf">
        <button type="button" class="ms-btn"><span class="txt">Todas as TOPs</span><span class="cnt" style="display:none"></span><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m6 9 6 6 6-6"/></svg></button>
        <div class="ms-pop">
          <input type="text" class="inp ms-search" placeholder="Buscar TOP...">
          <div class="ms-tools"><a class="ms-all">Marcar todas</a><a class="ms-none">Limpar</a></div>
          <div class="ms-list"></div>
        </div>
      </div>
    </div>
    <div class="grow"></div>
    <div class="f">
      <div style="display:flex;gap:8px">
        <button class="btn" id="btnLimpar">Limpar</button>
        <button class="btn" id="btnCsv" title="Exportar a lista de CT-e (CSV)"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3v12"/><path d="m7 10 5 5 5-5"/><path d="M5 21h14"/></svg></button>
        <button class="btn primary" id="btnAplicar"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 5h18l-7 8v6l-4-2v-4z"/></svg>Aplicar</button>
      </div>
    </div>
  </div>

  <!-- TOTAIS -->
  <div class="kpis">
    <div class="kpi err click" id="kpiRat" data-filtro="semrat" tabindex="0" role="button" title="Filtrar os CT-e sem rateio"><div class="k">CT-e sem rateio</div><div class="row"><span class="v" id="kRat">-</span><span class="h" id="kRatH"></span></div></div>
    <div class="kpi ok click" id="kpiCom" data-filtro="com" tabindex="0" role="button" title="Filtrar os CT-e com NF-e vinculada"><div class="k">Com NF-e vinculado</div><div class="row"><span class="v" id="kCom">-</span><span class="h" id="kComH"></span></div></div>
    <div class="kpi warn click" id="kpiSem" data-filtro="sem" tabindex="0" role="button" title="Filtrar os CT-e sem NF-e vinculada"><div class="k">Sem NF-e vinculado</div><div class="row"><span class="v" id="kSem">-</span><span class="h" id="kSemH"></span></div></div>
  </div>

  <!-- PAINEIS: CT-e (TOPO) / NF-e VINCULADA (INFERIOR, APARECE AO CLICAR NO CT-e) -->
  <div class="split" id="split">
    <div class="card" id="cardCTe">
      <div class="card-h">
        <h2>Conhecimentos de Transporte (CT-e) <span class="pill" id="cteCount">0</span> <span id="cteChip"></span></h2>
        <div class="tools">
          <div class="search"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg><input type="text" class="inp" id="cteSearch" placeholder="Filtrar na lista..."></div>
        </div>
      </div>
      <div class="card-b" id="cteWrap"></div>
      <div class="hint hint-tot"><span>1 clique: mostra a NF-e vinculada abaixo &middot; 2 cliques: abre o CT-e na Central</span><span class="tot" id="cteTot"></span></div>
      <div class="loading"><div class="spin"></div></div>
    </div>

    <div class="card" id="cardNF">
      <div class="card-h">
        <h2>NF-e vinculada <span class="pill" id="nfCount">0</span> <span class="muted" id="nfCteRef" style="font-weight:500;font-size:12.5px"></span></h2>
        <button class="x" id="nfClose" title="Fechar e voltar à lista completa (Esc)"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 6 6 18M6 6l12 12"/></svg></button>
      </div>
      <div class="card-b" id="nfWrap"></div>
      <div class="hint">Ver Rateio: compara o rateio da NF-e x CT-e &middot; Abrir NF-e (ou 2 cliques na linha): abre a NF-e na Central</div>
      <div class="loading"><div class="spin"></div></div>
    </div>
  </div>
</div>

<!-- POP UP RATEIO -->
<div class="ov" id="ovRat" role="dialog" aria-modal="true" aria-labelledby="ratTitle">
  <div class="modal">
    <div class="modal-h">
      <div>
        <h3 id="ratTitle">Rateio NF-e x CT-e</h3>
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
    //RESOURCE ID DA CENTRAL DE COMPRAS (CONFIRMADO NO AMBIENTE AGRISAN), USADO PARA ABRIR NF-e E CT-e
    TELA_CENTRAL: 'br.com.sankhya.com.mov.CentralNotas_COMPRA',
    MAX_LINHAS: 3000,
    TOL_PERC: 0.01,  //TOLERANCIA (PONTOS PERCENTUAIS) PARA CONSIDERAR O RATEIO DIVERGENTE
    //COMO EXECUTAR AS CONSULTAS: 'auto' (executeQuery DO COMPONENTE E, SE O RETORNO NAO FOR ENTENDIDO, DbExplorerSP),
    //'executeQuery' (SO O COMPONENTE) OU 'dbexplorer' (SO O SERVICO DbExplorerSP.executeQuery)
    FONTE: 'auto'
  };

  var ICO_ABRIR = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 4h6v6"/><path d="M20 4 10 14"/><path d="M18 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h5"/></svg>';

  /* =========================================================================
     CONSULTAS (ORACLE). VALORES DOS FILTROS SAO VALIDADOS ANTES DE ENTRAR NO SQL
     VINCULO NF x CTE: TGFNCT (NCT.NUNOTA = CTE / NCT.CHAVENFE + NCT.NUMERO = NF)
     ========================================================================= */
  var SQL = {
    //TOPs DE COMPRA MODELO 57 (CT-e), NA VERSAO MAIS RECENTE
    topsCte: function(){
      return "SELECT TPO.CODTIPOPER, TPO.DESCROPER\n"
        + "FROM TGFTOP TPO\n"
        + "WHERE TPO.DHALTER = (SELECT MAX(DHALTER) FROM TGFTOP WHERE CODTIPOPER = TPO.CODTIPOPER)\n"
        + "    AND TPO.CODMODDOC = 57\n"
        + "    AND TPO.TIPMOV = 'C'\n"
        + "ORDER BY 2";
    },

    topsNf: function(){
      //TOPs DE COMPRA MODELO 55 (NF-e), NA VERSAO MAIS RECENTE
      return "SELECT T.CODTIPOPER, T.DESCROPER, T.CODMODDOC\n"
        + "FROM TGFTOP T\n"
        + "WHERE T.DHALTER = (SELECT MAX(DHALTER) FROM TGFTOP WHERE CODTIPOPER = T.CODTIPOPER)\n"
        + "AND T.TIPMOV = 'C'\n"
        + "AND T.CODMODDOC = 55\n"
        + "ORDER BY 2";
    },

    //DESCRICOES DOS CAMPOS DE FRETE DA TGFCAB
    //DESCRICOES OFICIAIS DAS OPCOES DOS CAMPOS (DICIONARIO DO SANKHYA - F_DESCROPC)
    tipFrete: function(a){
      return "NVL(F_DESCROPC('TGFCAB', 'TIPFRETE', " + a + ".TIPFRETE), " + a + ".TIPFRETE)";
    },
    //EX.: 'C' = "CIF - Contratação do Frete por conta do Remetente". NULO OU 'S' (SEM FRETE) = "Não informado"
    cifFob: function(a){
      return "CASE WHEN " + a + ".CIF_FOB IS NULL OR " + a + ".CIF_FOB = 'S' THEN 'Não informado'"
        + " ELSE NVL(F_DESCROPC('TGFCAB', 'CIF_FOB', " + a + ".CIF_FOB), " + a + ".CIF_FOB) END";
    },

    /* LISTA PRINCIPAL: CT-e DO PERIODO, UMA LINHA POR CT-e. SEM SUBCONSULTAS CORRELACIONADAS:
       - CT:   CT-e DO PERIODO (FILTROS RODAM UMA VEZ)
       - VINC: NF-e VINCULADAS A CADA CT-e (TGFNCT) EM UM UNICO JOIN
       - QNF:  QUANTIDADE DE NF-e POR CT-e
       - RAT:  QUANTIDADE DE LINHAS DE RATEIO (TGFRAV) POR CT-e */
    ctes: function(f){
      var w = [];
      if(f.entIni) w.push("AND N.DTENTSAI >= " + toDateSql(f.entIni));
      if(f.entFin) w.push("AND N.DTENTSAI < " + toDateSql(f.entFin) + " + 1");
      if(f.topsCte.length) w.push("AND N.CODTIPOPER IN (" + f.topsCte.join(",") + ")");

      var fim = [];
      if(f.topsNf.length) fim.push("N.NUNOTA IN (SELECT V.NUNOTACTE FROM VINC V WHERE V.TOPNF IN (" + f.topsNf.join(",") + "))");

      return "SELECT * FROM (\n"
        + "WITH CT AS (\n"
        + "  SELECT /*+ MATERIALIZE */\n"
        + "         N.NUNOTA, N.NUMNOTA, N.SERIENOTA, N.CODEMP, NVL(N.CHAVECTE, N.CHAVENFE) AS CHAVE, N.DTNEG, N.DTENTSAI,\n"
        + "         N.CODNAT, N.CODCENCUS, N.CODPROJ, N.VLRNOTA, N.CODTIPOPER, N.STATUSNOTA, N.CODPARC,\n"
        + "         N.TIPFRETE, N.CIF_FOB, TPO.DESCROPER\n"
        + "    FROM TGFCAB N\n"
        + "   INNER JOIN TGFTOP TPO ON TPO.CODTIPOPER = N.CODTIPOPER AND TPO.DHALTER = N.DHTIPOPER\n"
        + "   WHERE N.TIPMOV = 'C'\n"
        + "     AND TPO.CODMODDOC = 57\n"
        + "     " + w.join("\n     ") + "\n"
        + "),\n"
        + "VINC AS (\n"
        + "  SELECT DISTINCT C.NUNOTA AS NUNOTACTE, NF.NUNOTA AS NUNOTANF, NF.CODTIPOPER AS TOPNF\n"
        + "    FROM CT C\n"
        + "   INNER JOIN TGFNCT NCT ON NCT.NUNOTA = C.NUNOTA\n"
        + "   INNER JOIN TGFCAB NF ON NF.CHAVENFE = NCT.CHAVENFE AND NF.NUMNOTA = TO_NUMBER(NCT.NUMERO) AND NF.TIPMOV = 'C'\n"
        + "),\n"
        + "QNF AS (\n"
        + "  SELECT NUNOTACTE, COUNT(*) AS QTDNF FROM VINC GROUP BY NUNOTACTE\n"
        + "),\n"
        + "RAT AS (\n"
        + "  SELECT RAV.NUFIN AS NUNOTACTE, COUNT(*) AS QTDRAT\n"
        + "    FROM CT C\n"
        + "   INNER JOIN TGFRAV RAV ON RAV.ORIGEM = 'E' AND RAV.NUFIN = C.NUNOTA\n"
        + "   GROUP BY RAV.NUFIN\n"
        + ")\n"
        + "SELECT N.NUNOTA, N.NUMNOTA, N.SERIENOTA, N.CODEMP, EMP.NOMEFANTASIA, N.CHAVE,\n"
        + "       TO_CHAR(N.DTNEG, 'DD/MM/YYYY') AS DTNEG, TO_CHAR(N.DTENTSAI, 'DD/MM/YYYY') AS DTENTSAI,\n"
        + "       N.CODNAT, NAT.DESCRNAT, N.CODCENCUS, CUS.DESCRCENCUS, N.CODPROJ, PRJ.IDENTIFICACAO AS DESCRPROJ,\n"
        + "       N.VLRNOTA, NVL(Q.QTDNF, 0) AS QTDNF, NVL(R.QTDRAT, 0) AS QTDRAT,\n"
        + "       N.CODTIPOPER, N.DESCROPER,\n"
        + "       CASE WHEN N.STATUSNOTA = 'L' THEN 'Sim' ELSE 'Não' END AS CONFIRMADA,\n"
        + "       N.CODPARC, PAR.NOMEPARC,\n"
        + "       " + SQL.tipFrete('N') + " AS TIPFRETE,\n"
        + "       " + SQL.cifFob('N') + " AS CIFFOB\n"
        + "  FROM CT N\n"
        + "  LEFT JOIN QNF Q ON Q.NUNOTACTE = N.NUNOTA\n"
        + "  LEFT JOIN RAT R ON R.NUNOTACTE = N.NUNOTA\n"
        + " INNER JOIN TGFPAR PAR ON PAR.CODPARC = N.CODPARC\n"
        + "  LEFT JOIN TSIEMP EMP ON EMP.CODEMP = N.CODEMP\n"
        + "  LEFT JOIN TGFNAT NAT ON NAT.CODNAT = N.CODNAT\n"
        + "  LEFT JOIN TSICUS CUS ON CUS.CODCENCUS = N.CODCENCUS\n"
        + "  LEFT JOIN TCSPRJ PRJ ON PRJ.CODPROJ = N.CODPROJ\n"
        + (fim.length ? " WHERE " + fim.join("\n   AND ") + "\n" : "")
        + ") X\n"
        + "WHERE ROWNUM <= " + (CFG.MAX_LINHAS + 1);
    },

    //NF-e VINCULADA(S) AO CT-e (MESMO JOIN DO cabEPJ). POUCAS LINHAS POR CT-e
    nfs: function(nuNotaCTe){
      return "SELECT N.NUNOTA, N.NUMNOTA, N.SERIENOTA, N.CODEMP, EMP.NOMEFANTASIA, N.CHAVENFE AS CHAVE,\n"
        + "       TO_CHAR(N.DTENTSAI, 'DD/MM/YYYY') AS DTENTSAI,\n"
        + "       N.CODNAT, NAT.DESCRNAT, N.CODCENCUS, CUS.DESCRCENCUS, N.CODPROJ, PRJ.IDENTIFICACAO AS DESCRPROJ,\n"
        + "       N.VLRNOTA, NVL(N.VLRFRETE, 0) AS VLRFRETE, N.CODTIPOPER, TPO.DESCROPER,\n"
        + "       CASE WHEN N.STATUSNOTA = 'L' THEN 'Sim' ELSE 'Não' END AS CONFIRMADA,\n"
        + "       N.CODPARC, PAR.NOMEPARC\n"
        + "  FROM TGFCAB N\n"
        + " INNER JOIN TGFTOP TPO ON TPO.CODTIPOPER = N.CODTIPOPER AND TPO.DHALTER = N.DHTIPOPER\n"
        + " INNER JOIN TGFPAR PAR ON PAR.CODPARC = N.CODPARC\n"
        + "  LEFT JOIN TSIEMP EMP ON EMP.CODEMP = N.CODEMP\n"
        + "  LEFT JOIN TGFNAT NAT ON NAT.CODNAT = N.CODNAT\n"
        + "  LEFT JOIN TSICUS CUS ON CUS.CODCENCUS = N.CODCENCUS\n"
        + "  LEFT JOIN TCSPRJ PRJ ON PRJ.CODPROJ = N.CODPROJ\n"
        + " WHERE N.NUNOTA IN (SELECT NF.NUNOTA\n"
        + "                      FROM TGFNCT NCT\n"
        + "                     INNER JOIN TGFCAB NF ON NF.CHAVENFE = NCT.CHAVENFE AND NF.NUMNOTA = TO_NUMBER(NCT.NUMERO) AND NF.TIPMOV = 'C'\n"
        + "                     WHERE NCT.NUNOTA = " + int(nuNotaCTe) + ")\n"
        + " ORDER BY N.NUMNOTA, N.NUNOTA";
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
  function vazio(v){ return v === null || v === undefined || v === ''; }
  function codDesc(cod, desc){
    if(vazio(cod)) return '';
    return '<span class="cd">' + esc(cod) + '</span>' + esc(desc || '');
  }
  function codDescTxt(cod, desc){ return vazio(cod) ? '' : cod + ' - ' + (desc || ''); }

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
    var nada = []; nada.reconhecido = false;
    if(raw === null || raw === undefined || raw === '') return nada;
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

  //ABRE A NOTA (CT-e OU NF-e) NA CENTRAL DE COMPRAS - MESMO FORMATO DO LINK GERADO PELO SANKHYA:
  //"/mge/system.jsp#app/" + Base64(TELA) + "/" + Base64({"NUNOTA":n, "TIPMOV":"C", "ehPedidoW":false, "CODTIPOPER":t, "TIPOPORTAL":"PC", "forceNewHash":ts}) + "&pk-refresh=" + ts
  function abrirCentral(nuNota){
    var nu = int(nuNota);
    var reg = state.ctes.concat(state.nfs).filter(function(r){ return num(r.NUNOTA) === nu; })[0] || {};
    var ts = Date.now();
    var filtro = '{"NUNOTA":' + nu + ', "TIPMOV":"C", "ehPedidoW":false'
      + (vazio(reg.CODTIPOPER) ? '' : ', "CODTIPOPER":' + int(reg.CODTIPOPER))
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
    ctes: [], cteView: [], cteSort: {k:'DTENTSAI', dir:-1}, cteSearch: '',
    filtroNF: null,  //null | 'com' | 'sem' (CLIQUE NOS TOTAIS "COM / SEM NF-e VINCULADO")
    filtroRat: false, //true = SO CT-e SEM RATEIO (CLIQUE NO TOTAL "CT-e SEM RATEIO"). COMBINA COM O filtroNF
    cteSel: null, nfs: [], cacheNF: {}
  };

  /* =========================================================================
     COLUNAS DAS GRADES
     ========================================================================= */
  function colCodDesc(k, t, cod, desc){
    return {k:k, t:t, html:function(r){ return codDesc(r[cod], r[desc]); }, txt:function(r){ return codDescTxt(r[cod], r[desc]); }};
  }
  var COL_CONF = {k:'CONFIRMADA', t:'Confirmada?', html:function(r){ return r.CONFIRMADA === 'Sim' ? '<span class="badge ok">Sim</span>' : '<span class="badge no">Não</span>'; }};

  var COLS_CTE = [
    {k:'NUNOTA', t:'Nro. Único', num:true},
    {k:'NUMNOTA', t:'Nro. Nota', num:true},
    {k:'SERIENOTA', t:'Série'},
    colCodDesc('CODEMP', 'Empresa', 'CODEMP', 'NOMEFANTASIA'),
    {k:'CHAVE', t:'Chave CT-e', cls:'mono'},
    {k:'DTENTSAI', t:'Dt. Entrada', date:true},
    colCodDesc('CODNAT', 'Natureza', 'CODNAT', 'DESCRNAT'),
    colCodDesc('CODCENCUS', 'CR', 'CODCENCUS', 'DESCRCENCUS'),
    colCodDesc('CODPROJ', 'Projeto', 'CODPROJ', 'DESCRPROJ'),
    {k:'VLRNOTA', t:'Valor CT-e', num:true, money:true},
    {k:'QTDNF', t:'NF-e', num:true, html:function(r){
      var q = num(r.QTDNF);
      return q ? '<span class="badge ok">' + q + ' vínculo' + (q > 1 ? 's' : '') + '</span>' : '<span class="badge warn">Sem NF-e</span>';
    }, txt:function(r){ return num(r.QTDNF); }},
    {k:'QTDRAT', t:'Rateio', num:true, html:function(r){
      var q = num(r.QTDRAT);
      return q ? '<span class="badge blue">' + q + ' linha' + (q > 1 ? 's' : '') + '</span>' : '<span class="badge err">Sem rateio</span>';
    }, txt:function(r){ return num(r.QTDRAT) ? num(r.QTDRAT) + ' linhas' : 'Sem rateio'; }},
    colCodDesc('CODTIPOPER', 'Tipo Operação', 'CODTIPOPER', 'DESCROPER'),
    COL_CONF,
    colCodDesc('CODPARC', 'Parceiro', 'CODPARC', 'NOMEPARC'),
    {k:'TIPFRETE', t:'Tipo Frete'},
    {k:'CIFFOB', t:'CIF/FOB'}
  ];

  var COLS_NF = [
    {k:'_ABRIR', t:'', html:function(r){
      return '<button class="btn sm" data-open="' + esc(r.NUNOTA) + '" title="Abrir a NF-e na Central">' + ICO_ABRIR + 'Abrir NF-e</button>';
    }},
    {k:'NUNOTA', t:'Nro. Único', num:true},
    {k:'NUMNOTA', t:'Nro. Nota', num:true},
    {k:'SERIENOTA', t:'Série'},
    colCodDesc('CODEMP', 'Empresa', 'CODEMP', 'NOMEFANTASIA'),
    {k:'CHAVE', t:'Chave NF-e', cls:'mono'},
    {k:'DTENTSAI', t:'Dt. Entrada', date:true},
    colCodDesc('CODNAT', 'Natureza', 'CODNAT', 'DESCRNAT'),
    colCodDesc('CODCENCUS', 'CR', 'CODCENCUS', 'DESCRCENCUS'),
    colCodDesc('CODPROJ', 'Projeto', 'CODPROJ', 'DESCRPROJ'),
    {k:'VLRNOTA', t:'Valor Nota', num:true, money:true},
    {k:'VLRFRETE', t:'Valor Frete', num:true, money:true},
    colCodDesc('CODTIPOPER', 'Tipo Operação', 'CODTIPOPER', 'DESCROPER'),
    COL_CONF,
    colCodDesc('CODPARC', 'Parceiro', 'CODPARC', 'NOMEPARC')
  ];

  function cellHtml(col, r){
    if(col.html) return col.html(r);
    var v = r[col.k];
    if(col.money) return money(v);
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
      var arrow = c.k.charAt(0) === '_' ? '' : '<span class="ar">' + (sorted ? (opts.sort.dir > 0 ? '&#9650;' : '&#9660;') : '&#8693;') + '</span>';
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
      truck:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M3 7h11v9H3z"/><path d="M14 10h4l3 3v3h-7"/><circle cx="7" cy="18" r="2"/><circle cx="17" cy="18" r="2"/></svg>'
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
    MS_LISTAS.forEach(function(m){ m.limpar(); });
    state.filtroNF = null;
    state.filtroRat = false;
  }

  function readFilters(){
    var f = {
      entIni: $('dtEntIni').value, entFin: $('dtEntFin').value,
      topsCte: msTopCte.selecionados(),
      topsNf: msTopNf.selecionados()
    };
    if(!f.entIni && !f.entFin) throw new Error('Informe o período de entrada.');
    if(f.entIni && f.entFin && f.entIni > f.entFin) throw new Error('Período de entrada: data inicial maior que a final.');
    return f;
  }

  /* MULTILIST DE TOPs (COMPONENTE REUTILIZADO PELOS FILTROS "TOPs COMPRA (CT-e)" E "TOPs COMPRA (NF-e)")
     id = ELEMENTO .ms / nome = NOME DA CONSULTA (DIAGNOSTICO E DEMO) / sql = FUNCAO QUE MONTA O SELECT */
  function MultiList(id, nome, sql){
    var root = $(id), self = this;
    var q = function(s){ return root.querySelector(s); };
    self.root = root; self.itens = []; self.sel = {};

    self.selecionados = function(){
      return Object.keys(self.sel).filter(function(k){ return self.sel[k]; }).map(int);
    };
    self.limpar = function(){ self.sel = {}; self.render(); };
    self.fechar = function(){ root.classList.remove('open'); };
    self.aberto = function(){ return root.classList.contains('open'); };

    self.render = function(){
      var term = (q('.ms-search').value || '').toLowerCase();
      var html = '';
      self.itens.forEach(function(t){
        var label = t.CODTIPOPER + ' ' + (t.DESCROPER || '');
        if(term && label.toLowerCase().indexOf(term) < 0) return;
        var ck = self.sel[t.CODTIPOPER] ? ' checked' : '';
        html += '<label class="ms-item"><input type="checkbox" value="' + esc(t.CODTIPOPER) + '"' + ck + '><b>' + esc(t.CODTIPOPER) + '</b><span>' + esc(t.DESCROPER) + '</span></label>';
      });
      q('.ms-list').innerHTML = html || ('<div class="muted" style="padding:8px">Nenhuma TOP encontrada.</div>'
        + (DEMO || self.itens.length ? '' : '<div style="padding:0 8px 6px"><button type="button" class="btn sm ms-diag">Ver retorno da consulta</button></div>'));

      var sel = self.itens.filter(function(t){ return self.sel[t.CODTIPOPER]; });
      var btn = q('.ms-btn');
      btn.querySelector('.txt').textContent = !sel.length ? 'Todas as TOPs'
        : sel.length === 1 ? sel[0].CODTIPOPER + ' - ' + sel[0].DESCROPER
        : sel.map(function(t){ return t.CODTIPOPER; }).join(', ');
      var cnt = btn.querySelector('.cnt');
      cnt.style.display = sel.length > 1 ? '' : 'none';
      cnt.textContent = sel.length;
    };

    self.carregar = function(){
      return runQuery(nome, sql()).then(function(rows){
        self.itens = rows;
        self.render();
      });
    };

    //EVENTOS
    q('.ms-btn').addEventListener('click', function(){
      MS_LISTAS.forEach(function(m){ if(m !== self) m.fechar(); });
      root.classList.toggle('open');
      if(self.aberto()) setTimeout(function(){ q('.ms-search').focus(); }, 0);
    });
    document.addEventListener('mousedown', function(e){ if(!root.contains(e.target)) self.fechar(); });
    q('.ms-search').addEventListener('input', self.render);
    q('.ms-search').addEventListener('keydown', function(e){ if(e.key === 'Enter') e.stopPropagation(); });
    q('.ms-list').addEventListener('click', function(e){
      if(e.target.closest('.ms-diag')){ self.fechar(); showDiag(); }
    });
    q('.ms-list').addEventListener('change', function(e){
      if(e.target.type !== 'checkbox') return;
      self.sel[e.target.value] = e.target.checked;
      self.render();
    });
    q('.ms-all').addEventListener('click', function(){
      var term = (q('.ms-search').value || '').toLowerCase();
      self.itens.forEach(function(t){ if(!term || (t.CODTIPOPER + ' ' + t.DESCROPER).toLowerCase().indexOf(term) >= 0) self.sel[t.CODTIPOPER] = true; });
      self.render();
    });
    q('.ms-none').addEventListener('click', self.limpar);
  }

  var msTopCte, msTopNf, MS_LISTAS = [];
  function criaListas(){
    msTopCte = new MultiList('msTopCte', 'topsCte', SQL.topsCte);
    msTopNf = new MultiList('msTopNf', 'topsNf', SQL.topsNf);
    MS_LISTAS = [msTopCte, msTopNf];
  }
  function loadTops(){
    //AS DUAS LISTAS CARREGAM JUNTAS; ERRO EM UMA NAO IMPEDE A OUTRA
    return Promise.all(MS_LISTAS.map(function(m){
      return m.carregar().catch(function(e){ toast(e.message, true); });
    }));
  }

  /* =========================================================================
     CT-e (LISTA PRINCIPAL)
     ========================================================================= */
  function loadCTes(){
    var f;
    try{ f = readFilters(); }catch(e){ toast(e.message, true); return Promise.resolve(); }
    busy('cardCTe', true);
    return runQuery('ctes', SQL.ctes(f), f).then(function(rows){
      if(rows.length > CFG.MAX_LINHAS){
        rows = rows.slice(0, CFG.MAX_LINHAS);
        toast('Mais de ' + fmtInt.format(CFG.MAX_LINHAS) + ' CT-e no período. Refine os filtros.', true);
      }
      state.ctes = rows;
      state.cacheNF = {};
      //MANTEM O CT-e SELECIONADO SE ELE CONTINUAR NA LISTA
      var sel = state.cteSel && rows.filter(function(r){ return String(r.NUNOTA) === String(state.cteSel.NUNOTA); })[0];
      state.cteSel = sel || null;
      if(!sel) state.nfs = [];
      applyCteView();
      renderKpis();
      if(sel) loadNFs(sel); else renderNFs();
      $('lastUpd').textContent = (DEMO ? 'Modo demonstração · ' : '') + 'Atualizado às ' + new Date().toLocaleTimeString('pt-BR', {hour:'2-digit', minute:'2-digit'});
    }).catch(function(e){
      toast(e.message, true);
    }).then(function(){ busy('cardCTe', false); });
  }

  function applyCteView(){
    var term = state.cteSearch.toLowerCase();
    var fnf = state.filtroNF;
    var rows = state.ctes.filter(function(r){
      if(fnf === 'com' && !num(r.QTDNF)) return false;
      if(fnf === 'sem' && num(r.QTDNF)) return false;
      if(state.filtroRat && num(r.QTDRAT)) return false;
      return !term || COLS_CTE.some(function(c){ return cellTxt(c, r).toLowerCase().indexOf(term) >= 0; });
    });
    var s = state.cteSort, col = COLS_CTE.filter(function(c){ return c.k === s.k; })[0] || {};
    rows.sort(function(a, b){
      var x = a[s.k], y = b[s.k];
      if(col.date){ x = dateKey(x); y = dateKey(y); }
      else if(col.num){ x = num(x); y = num(y); }
      else { x = cellTxt(col, a).toLowerCase(); y = cellTxt(col, b).toLowerCase(); }
      return (x > y ? 1 : x < y ? -1 : 0) * s.dir || (num(b.NUNOTA) - num(a.NUNOTA));
    });
    state.cteView = rows;
    renderCTes();
    renderFiltroNF();
  }

  function renderCTes(){
    var rows = state.cteView;
    $('cteCount').textContent = fmtInt.format(rows.length) + (rows.length !== state.ctes.length ? ' de ' + fmtInt.format(state.ctes.length) : '');
    //RODAPE DO CARD: QTD. TOTAL E TOTAL R$ DOS CT-e DA LISTA (RESPEITA O FILTRO DE TEXTO E O FILTRO DOS TOTAIS)
    var tVlr = 0;
    rows.forEach(function(r){ tVlr += num(r.VLRNOTA); });
    $('cteTot').innerHTML = '<span>Qtd. Total CT-e: <b>' + fmtInt.format(rows.length) + '</b></span>'
      + '<span>Total R$ CT-e: <b>' + brl(tVlr) + '</b></span>';
    if(!state.ctes.length){
      $('cteWrap').innerHTML = emptyHtml('truck', 'Nenhum CT-e encontrado', 'Ajuste os filtros de período, TOP ou rateio e clique em Aplicar.')
        + (DEMO ? '' : '<div style="text-align:center;margin-top:-20px"><button class="btn sm" id="btnDiag">Ver retorno da consulta</button></div>');
      return;
    }
    if(!rows.length){
      $('cteWrap').innerHTML = emptyHtml('truck', 'Nada corresponde ao filtro', state.cteSearch ? 'Nenhum CT-e contém "' + state.cteSearch + '".' : 'Nenhum CT-e nesta situação.');
      return;
    }
    $('cteWrap').innerHTML = renderTable(COLS_CTE, rows, {sort:state.cteSort, selKey:state.cteSel && state.cteSel.NUNOTA});
  }

  function renderKpis(){
    var rows = state.ctes, vlr = 0, com = 0, vlrCom = 0, semRat = 0, vlrSemRat = 0;
    rows.forEach(function(r){
      var v = num(r.VLRNOTA);
      vlr += v;
      if(num(r.QTDNF) > 0){ com++; vlrCom += v; }
      if(!num(r.QTDRAT)){ semRat++; vlrSemRat += v; }
    });
    var sem = rows.length - com;
    var pc = function(a){ return rows.length ? Math.round(a * 100 / rows.length) + '%' : ''; };
    $('kRat').textContent = fmtInt.format(semRat);
    $('kRatH').textContent = rows.length ? pc(semRat) + ' · ' + brl(vlrSemRat) : '';
    $('kCom').textContent = fmtInt.format(com);
    $('kComH').textContent = rows.length ? pc(com) + ' · ' + brl(vlrCom) : '';
    $('kSem').textContent = fmtInt.format(sem);
    $('kSemH').textContent = rows.length ? pc(sem) + ' · ' + brl(vlr - vlrCom) : '';
  }

  /* FILTRO PELOS TOTAIS (NO CLIENTE, SEM NOVA CONSULTA):
     - "COM / SEM NF-e VINCULADO": UM OU OUTRO (CLICAR DE NOVO DESMARCA)
     - "CT-e SEM RATEIO": LIGA/DESLIGA E COMBINA COM O FILTRO DE NF-e */
  function setFiltro(v){
    if(v === 'semrat') state.filtroRat = !state.filtroRat;
    else state.filtroNF = state.filtroNF === v ? null : v;
    //SE O CT-e SELECIONADO SAIR DA LISTA, FECHA O PAINEL DA NF-e
    var c = state.cteSel;
    if(c && ((state.filtroNF === 'com' && !num(c.QTDNF)) || (state.filtroNF === 'sem' && num(c.QTDNF)) || (state.filtroRat && num(c.QTDRAT)))) closeNF();
    applyCteView();
  }
  var ICO_X = '<svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><path d="M18 6 6 18M6 6l12 12"/></svg>';
  function renderFiltroNF(){
    var on = {kpiCom: state.filtroNF === 'com', kpiSem: state.filtroNF === 'sem', kpiRat: state.filtroRat};
    Object.keys(on).forEach(function(id){
      $(id).classList.toggle('on', on[id]);
      $(id).setAttribute('aria-pressed', on[id]);
    });
    var chips = '';
    if(state.filtroRat) chips += '<span class="chip">CT-e sem rateio<button data-limpa="semrat" title="Remover filtro">' + ICO_X + '</button></span> ';
    if(state.filtroNF) chips += '<span class="chip">' + (state.filtroNF === 'com' ? 'Com NF-e vinculado' : 'Sem NF-e vinculado')
      + '<button data-limpa="nf" title="Remover filtro">' + ICO_X + '</button></span>';
    $('cteChip').innerHTML = chips;
  }

  /* =========================================================================
     NF-e VINCULADA (PAINEL INFERIOR)
     ========================================================================= */
  function selectCTe(nu){
    var r = state.ctes.filter(function(x){ return String(x.NUNOTA) === String(nu); })[0];
    if(!r || (state.cteSel && String(state.cteSel.NUNOTA) === String(nu))) return;
    state.cteSel = r;
    var trs = $('cteWrap').querySelectorAll('tbody tr'), alvo = null;
    for(var i = 0; i < trs.length; i++){
      var on = trs[i].getAttribute('data-nu') === String(nu);
      trs[i].classList.toggle('sel', on);
      if(on) alvo = trs[i];
    }
    $('split').classList.add('has-nf');
    //A LISTA DE CT-e DIMINUI QUANDO O PAINEL DA NF-e ABRE: MANTEM A LINHA SELECIONADA VISIVEL
    if(alvo) setTimeout(function(){
      var wrap = $('cteWrap');
      wrap.scrollTop = Math.max(0, alvo.offsetTop - (wrap.clientHeight - alvo.offsetHeight) / 2);
    }, 0);
    state.nfs = [];
    renderNFs();
    loadNFs(r);
  }

  //FECHA O PAINEL DA NF-e E VOLTA A LISTA COMPLETA DE CT-e
  function closeNF(){
    state.cteSel = null; state.nfs = [];
    $('split').classList.remove('has-nf');
    var sel = $('cteWrap').querySelector('tbody tr.sel');
    if(sel) sel.classList.remove('sel');
    renderNFs();
  }

  function loadNFs(cte){
    var key = String(cte.NUNOTA);
    if(state.cacheNF[key]){ state.nfs = state.cacheNF[key]; renderNFs(); return; }
    busy('cardNF', true);
    runQuery('nfs', SQL.nfs(cte.NUNOTA), {nunotaCte:cte.NUNOTA}).then(function(rows){
      state.cacheNF[key] = rows;
      if(state.cteSel && String(state.cteSel.NUNOTA) === key){ state.nfs = rows; renderNFs(); }
    }).catch(function(e){ toast(e.message, true); })
      .then(function(){ busy('cardNF', false); });
  }

  function renderNFs(){
    var cte = state.cteSel, w = $('nfWrap');
    $('split').classList.toggle('has-nf', !!cte);
    if(!cte){
      $('nfCount').textContent = '0';
      $('nfCteRef').textContent = '';
      w.innerHTML = '';
      return;
    }
    $('nfCteRef').textContent = '· CT-e ' + cte.NUMNOTA + ' (NU ' + cte.NUNOTA + ')';
    var rows = state.nfs, totFrete = 0;
    rows.forEach(function(r){ totFrete += num(r.VLRFRETE); });
    var dif = num(cte.VLRNOTA) - totFrete;
    var difCls = !rows.length ? 'muted' : Math.abs(dif) < 0.01 ? '' : 'diff-pos';
    $('nfCount').textContent = rows.length;

    var esq = '<div class="box"><div class="t">CT-e ' + esc(cte.NUMNOTA) + (cte.SERIENOTA ? '/' + esc(cte.SERIENOTA) : '') + ' <span class="muted" style="font-weight:500">· NU ' + esc(cte.NUNOTA) + '</span></div>'
      + '<div class="p" title="' + esc(cte.NOMEPARC) + '">' + esc(cte.CODPARC) + ' - ' + esc(cte.NOMEPARC) + '</div>'
      + '<div class="p">Entrada ' + esc(cte.DTENTSAI || '-') + (cte.CIFFOB ? ' · ' + esc(cte.CIFFOB) : '') + (cte.TIPFRETE ? ' · ' + esc(cte.TIPFRETE) : '') + '</div>'
      + '<div class="cmp"><div><span>Valor CT-e</span><b>' + money(cte.VLRNOTA) + '</b></div>'
      + '<div><span>Frete NF-e</span><b>' + (rows.length ? money(totFrete) : '-') + '</b></div>'
      + '<div><span>Diferença</span><b class="' + difCls + '">' + (rows.length ? money(dif) : '-') + '</b></div></div>'
      + '<div class="acts">'
      + '<button class="btn-rat" data-rat="' + esc(cte.NUNOTA) + '" title="Comparar o rateio NF-e x CT-e"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14"/><path d="m13 6 6 6-6 6"/></svg>Ver Rateio</button>'
      + '<button class="btn sm" data-open="' + esc(cte.NUNOTA) + '" title="Abrir o CT-e na Central">' + ICO_ABRIR + 'Abrir CT-e</button>'
      + '</div></div>';

    var dir = rows.length
      ? renderTable(COLS_NF, rows, {})
      : emptyHtml('doc', 'Nenhuma NF-e vinculada', 'Este CT-e não tem NF-e de compra na aba de notas do conhecimento (TGFNCT).');
    w.innerHTML = '<div class="sub-grid"><div class="sub-l">' + esq + '</div><div class="sub-r">' + dir + '</div></div>';
  }

  /* =========================================================================
     POP UP RATEIO NF-e x CT-e
     ========================================================================= */
  function chaveRateio(r){ return [num(r.CODNAT), num(r.CODCENCUS), num(r.CODPROJ)].join('|'); }

  function openRateio(nuCte){
    var cte = state.ctes.filter(function(c){ return String(c.NUNOTA) === String(nuCte); })[0] || {NUNOTA:nuCte};
    $('ratTitle').innerHTML = 'Rateio NF-e x CT-e <span class="muted" style="font-weight:500;font-size:13px">CT-e ' + esc(cte.NUMNOTA || '') + ' · NU ' + esc(cte.NUNOTA) + '</span>';
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
    nfRows.forEach(function(r){ if(!(r.NUNOTA in nfs)){ nfs[r.NUNOTA] = num(r.VLRNOTA); totNF += num(r.VLRNOTA); } });
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

    var status = !nfRows.length ? '<span class="badge warn">CT-e sem NF-e vinculada</span>'
      : qtdDiv ? '<span class="badge err">Divergente · ' + qtdDiv + ' linha' + (qtdDiv > 1 ? 's' : '') + '</span>'
      : '<span class="badge ok">Rateio conferido</span>';
    var t = $('ratTitle');
    if(!t.querySelector('.badge')) t.insertAdjacentHTML('beforeend', status);

    var cols = [
      {k:'ORIGEM', t:'Origem', html:function(r){
        var o = '<div style="white-space:nowrap;font-weight:600">' + (r.ORIGEM === 'NF' ? 'NF-e ' : 'CT-e ') + esc(r.NUMNOTA)
          + (r.ORIGEM === 'NF' ? '<button class="ico" data-open="' + esc(r.NUNOTA) + '" title="Abrir a NF-e na Central">' + ICO_ABRIR + '</button>' : '') + '</div>'
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

    function pane(titulo, extra, lista, marcaDiv){
      var tot = 0, totP = 0;
      lista.forEach(function(r){ tot += num(r.VLRRATEIO); totP += num(r.PERCRATEIO); });
      var html = '<div class="pane"><div class="pane-h"><span>' + titulo + '</span><span style="display:flex;gap:6px;align-items:center">' + extra
        + '<span class="pill">' + lista.length + ' linha' + (lista.length !== 1 ? 's' : '') + '</span></span></div><div class="pane-b">';
      if(!lista.length){
        html += emptyHtml('doc', 'Sem linhas', 'Nenhuma nota encontrada.');
      }else{
        var tb = renderTable(cols, lista, {});
        if(marcaDiv){
          //DESTACA AS LINHAS DO CTE QUE DIVERGEM DO ESPERADO
          var i = 0;
          tb = tb.replace(/<tr data-nu="[^"]*"/g, function(m){ var r = lista[i++]; return m + (divergentes[chaveRateio(r)] ? ' class="dif"' : ''); });
        }
        var foot = '<td>Total</td><td></td><td></td><td></td><td class="num">' + (qtdNF > 1 && !marcaDiv ? '' : perc(totP)) + '</td><td class="num">' + money(tot) + '</td><td></td>';
        html += tb.replace('</tbody>', '</tbody><tfoot><tr>' + foot + '</tr></tfoot>');
      }
      return html + '</div></div>';
    }

    //BOTAO PARA ABRIR A NF-e (SE HOUVER UMA SO; COM VARIAS, CADA LINHA TEM O SEU ICONE)
    var nfUnica = qtdNF === 1 ? Object.keys(nfs)[0] : null;
    var btnNF = nfUnica ? '<button class="btn sm" data-open="' + esc(nfUnica) + '" title="Abrir a NF-e na Central">' + ICO_ABRIR + 'Abrir NF-e</button>' : '';

    var h = '';
    if(nfSemRat && cteSemRat){
      h += '<div class="muted">NF-e e CT-e sem rateio: a comparação usa a natureza, o centro de resultado e o projeto do cabeçalho das notas.</div>';
    }
    h += '<div class="two">'
      + pane('NF-e de Compra' + (qtdNF > 1 ? ' <span class="muted" style="font-weight:500">(' + qtdNF + ' NF-e, ponderadas pelo valor)</span>' : ''), btnNF, nfRows, false)
      + pane('CT-e', '', cteRows, true)
      + '</div>';

    //COMPARATIVO POR NATUREZA / CR / PROJETO
    chaves.sort(function(a, b){ return (esperado[b] || atual[b] || 0) - (esperado[a] || atual[a] || 0); });
    var comp = '<div class="pane"><div class="pane-h"><span>Comparativo NF-e x CT-e (Natureza · Centro de Resultado · Projeto)</span>'
      + (qtdDiv ? '<span class="badge err">' + qtdDiv + ' divergência' + (qtdDiv > 1 ? 's' : '') + '</span>' : '<span class="badge ok">Sem divergências</span>')
      + '</div><div class="pane-b"><table class="grid"><thead><tr><th>Natureza</th><th>Centro de Resultado</th><th>Projeto</th>'
      + '<th class="num">% esperado (NF-e)</th><th class="num">% no CT-e</th><th class="num">Diferença</th><th class="num">Valor esperado</th><th class="num">Valor no CT-e</th><th>Situação</th></tr></thead><tbody>';
    var vlrCte = cteRows.length ? num(cteRows[0].VLRNOTA) : 0;
    chaves.forEach(function(k){
      var d = desc[k], e = esperado[k] || 0, a = atual[k] || 0, dv = divergentes[k];
      comp += '<tr class="' + (dv ? 'dif' : '') + '">'
        + '<td>' + codDesc(d.CODNAT, d.DESCRNAT) + '</td><td>' + codDesc(d.CODCENCUS, d.DESCRCENCUS) + '</td><td>' + codDesc(d.CODPROJ, d.DESCRPROJ) + '</td>'
        + '<td class="num">' + perc(e) + '</td><td class="num">' + perc(a) + '</td>'
        + '<td class="num' + (dv ? ' diff-pos' : '') + '">' + perc(a - e) + '</td>'
        + '<td class="num">' + money(vlrCte * e / 100) + '</td><td class="num">' + money(vlrCte * a / 100) + '</td>'
        + '<td>' + (dv ? (!a ? '<span class="badge err">Falta no CT-e</span>' : !e ? '<span class="badge err">Não existe na NF-e</span>' : '<span class="badge err">% diferente</span>') : '<span class="badge ok">OK</span>') + '</td></tr>';
    });
    comp += '</tbody></table></div></div>';
    h += comp;

    $('ratBody').innerHTML = h;
  }

  /* =========================================================================
     CSV (LISTA DE CT-e COMO ESTA NA TELA)
     ========================================================================= */
  function exportCsv(){
    var rows = state.cteView;
    if(!rows.length){ toast('Não há CT-e para exportar.'); return; }
    var cols = COLS_CTE;
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
    a.download = 'cte_x_notas_compra_' + isoDate(new Date()) + '.csv';
    document.body.appendChild(a); a.click(); a.remove();
    setTimeout(function(){ URL.revokeObjectURL(a.href); }, 1000);
  }

  /* =========================================================================
     EVENTOS
     ========================================================================= */
  function bind(){
    $('btnAplicar').addEventListener('click', loadCTes);
    $('btnLimpar').addEventListener('click', function(){ defaultFilters(); closeNF(); loadCTes(); });
    $('btnCsv').addEventListener('click', exportCsv);
    $('filters').addEventListener('keydown', function(e){ if(e.key === 'Enter' && !e.target.closest('.ms') && !e.target.closest('.brand')) loadCTes(); });

    //TOTAIS COMO FILTRO
    ['kpiRat', 'kpiCom', 'kpiSem'].forEach(function(id){
      var el = $(id);
      el.addEventListener('click', function(){ setFiltro(el.getAttribute('data-filtro')); });
      el.addEventListener('keydown', function(e){ if(e.key === 'Enter' || e.key === ' '){ e.preventDefault(); setFiltro(el.getAttribute('data-filtro')); } });
    });
    $('cteChip').addEventListener('click', function(e){
      var b = e.target.closest('[data-limpa]');
      if(!b) return;
      if(b.getAttribute('data-limpa') === 'semrat') state.filtroRat = false; else state.filtroNF = null;
      applyCteView();
    });

    //GRADE CT-e: 1 CLIQUE MOSTRA A NF-e / 2 CLIQUES ABRE O CT-e NA CENTRAL / CABECALHO ORDENA
    var cteWrap = $('cteWrap');
    cteWrap.addEventListener('click', function(e){
      if(e.target.closest('#btnDiag')){ showDiag(); return; }
      var th = e.target.closest('th');
      if(th){
        var k = th.getAttribute('data-k');
        state.cteSort = {k:k, dir: state.cteSort.k === k ? -state.cteSort.dir : 1};
        applyCteView();
        return;
      }
      var tr = e.target.closest('tbody tr');
      if(tr) selectCTe(tr.getAttribute('data-nu'));
    });
    cteWrap.addEventListener('dblclick', function(e){
      var tr = e.target.closest('tbody tr');
      if(tr) abrirCentral(tr.getAttribute('data-nu'));
    });

    var t;
    $('cteSearch').addEventListener('input', function(e){
      clearTimeout(t);
      t = setTimeout(function(){ state.cteSearch = e.target.value.trim(); applyCteView(); }, 150);
    });

    //PAINEL NF-e: VER RATEIO / ABRIR CT-e / ABRIR NF-e / 2 CLIQUES ABRE A NF-e
    var nfWrap = $('nfWrap');
    nfWrap.addEventListener('click', function(e){
      var b = e.target.closest('[data-rat]');
      if(b){ openRateio(b.getAttribute('data-rat')); return; }
      var o = e.target.closest('[data-open]');
      if(o) abrirCentral(o.getAttribute('data-open'));
    });
    nfWrap.addEventListener('dblclick', function(e){
      if(e.target.closest('button')) return;
      var tr = e.target.closest('tbody tr');
      if(tr) abrirCentral(tr.getAttribute('data-nu'));
    });
    $('nfClose').addEventListener('click', closeNF);

    //POP UP (BOTOES DE ABRIR NF-e DENTRO DO RATEIO)
    $('ratBody').addEventListener('click', function(e){
      var o = e.target.closest('[data-open]');
      if(o) abrirCentral(o.getAttribute('data-open'));
    });
    $('ratClose').addEventListener('click', closeRateio);
    $('ovRat').addEventListener('mousedown', function(e){ if(e.target === this) closeRateio(); });
    document.addEventListener('keydown', function(e){
      if(e.key !== 'Escape') return;
      //ESC FECHA O QUE ESTIVER POR CIMA: POP UP > LISTA DE TOPs > PAINEL DA NF-e
      if($('ovRat').classList.contains('open')) closeRateio();
      else if(MS_LISTAS.some(function(m){ return m.aberto(); })) MS_LISTAS.forEach(function(m){ m.fechar(); });
      else if(state.cteSel) closeNF();
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
    var tops = [{CODTIPOPER:9, DESCROPER:'NFE COMPRA INSUMOS'}, {CODTIPOPER:26, DESCROPER:'NFE COMPRA APLICACAO'}, {CODTIPOPER:30, DESCROPER:'NFE COMPRA USO E CONSUMO'}];
    var topsCte = [{CODTIPOPER:27, DESCROPER:'CTE ENTRADA FRETE S/ COMPRA'}, {CODTIPOPER:28, DESCROPER:'CTE ENTRADA FRETE TRANSFERENCIA'}];
    var emps = [[1, 'AGRISAN MATRIZ'], [3, 'AGRISAN FILIAL GO']];
    function chave(p){ var s = p; while(s.length < 44) s += Math.floor(rnd() * 10); return s; }
    function dt(d){ var x = new Date(); x.setDate(x.getDate() - d); var p = function(n){ return (n < 10 ? '0' : '') + n; }; return p(x.getDate()) + '/' + p(x.getMonth() + 1) + '/' + x.getFullYear(); }
    function nota(nu, n, parc, top, vlr, dias, nat, cr, prj, ch){
      var e = pick(emps);
      return {NUNOTA:nu, NUMNOTA:n, SERIENOTA:'1', CODEMP:e[0], NOMEFANTASIA:e[1], CHAVE:ch, DTNEG:dt(dias + 1), DTENTSAI:dt(dias),
        CODNAT:nat[0], DESCRNAT:nat[1], CODCENCUS:cr[0], DESCRCENCUS:cr[1], CODPROJ:prj[0], DESCRPROJ:prj[1],
        VLRNOTA:vlr, CODTIPOPER:top.CODTIPOPER, DESCROPER:top.DESCROPER,
        CONFIRMADA: rnd() > .15 ? 'Sim' : 'Não', CODPARC:parc[0], NOMEPARC:parc[1]};
    }
    function linhaRat(origem, n, l){
      return {ORIGEM:origem, NUNOTA:n.NUNOTA, NUMNOTA:n.NUMNOTA, VLRNOTA:n.VLRNOTA, SEMRATEIO:l.sem ? 'S' : 'N',
        CODNAT:l.n[0], DESCRNAT:l.n[1], CODCENCUS:l.c[0], DESCRCENCUS:l.c[1], CODPROJ:l.p[0], DESCRPROJ:l.p[1], PERCRATEIO:l.perc,
        VLRRATEIO:Math.round(n.VLRNOTA * l.perc) / 100, CODPARC:n.CODPARC};
    }
    var CTES = [], NFS = {}, RAT = {}, TOPNF = {};
    for(var i = 0; i < 24; i++){
      var nat = pick(nats), cr = pick(crs), prj = pick(prjs);
      var qtdNF = i % 5 === 4 ? 0 : (i % 7 === 0 ? 2 : 1);
      var nfs = [], linhasNF = [], fretes = 0;
      for(var j = 0; j < qtdNF; j++){
        var vlr = Math.round((8000 + rnd() * 120000) * 100) / 100, frete = Math.round(vlr * (0.02 + rnd() * 0.05) * 100) / 100;
        var nf = nota(84000 + i * 7 + j, 15230 + i * 2 + j, pick(parcs), pick(tops), vlr, 2 + Math.floor(rnd() * 25), nat, cr, prj, chave('5126'));
        nf.VLRFRETE = frete; fretes += frete;
        var rateada = (i + j) % 2 === 0;
        var ln = rateada ? [{n:nat, c:crs[0], p:prjs[1], perc:60}, {n:nat, c:crs[1], p:prjs[1], perc:40}] : [{n:nat, c:cr, p:prj, perc:100, sem:true}];
        ln.forEach(function(l){ linhasNF.push(linhaRat('NF', nf, l)); });
        nfs.push(nf);
      }
      var vc = qtdNF ? (i % 6 === 1 ? Math.round(fretes * 0.95 * 100) / 100 : fretes) : Math.round((300 + rnd() * 3000) * 100) / 100;
      var c = nota(90000 + i * 5, 7700 + i, pick(transp), pick(topsCte), vc, Math.floor(rnd() * 28), nat, cr, prj, chave('5126'));
      c.TIPFRETE = i % 3 ? 'Extra-nota' : 'Incluso na nota';
      c.CIFFOB = i % 5 === 3 ? 'Não informado' : i % 4 ? 'FOB - Contratação do Frete por conta do Destinatário' : 'CIF - Contratação do Frete por conta do Remetente';
      var base = linhasNF.length ? linhasNF.filter(function(l){ return l.NUNOTA === nfs[0].NUNOTA; }) : [];
      var lc = base.length && base[0].SEMRATEIO === 'N'
        ? base.map(function(l){ return {n:[l.CODNAT, l.DESCRNAT], c:[l.CODCENCUS, l.DESCRCENCUS], p:[l.CODPROJ, l.DESCRPROJ], perc:l.PERCRATEIO}; })
        : [{n:nat, c:cr, p:prj, perc:100, sem:true}];
      if(i % 6 === 0 && lc.length === 2){ lc[0].perc = 70; lc[1].perc = 30; }
      if(i % 8 === 2){ lc = [{n:nat, c:cr, p:prj, perc:100, sem:true}]; }
      c.QTDNF = qtdNF;
      c.QTDRAT = lc[0].sem ? 0 : lc.length;
      CTES.push(c);
      NFS[c.NUNOTA] = nfs;
      TOPNF[c.NUNOTA] = nfs.map(function(n){ return n.CODTIPOPER; });
      RAT[c.NUNOTA] = linhasNF.concat(lc.map(function(l){ return linhaRat('CTE', c, l); }));
    }
    return {
      query: function(nome, ctx){
        if(nome === 'topsNf') return tops;
        if(nome === 'topsCte') return topsCte;
        if(nome === 'ctes') return CTES.filter(function(c){
          return (!ctx.topsCte || !ctx.topsCte.length || ctx.topsCte.indexOf(c.CODTIPOPER) >= 0)
            && (!ctx.topsNf || !ctx.topsNf.length || TOPNF[c.NUNOTA].some(function(t){ return ctx.topsNf.indexOf(t) >= 0; }));
        });
        if(nome === 'nfs') return NFS[ctx.nunotaCte] || [];
        if(nome === 'rateio') return RAT[ctx.nunotaCte] || [];
        return [];
      }
    };
  })();

  /* =========================================================================
     INICIO
     ========================================================================= */
  function init(){
    if(DEMO) $('demoTag').style.display = '';
    criaListas();
    bind();
    defaultFilters();
    renderNFs();
    loadTops().catch(function(e){ toast(e.message, true); }).then(loadCTes);
  }
  if(document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init); else init();
})();
</script>
</body>
</html>
