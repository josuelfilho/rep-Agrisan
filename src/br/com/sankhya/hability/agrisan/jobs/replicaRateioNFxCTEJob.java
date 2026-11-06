package br.com.sankhya.hability.agrisan.jobs;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.math.BigDecimal;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

import org.cuckoo.core.ScheduledAction;
import org.cuckoo.core.ScheduledActionContext;

import br.com.sankhya.hability.agrisan.listeners.cabEPJ;
import br.com.sankhya.jape.EntityFacade;
import br.com.sankhya.jape.core.JapeSession;
import br.com.sankhya.jape.dao.JdbcWrapper;
import br.com.sankhya.jape.sql.NativeSql;
import br.com.sankhya.modelcore.auth.AuthenticationInfo;
import br.com.sankhya.modelcore.util.EntityFacadeFactory;
import br.com.sankhya.modelcore.util.SPBeanUtils;
import br.com.sankhya.ws.ServiceContext;

/*JOB: PERCORRE OS CTEs VINCULADOS A NFs DE COMPRA (VIA TGFNCT) E DEIXA O RATEIO (TGFRAV) DO CTE
  COM AS MESMAS PROPORCOES DA NF DE ORIGEM:
  - RATEIO DO CTE DIFERENTE DA NF: ATUALIZA
  - CTE SEM RATEIO E NF RATEADA: CRIA O RATEIO PROPORCIONAL
  - NF SEM RATEIO E CTE COM RATEIO: REMOVE O RATEIO DO CTE
  A REGRA E A MESMA DO EVENTO cabEPJ (replicaRateioNFxCTE)*/
public class replicaRateioNFxCTEJob implements ScheduledAction {

	//QUANTIDADE DE DIAS PARA TRAS (PELA DTNEG DO CTE) QUE O JOB VERIFICA
	private static final int DIAS_RETROATIVOS = 90;

	@Override
	public void onTime(ScheduledActionContext ctx) {
		ServiceContext sc = new ServiceContext(null);
		sc.setAutentication(AuthenticationInfo.getCurrent());
		sc.makeCurrent();
		try {
			SPBeanUtils.setupContext(sc);
		} catch (Exception e) {
			e.printStackTrace();
		}

		List<BigDecimal> ctes = new ArrayList<BigDecimal>();
		try {
			ctes = buscaCTes();
		} catch (Exception e) {
			handleException(e, "buscaCTes");
			ctx.log("Erro ao buscar CTes: " + e.getMessage());
			return;
		}

		int criados = 0, atualizados = 0, removidos = 0, erros = 0;
		for(BigDecimal nuNotaCTe : ctes) {
			try {
				String acao = cabEPJ.replicaRateioNFxCTE(nuNotaCTe);
				if(cabEPJ.RATEIO_CRIADO.equals(acao)) criados++;
				else if(cabEPJ.RATEIO_ATUALIZADO.equals(acao)) atualizados++;
				else if(cabEPJ.RATEIO_REMOVIDO.equals(acao)) removidos++;
			} catch (Exception e) {
				//ERRO EM UM CTE NAO INTERROMPE OS DEMAIS
				erros++;
				handleException(e, "replicaRateioNFxCTE NU " + nuNotaCTe);
				ctx.log("CTe NU " + nuNotaCTe + ": " + e.getMessage());
			}
		}

		ctx.info("CTes verificados: " + ctes.size()
				+ " | Rateios criados: " + criados
				+ " | Atualizados: " + atualizados
				+ " | Removidos: " + removidos
				+ " | Erros: " + erros);
	}

	/*CTEs (TIPMOV 'C', MODELO 57) DO PERIODO COM NF DE COMPRA VINCULADA VIA TGFNCT,
	  ONDE A NF OU O CTE POSSUEM RATEIO (SEM RATEIO DOS DOIS LADOS NAO HA O QUE FAZER)*/
	private static List<BigDecimal> buscaCTes() throws Exception {
		List<BigDecimal> ctes = new ArrayList<BigDecimal>();
		JapeSession.SessionHandle hnd = null;
		JdbcWrapper jdbc = null;
		NativeSql query = null;
		ResultSet rs = null;
		try {
			hnd = JapeSession.open();
			hnd.setCanTimeout(false);
			hnd.setFindersMaxRows(-1);
			EntityFacade entity = EntityFacadeFactory.getDWFFacade();
			jdbc = entity.getJdbcWrapper(); jdbc.openSession();
			query = new NativeSql(jdbc);
			query.setNamedParameter("DIAS", new BigDecimal(DIAS_RETROATIVOS));
			query.appendSql("SELECT DISTINCT CTE.NUNOTA\n"
					+ "FROM TGFCAB CTE\n"
					+ "INNER JOIN TGFTOP TPO ON TPO.CODTIPOPER = CTE.CODTIPOPER AND TPO.DHALTER = CTE.DHTIPOPER\n"
					+ "INNER JOIN TGFNCT NCT ON NCT.NUNOTA = CTE.NUNOTA\n"
					+ "INNER JOIN TGFCAB NF ON NF.NUMNOTA = TO_NUMBER(NCT.NUMERO) AND NF.CHAVENFE = NCT.CHAVENFE AND NF.TIPMOV = 'C'\n"
					+ "WHERE CTE.TIPMOV = 'C'\n"
					+ "AND TPO.CODMODDOC = 57\n"
					+ "AND CTE.DTNEG >= TRUNC(SYSDATE) - :DIAS\n"
					+ "AND (EXISTS (SELECT 1 FROM TGFRAV RAV WHERE RAV.ORIGEM = 'E' AND RAV.NUFIN = NF.NUNOTA)\n"
					+ "  OR EXISTS (SELECT 1 FROM TGFRAV RAV WHERE RAV.ORIGEM = 'E' AND RAV.NUFIN = CTE.NUNOTA))\n"
					+ "ORDER BY CTE.NUNOTA");
			rs = query.executeQuery();
			while(rs.next()) {
				ctes.add(rs.getBigDecimal("NUNOTA"));
			}
		} finally {
			if(rs != null) rs.close();
			NativeSql.releaseResources(query);
			JdbcWrapper.closeSession(jdbc);
			JapeSession.close(hnd);
		}
		return ctes;
	}

	private static void handleException(Exception e, String metodo) {
		StringWriter sw = new StringWriter();
		PrintWriter pw = new PrintWriter(sw);
		e.printStackTrace(pw);
		System.out.println("Erro! " + metodo + ": " + e.getMessage() + " - " + sw.toString());
	}

}
