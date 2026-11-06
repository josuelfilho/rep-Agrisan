package br.com.sankhya.hability.agrisan.listeners;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;
import java.util.LinkedHashMap;
import java.util.Map;

import br.com.sankhya.extensions.eventoprogramavel.EventoProgramavelJava;
import br.com.sankhya.jape.EntityFacade;
import br.com.sankhya.jape.core.JapeSession;
import br.com.sankhya.jape.dao.JdbcWrapper;
import br.com.sankhya.jape.event.ModifingFields;
import br.com.sankhya.jape.event.PersistenceEvent;
import br.com.sankhya.jape.event.TransactionContext;
import br.com.sankhya.jape.sql.NativeSql;
import br.com.sankhya.modelcore.MGEModelException;
import br.com.sankhya.modelcore.util.EntityFacadeFactory;
import br.com.sankhya.ws.ServiceContext;
import br.com.sankhya.jape.vo.DynamicVO;

public class cabEPJ implements EventoProgramavelJava {

	@Override
	public void beforeInsert(PersistenceEvent event) throws Exception {
		// TODO Auto-generated method stub

	}

	@Override
	public void beforeUpdate(PersistenceEvent event) throws Exception {
		//VERIFICA SE O USUARIO ESTA ALTERANDO ALGUM DOS CAMPOS: DTENTSAI, CODCENCUS, CODNAT, CODPROJ
		ModifingFields modificados = event.getModifingFields();
		Map<String, Object> camposAlterados = new LinkedHashMap<String, Object>();
		DynamicVO cabNota = (DynamicVO) event.getVo();

		if(modificados.isModifing("DTENTSAI")) {
			camposAlterados.put("DTENTSAI", cabNota.asTimestamp("DTENTSAI"));
		}
		if(modificados.isModifing("CODCENCUS")) {
			camposAlterados.put("CODCENCUS", cabNota.asBigDecimal("CODCENCUS"));
		}
		if(modificados.isModifing("CODNAT")) {
			camposAlterados.put("CODNAT", cabNota.asBigDecimal("CODNAT"));
		}
		if(modificados.isModifing("CODPROJ")) {
			camposAlterados.put("CODPROJ", cabNota.asBigDecimal("CODPROJ"));
		}

		if(camposAlterados.isEmpty()) {
			return;
		}

		BigDecimal nuNotaCTe = cabNota.asBigDecimalOrZero("NUNOTA");
		Map<String, Object> valoresNF = new LinkedHashMap<String, Object>();
		String bloqueio = verificaAlteracaoCTexNF(nuNotaCTe, camposAlterados, valoresNF);
		if(bloqueio == null) {
			return;
		}

		String servico = nomeServico();
		if(isProcessoImportacao(servico)) {
			//IMPORTACAO DO XML (PORTAL DE IMPORTACAO) GRAVA SEUS PROPRIOS VALORES NA TGFCAB DEPOIS DO VINCULO NA TGFNCT.
			//NAO BLOQUEIA: MANTEM OS VALORES DA NF NO CTE
			for(Map.Entry<String, Object> campo : valoresNF.entrySet()) {
				cabNota.setProperty(campo.getKey(), campo.getValue());
			}
			System.out.println("CTe NU " + nuNotaCTe + ": importacao (" + servico + ") tentou alterar "
					+ valoresNF.keySet() + ". Mantidos os valores da NF.");
			return;
		}

		System.out.println("CTe NU " + nuNotaCTe + ": alteracao bloqueada. Servico: " + servico);
		MGEModelException.throwMe(new IllegalStateException(bloqueio + " (Serviço: " + servico + ")"));
	}

	@Override
	public void beforeDelete(PersistenceEvent event) throws Exception {
		// TODO Auto-generated method stub

	}

	@Override
	public void afterInsert(PersistenceEvent event) throws Exception {
		//NO INSERT DA TGFCAB A TGFNCT AINDA NAO EXISTE.
		//A SINCRONIZACAO CTE x NF (CAMPOS E RATEIO) E FEITA NO afterInsert DA TGFNCT: notasCTeEPJ
	}

