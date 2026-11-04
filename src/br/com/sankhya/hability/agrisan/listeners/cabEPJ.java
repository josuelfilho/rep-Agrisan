package br.com.sankhya.hability.agrisan.listeners;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.util.LinkedHashMap;
import java.util.Map;

import br.com.sankhya.extensions.eventoprogramavel.EventoProgramavelJava;
import br.com.sankhya.jape.EntityFacade;
import br.com.sankhya.jape.core.JapeSession;
import br.com.sankhya.jape.dao.JdbcWrapper;
import br.com.sankhya.jape.event.PersistenceEvent;
import br.com.sankhya.jape.event.TransactionContext;
import br.com.sankhya.jape.sql.NativeSql;
import br.com.sankhya.modelcore.MGEModelException;
import br.com.sankhya.modelcore.util.EntityFacadeFactory;
import br.com.sankhya.jape.vo.DynamicVO;

public class cabEPJ implements EventoProgramavelJava {

	@Override
	public void beforeInsert(PersistenceEvent event) throws Exception {
		// TODO Auto-generated method stub

	}

	@Override
	public void beforeUpdate(PersistenceEvent event) throws Exception {
		// TODO Auto-generated method stub

	}

	@Override
	public void beforeDelete(PersistenceEvent event) throws Exception {
		// TODO Auto-generated method stub

	}

	@Override
	public void afterInsert(PersistenceEvent event) throws Exception {
		DynamicVO cabNota = (DynamicVO) event.getVo();
		BigDecimal nuNotaCTe = cabNota.asBigDecimalOrZero("NUNOTA");
		verificaDadosNFxCTE(nuNotaCTe);

	}

	@Override
	public void afterUpdate(PersistenceEvent event) throws Exception {
		// TODO Auto-generated method stub

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
					+ "\n"
					+ "NF.NUNOTA AS NUNOTANF,\n"
					+ "NF.NUMNOTA AS NUMNOTANF,\n"
					+ "NF.CODCENCUS AS CODCENCUSNF,\n"
					+ "NF.CODNAT AS CODNATNF,\n"
					+ "NF.DTENTSAI AS DTENTSAINF\n"
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
				//VERIFICA OS CAMPOS DO CTE LANÇADO: DTENTSAI, CODCENCUS, CODNAT
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