	@Override
	public void afterUpdate(PersistenceEvent event) throws Exception {
		//APOS ALTERAR/VALIDAR OS CAMPOS DO CTE, VALIDA O RATEIO COM BASE NAS NFs
		ModifingFields modificados = event.getModifingFields();
		if(modificados.isModifing("DTENTSAI") || modificados.isModifing("CODCENCUS")
				|| modificados.isModifing("CODNAT") || modificados.isModifing("CODPROJ")) {
			DynamicVO cabNota = (DynamicVO) event.getVo();
			replicaRateioNFxCTE(cabNota.asBigDecimalOrZero("NUNOTA"));
		}
	}

	@Override
	public void afterDelete(PersistenceEvent event) throws Exception {
		// TODO Auto-generated method stub

	}

	@Override
	public void beforeCommit(TransactionContext tranCtx) throws Exception {
		// TODO Auto-generated method stub

	}
	
	public static void verificaDadosNFxCTE(BigDecimal nuNotaCTe) throws MGEModelException {
		JapeSession.SessionHandle hnd = null;
		JdbcWrapper jdbc = null;
		NativeSql query = null;
		ResultSet rset = null;
		try {
			hnd = JapeSession.open(); hnd.setFindersMaxRows(-1);
			EntityFacade entity = EntityFacadeFactory.getDWFFacade();
			jdbc = entity.getJdbcWrapper(); jdbc.openSession();
			query = new NativeSql(jdbc);	
			query.setNamedParameter("NUNOTA", nuNotaCTe);
			query.appendSql("SELECT CAB.NUNOTA AS NUNOTACTE,\n"
					+ "CAB.NUMNOTA AS NUMNOTACTE,\n"
					+ "CAB.CODCENCUS AS CODCENCUSCTE,\n"
					+ "CAB.CODNAT AS CODNATCTE,\n"
					+ "CAB.DTENTSAI AS DTENTSAICTE,\n"
					+ "CAB.CODPROJ AS CODPROJCTE,\n"
					+ "\n"
					+ "NF.NUNOTA AS NUNOTANF,\n"
					+ "NF.NUMNOTA AS NUMNOTANF,\n"
					+ "NF.CODCENCUS AS CODCENCUSNF,\n"
					+ "NF.CODNAT AS CODNATNF,\n"
					+ "NF.DTENTSAI AS DTENTSAINF,\n"
					+ "NF.CODPROJ AS CODPROJNF\n"
					+ "\n"
					+ "FROM TGFCAB CAB\n"
					+ "INNER JOIN TGFTOP TPO ON TPO.CODTIPOPER = CAB.CODTIPOPER AND TPO.DHALTER = CAB.DHTIPOPER\n"
					+ "INNER JOIN TGFNCT NCT ON CAB.NUNOTA = NCT.NUNOTA\n"
					+ "INNER JOIN TGFCAB NF ON NF.NUMNOTA = TO_NUMBER(NCT.NUMERO) AND NF.CHAVENFE = NCT.CHAVENFE\n"
					+ "WHERE CAB.TIPMOV = 'C' AND TPO.CODMODDOC = 57\n"
					+ "AND CAB.NUNOTA = :NUNOTA ");
			rset = query.executeQuery();
			//PERCORRE TODAS AS NOTAS VINCULADAS AO CTE
			while(rset.next()) {
				//VERIFICA OS CAMPOS DO CTE LANÇADO: DTENTSAI, CODCENCUS, CODNAT, CODPROJ
				//SE CAMPOS FOREM DIFERENTES DA NF PRECISAM SER IGUAIS A NF LANÇADA ONDE BUSCAMOS VIA TGFNCT
				Map<String, Object> camposAlterar = new LinkedHashMap<String, Object>();

				Timestamp dtEntSaiCTe = rset.getTimestamp("DTENTSAICTE");
				Timestamp dtEntSaiNF = rset.getTimestamp("DTENTSAINF");
				if(!iguais(dtEntSaiCTe, dtEntSaiNF)) {
					camposAlterar.put("DTENTSAI", dtEntSaiNF);
				}

				BigDecimal codCenCusCTe = rset.getBigDecimal("CODCENCUSCTE");
				BigDecimal codCenCusNF = rset.getBigDecimal("CODCENCUSNF");
				if(!iguais(codCenCusCTe, codCenCusNF)) {
					camposAlterar.put("CODCENCUS", codCenCusNF);
				}

				BigDecimal codNatCTe = rset.getBigDecimal("CODNATCTE");
				BigDecimal codNatNF = rset.getBigDecimal("CODNATNF");
				if(!iguais(codNatCTe, codNatNF)) {
					camposAlterar.put("CODNAT", codNatNF);
				}

				BigDecimal codProjCTe = rset.getBigDecimal("CODPROJCTE");
				BigDecimal codProjNF = rset.getBigDecimal("CODPROJNF");
				if(!iguais(codProjCTe, codProjNF)) {
					camposAlterar.put("CODPROJ", codProjNF);
				}

				if(!camposAlterar.isEmpty()) {
					updateTGFCAB(nuNotaCTe, camposAlterar);
					System.out.println("CTe NU " + nuNotaCTe + " atualizado com base na NF NU "
							+ rset.getBigDecimal("NUNOTANF") + ". Campos: " + camposAlterar.keySet());
				}
			}
		} catch(Exception e) {
			handleException(e, "verificaDadosNFxCTE");
		} finally {
			NativeSql.releaseResources(query);
			JdbcWrapper.closeSession(jdbc);
			JapeSession.close(hnd);
		}
	}

	/*REPLICA O RATEIO (TGFRAV) DAS NFs VINCULADAS VIA TGFNCT PARA O CTE.
	  - 1 NF: O CTE RECEBE OS MESMOS PERCENTUAIS DA NF.
	  - VARIAS NFs: CADA NF PESA PELO SEU VLRNOTA E OS PERCENTUAIS SAO SOMADOS POR NATUREZA/CR/PROJETO.
	  - NENHUMA NF COM RATEIO: O RATEIO DO CTE E REMOVIDO (CTE NAO DEVE TER RATEIO).
	  - VARIAS NFs E SO ALGUMAS COM RATEIO: A NF SEM RATEIO ENTRA COM 100% NA NATUREZA/CR/PROJETO DO CABECALHO DELA.
	  SO REGRAVA O RATEIO DO CTE SE ELE ESTIVER DIFERENTE DO ESPERADO.
	  RETORNA O QUE FOI FEITO: RATEIO_CRIADO, RATEIO_ATUALIZADO, RATEIO_REMOVIDO OU NULL (NADA ALTERADO)*/
	public static final String RATEIO_CRIADO = "CRIADO";
	public static final String RATEIO_ATUALIZADO = "ATUALIZADO";
	public static final String RATEIO_REMOVIDO = "REMOVIDO";

	public static String replicaRateioNFxCTE(BigDecimal nuNotaCTe) throws MGEModelException {
		String acao = null;
		JapeSession.SessionHandle hnd = null;
		JdbcWrapper jdbc = null;
		NativeSql query = null;
		ResultSet rset = null;
		try {
			hnd = JapeSession.open(); hnd.setFindersMaxRows(-1);
			EntityFacade entity = EntityFacadeFactory.getDWFFacade();
			jdbc = entity.getJdbcWrapper(); jdbc.openSession();

			//1. NFs VINCULADAS AO CTE
			query = new NativeSql(jdbc);
			query.setNamedParameter("NUNOTA", nuNotaCTe);
			query.appendSql("SELECT CAB.CODPARC AS CODPARCCTE,\n"
					+ "NF.NUNOTA AS NUNOTANF,\n"
					+ "NF.VLRNOTA AS VLRNOTANF,\n"
					+ "NF.CODPARC AS CODPARCNF,\n"
					+ "NF.CODNAT AS CODNATNF,\n"
					+ "NF.CODCENCUS AS CODCENCUSNF,\n"
					+ "NF.CODPROJ AS CODPROJNF\n"
					+ "FROM TGFCAB CAB\n"
					+ "INNER JOIN TGFTOP TPO ON TPO.CODTIPOPER = CAB.CODTIPOPER AND TPO.DHALTER = CAB.DHTIPOPER\n"
					+ "INNER JOIN TGFNCT NCT ON CAB.NUNOTA = NCT.NUNOTA\n"
					+ "INNER JOIN TGFCAB NF ON NF.NUMNOTA = TO_NUMBER(NCT.NUMERO) AND NF.CHAVENFE = NCT.CHAVENFE AND NF.TIPMOV = 'C'\n"
					+ "WHERE CAB.TIPMOV = 'C' AND TPO.CODMODDOC = 57\n"
					+ "AND CAB.NUNOTA = :NUNOTA\n"
					+ "ORDER BY NF.NUNOTA");
			rset = query.executeQuery();

			BigDecimal codParcCTe = null;
			java.util.List<Object[]> nfs = new java.util.ArrayList<Object[]>();
			BigDecimal totalNFs = BigDecimal.ZERO;
			while(rset.next()) {
				codParcCTe = rset.getBigDecimal("CODPARCCTE");
				BigDecimal vlrNota = nvl(rset.getBigDecimal("VLRNOTANF"));
				totalNFs = totalNFs.add(vlrNota);
				nfs.add(new Object[] {
						rset.getBigDecimal("NUNOTANF"), vlrNota, rset.getBigDecimal("CODPARCNF"),
						nvl(rset.getBigDecimal("CODNATNF")), nvl(rset.getBigDecimal("CODCENCUSNF")), nvl(rset.getBigDecimal("CODPROJNF"))});
			}
			rset.close();
			NativeSql.releaseResources(query);

			if(nfs.isEmpty()) {
				return null;
			}

			//2. MONTA O RATEIO ESPERADO PARA O CTE
			Map<String, LinhaRateio> esperado = new LinkedHashMap<String, LinhaRateio>();
			boolean algumaNFRateada = false;
			BigDecimal cem = new BigDecimal(100);

			for(Object[] nf : nfs) {
				BigDecimal nuNotaNF = (BigDecimal) nf[0];
				BigDecimal peso = totalNFs.signum() == 0
						? BigDecimal.ONE.divide(new BigDecimal(nfs.size()), 12, BigDecimal.ROUND_HALF_UP)
						: ((BigDecimal) nf[1]).divide(totalNFs, 12, BigDecimal.ROUND_HALF_UP);

				java.util.List<LinhaRateio> linhasNF = buscaRateio(jdbc, nuNotaNF);
				if(linhasNF.isEmpty()) {
					//NF SEM RATEIO: USA O CABECALHO DA NF COM 100%
					LinhaRateio cabecalhoNF = new LinhaRateio();
					cabecalhoNF.codNat = (BigDecimal) nf[3];
					cabecalhoNF.codCenCus = (BigDecimal) nf[4];
					cabecalhoNF.codProj = (BigDecimal) nf[5];
					cabecalhoNF.codParc = BigDecimal.ZERO;
					cabecalhoNF.perc = cem;
					linhasNF.add(cabecalhoNF);
				} else {
					algumaNFRateada = true;
				}

				for(LinhaRateio linha : linhasNF) {
					//O PARCEIRO DA NF NO RATEIO PASSA A SER O PARCEIRO DO CTE (TRANSPORTADORA)
					if(codParcCTe != null && iguais(linha.codParc, nf[2])) {
						linha.codParc = codParcCTe;
					}
					linha.perc = linha.perc.multiply(peso);
					LinhaRateio existente = esperado.get(linha.chave());
					if(existente == null) {
						esperado.put(linha.chave(), linha);
					} else {
						existente.perc = existente.perc.add(linha.perc);
					}
				}
			}

			//NENHUMA NF DE ORIGEM COM LINHAS NA TGFRAV: O CTE NAO DEVE TER RATEIO
			if(!algumaNFRateada) {
				int linhasCTe = buscaRateio(jdbc, nuNotaCTe).size();
				if(linhasCTe > 0) {
					query = new NativeSql(jdbc);
					query.setNamedParameter("NUFIN", nuNotaCTe);
					query.appendSql("DELETE FROM TGFRAV WHERE ORIGEM = 'E' AND NUFIN = :NUFIN");
					query.executeUpdate();
					System.out.println("CTe NU " + nuNotaCTe + ": NF de origem sem rateio. Rateio do CTe removido ("
							+ linhasCTe + " linhas)");
					return RATEIO_REMOVIDO;
				}
				return null;
			}

			//AJUSTA ARREDONDAMENTO PARA FECHAR 100% NA MAIOR LINHA
			BigDecimal soma = BigDecimal.ZERO;
			LinhaRateio maior = null;
			for(LinhaRateio linha : esperado.values()) {
				linha.perc = linha.perc.setScale(8, BigDecimal.ROUND_HALF_UP);
				soma = soma.add(linha.perc);
				if(maior == null || linha.perc.compareTo(maior.perc) > 0) maior = linha;
			}
			maior.perc = maior.perc.add(cem.subtract(soma));

			//3. COMPARA COM O RATEIO ATUAL DO CTE
			java.util.List<LinhaRateio> atual = buscaRateio(jdbc, nuNotaCTe);
			boolean igual = atual.size() == esperado.size();
			if(igual) {
				for(LinhaRateio linha : atual) {
					LinhaRateio esp = esperado.get(linha.chave());
					if(esp == null || linha.perc.subtract(esp.perc).abs().compareTo(new BigDecimal("0.0001")) > 0) {
						igual = false;
						break;
					}
				}
			}
			if(igual) {
				return null;
			}

			//4. REGRAVA O RATEIO DO CTE
			query = new NativeSql(jdbc);
			query.setNamedParameter("NUFIN", nuNotaCTe);
			query.appendSql("DELETE FROM TGFRAV WHERE ORIGEM = 'E' AND NUFIN = :NUFIN");
			query.executeUpdate();
			NativeSql.releaseResources(query);

			for(LinhaRateio linha : esperado.values()) {
				query = new NativeSql(jdbc);
				query.setNamedParameter("NUFIN", nuNotaCTe);
				query.setNamedParameter("CODNAT", linha.codNat);
				query.setNamedParameter("CODCENCUS", linha.codCenCus);
				query.setNamedParameter("CODPROJ", linha.codProj);
				query.setNamedParameter("PERCRATEIO", linha.perc);
				query.setNamedParameter("NUMCONTRATO", linha.numContrato);
				query.setNamedParameter("CODSITE", linha.codSite);
				query.setNamedParameter("CODPARC", linha.codParc);
				query.setNamedParameter("CODVEICULO", linha.codVeiculo);
				query.setNamedParameter("TIPOAFERICAO", linha.tipoAfericao);
				query.setNamedParameter("AFERICAO", linha.afericao);
				query.appendSql("INSERT INTO TGFRAV (ORIGEM, NUFIN, CODNAT, CODCENCUS, CODPROJ, PERCRATEIO, CODCTACTB, NUMCONTRATO,\n"
						+ "DIGITADO, CODSITE, CODPARC, CODVEICULO, TIPOAFERICAO, AFERICAO, DTALTER)\n"
						+ "VALUES ('E', :NUFIN, :CODNAT, :CODCENCUS, :CODPROJ, :PERCRATEIO, "
						+ (linha.codCtaCtb == null ? "NULL" : linha.codCtaCtb.toPlainString()) + ", :NUMCONTRATO,\n"
						+ "'S', :CODSITE, :CODPARC, :CODVEICULO, :TIPOAFERICAO, :AFERICAO, SYSDATE)");
				query.executeUpdate();
				NativeSql.releaseResources(query);
			}
			query = null;

			acao = atual.isEmpty() ? RATEIO_CRIADO : RATEIO_ATUALIZADO;
			System.out.println("CTe NU " + nuNotaCTe + ": rateio " + acao + " com base nas NFs (" + esperado.size() + " linhas)");
		} catch(Exception e) {
			handleException(e, "replicaRateioNFxCTE");
		} finally {
			NativeSql.releaseResources(query);
			JdbcWrapper.closeSession(jdbc);
			JapeSession.close(hnd);
		}
		return acao;
	}

	/*BUSCA AS LINHAS DE RATEIO (TGFRAV ORIGEM 'E') DE UMA NOTA*/
	private static java.util.List<LinhaRateio> buscaRateio(JdbcWrapper jdbc, BigDecimal nuNota) throws Exception {
		java.util.List<LinhaRateio> linhas = new java.util.ArrayList<LinhaRateio>();
		NativeSql query = new NativeSql(jdbc);
		ResultSet rset = null;
		try {
			query.setNamedParameter("NUFIN", nuNota);
			query.appendSql("SELECT CODNAT, CODCENCUS, CODPROJ, PERCRATEIO, CODCTACTB, NUMCONTRATO, CODSITE, CODPARC,\n"
					+ "CODVEICULO, TIPOAFERICAO, AFERICAO\n"
					+ "FROM TGFRAV WHERE ORIGEM = 'E' AND NUFIN = :NUFIN");
			rset = query.executeQuery();
			while(rset.next()) {
				LinhaRateio linha = new LinhaRateio();
				linha.codNat = nvl(rset.getBigDecimal("CODNAT"));
				linha.codCenCus = nvl(rset.getBigDecimal("CODCENCUS"));
				linha.codProj = nvl(rset.getBigDecimal("CODPROJ"));
				linha.perc = nvl(rset.getBigDecimal("PERCRATEIO"));
				linha.codCtaCtb = rset.getBigDecimal("CODCTACTB");
				linha.numContrato = nvl(rset.getBigDecimal("NUMCONTRATO"));
				linha.codSite = nvl(rset.getBigDecimal("CODSITE"));
				linha.codParc = nvl(rset.getBigDecimal("CODPARC"));
				linha.codVeiculo = nvl(rset.getBigDecimal("CODVEICULO"));
				String tipoAfericao = rset.getString("TIPOAFERICAO");
				linha.tipoAfericao = tipoAfericao == null ? "N" : tipoAfericao;
				linha.afericao = nvl(rset.getBigDecimal("AFERICAO"));
				linhas.add(linha);
			}
		} finally {
			if(rset != null) rset.close();
			NativeSql.releaseResources(query);
		}
		return linhas;
	}

	private static BigDecimal nvl(BigDecimal valor) {
		return valor == null ? BigDecimal.ZERO : valor;
	}

	/*LINHA DE RATEIO (TGFRAV). A CHAVE SEGUE A PK DA TABELA, SEM ORIGEM/NUFIN*/
	private static class LinhaRateio {
		BigDecimal codNat, codCenCus, codProj, perc, codCtaCtb, numContrato, codSite, codParc, codVeiculo, afericao;
		String tipoAfericao = "N";

		{
			numContrato = BigDecimal.ZERO; codSite = BigDecimal.ZERO; codVeiculo = BigDecimal.ZERO; afericao = BigDecimal.ZERO;
		}

		String chave() {
			return k(codNat) + "|" + k(codCenCus) + "|" + k(codProj) + "|" + k(codSite) + "|" + k(codParc) + "|" + k(codVeiculo);
		}

		private static String k(BigDecimal valor) {
			return valor.stripTrailingZeros().toPlainString();
		}
	}

	/*VERIFICA SE OS VALORES ALTERADOS NO CTE SAO DIFERENTES DAS NFs VINCULADAS VIA TGFNCT.
	  RETORNA A MENSAGEM DE BLOQUEIO DA PRIMEIRA NF DIVERGENTE OU NULL SE ESTIVER TUDO IGUAL.
	  valoresNF (OPCIONAL) RECEBE OS VALORES DA NF DIVERGENTE PARA OS CAMPOS DIFERENTES*/
	public static String verificaAlteracaoCTexNF(BigDecimal nuNotaCTe, Map<String, Object> camposAlterados,
			Map<String, Object> valoresNF) throws MGEModelException {
		JapeSession.SessionHandle hnd = null;
		JdbcWrapper jdbc = null;
		NativeSql query = null;
		ResultSet rset = null;
		String bloqueio = null;
		try {
			hnd = JapeSession.open(); hnd.setFindersMaxRows(-1);
			EntityFacade entity = EntityFacadeFactory.getDWFFacade();
			jdbc = entity.getJdbcWrapper(); jdbc.openSession();
			query = new NativeSql(jdbc);
			query.setNamedParameter("NUNOTA", nuNotaCTe);
			query.appendSql("SELECT NF.NUNOTA AS NUNOTANF,\n"
					+ "NF.NUMNOTA AS NUMNOTANF,\n"
					+ "NF.CODCENCUS AS CODCENCUS,\n"
					+ "NF.CODNAT AS CODNAT,\n"
					+ "NF.CODPROJ AS CODPROJ,\n"
					+ "NF.DTENTSAI AS DTENTSAI\n"
					+ "\n"
					+ "FROM TGFCAB CAB\n"
					+ "INNER JOIN TGFTOP TPO ON TPO.CODTIPOPER = CAB.CODTIPOPER AND TPO.DHALTER = CAB.DHTIPOPER\n"
					+ "INNER JOIN TGFNCT NCT ON CAB.NUNOTA = NCT.NUNOTA\n"
					+ "INNER JOIN TGFCAB NF ON NF.NUMNOTA = TO_NUMBER(NCT.NUMERO) AND NF.CHAVENFE = NCT.CHAVENFE\n"
					+ "WHERE CAB.TIPMOV = 'C' AND TPO.CODMODDOC = 57\n"
					+ "AND CAB.NUNOTA = :NUNOTA ");
			rset = query.executeQuery();
			//PERCORRE TODAS AS NOTAS VINCULADAS AO CTE
			while(rset.next() && bloqueio == null) {
				StringBuilder campos = new StringBuilder();
				StringBuilder valores = new StringBuilder();

				for(Map.Entry<String, Object> campo : camposAlterados.entrySet()) {
					Object valorNF = "DTENTSAI".equals(campo.getKey())
							? rset.getTimestamp(campo.getKey())
							: rset.getBigDecimal(campo.getKey());
					if(!iguais(campo.getValue(), valorNF)) {
						if(campos.length() > 0) { campos.append(", "); valores.append(", "); }
						campos.append(campo.getKey());
						valores.append(formatar(campo.getValue()));
						if(valoresNF != null) valoresNF.put(campo.getKey(), valorNF);
					}
				}

				if(campos.length() > 0) {
					bloqueio = "Bloqueio! Não é possível alterar os campos " + campos
							+ " os valores " + valores
							+ " são diferentes da NF " + rset.getBigDecimal("NUNOTANF")
							+ " Nro. Nota " + rset.getBigDecimal("NUMNOTANF");
				}
			}
		} catch(Exception e) {
			handleException(e, "verificaAlteracaoCTexNF");
		} finally {
			NativeSql.releaseResources(query);
			JdbcWrapper.closeSession(jdbc);
			JapeSession.close(hnd);
		}
		return bloqueio;
	}

	/*NOME DO SERVICO QUE ESTA GRAVANDO A NOTA (TELA, IMPORTACAO, JOB...). "SEM CONTEXTO" QUANDO NAO HA ServiceContext*/
	private static String nomeServico() {
		ServiceContext sc = ServiceContext.getCurrent();
		if(sc == null || sc.getServiceName() == null) return "SEM CONTEXTO";
		return sc.getServiceName();
	}

	/*IDENTIFICA O PROCESSO DE IMPORTACAO DE XML PELO NOME DO SERVICO.
	  SE O BLOQUEIO AINDA OCORRER NA IMPORTACAO, A MENSAGEM MOSTRA O SERVICO: INCLUIR O NOME AQUI*/
	private static final String[] SERVICOS_IMPORTACAO = {"IMPORT", "XML"};

	private static boolean isProcessoImportacao(String servico) {
		String nome = servico.toUpperCase();
		for(String trecho : SERVICOS_IMPORTACAO) {
			if(nome.contains(trecho)) return true;
		}
		return false;
	}

	/*FORMATA O VALOR PARA A MENSAGEM (DATA EM dd/MM/yyyy)*/
	private static String formatar(Object valor) {
		if(valor == null) return "(vazio)";
		if(valor instanceof Timestamp) return new SimpleDateFormat("dd/MM/yyyy").format((Timestamp) valor);
		return valor.toString();
	}

	/*COMPARA DOIS VALORES TRATANDO NULOS (BIGDECIMAL VIA compareTo PARA IGNORAR ESCALA)*/
	private static boolean iguais(Object valorCTe, Object valorNF) {
		if(valorCTe == null && valorNF == null) return true;
		if(valorCTe == null || valorNF == null) return false;
		if(valorCTe instanceof BigDecimal && valorNF instanceof BigDecimal) {
			return ((BigDecimal) valorCTe).compareTo((BigDecimal) valorNF) == 0;
		}
		return valorCTe.equals(valorNF);
	}

	/*MONTA O UPDATE DE ACORDO COM A QUANTIDADE DE CAMPOS ALTERADOS*/
	public static void updateTGFCAB(BigDecimal nuNotaCTe, Map<String, Object> camposAlterar) throws MGEModelException {
        JapeSession.SessionHandle hnd = null;
        JdbcWrapper jdbc = null;
        NativeSql query = null;
        try {
            hnd = JapeSession.open();
            hnd.setFindersMaxRows(-1);

            EntityFacade entity = EntityFacadeFactory.getDWFFacade();
            jdbc = entity.getJdbcWrapper();
            jdbc.openSession();
            query = new NativeSql(jdbc);
            query.setNamedParameter("NUNOTA", nuNotaCTe);

            StringBuilder set = new StringBuilder();
            for(Map.Entry<String, Object> campo : camposAlterar.entrySet()) {
            	if(set.length() > 0) set.append(", ");
            	set.append(campo.getKey()).append(" = :").append(campo.getKey());
            	query.setNamedParameter(campo.getKey(), campo.getValue());
            }

            query.appendSql("UPDATE TGFCAB SET " + set + " WHERE NUNOTA = :NUNOTA ");
            query.executeUpdate();
        } catch (Exception e) {
            handleException(e, "updateTGFCAB");
        } finally {
            NativeSql.releaseResources(query);
            JdbcWrapper.closeSession(jdbc);
            JapeSession.close(hnd);
        }
    }
	
	private static void handleException(Exception e, String metodo) throws MGEModelException {
		StringWriter sw = new StringWriter();
		PrintWriter pw = new PrintWriter(sw);
		StringBuffer mensagem = new StringBuffer();
		e.printStackTrace(pw);
		mensagem.append("Erro! "+metodo+": " + e.getMessage() + " - " + sw.toString());
		System.out.println("Erro! "+metodo+": " + e.getMessage() + " - " + sw.toString());
		MGEModelException.throwMe(new IllegalStateException("Erro! "+metodo+": " + e.getMessage() + " - " + sw.toString()));
    }
}
