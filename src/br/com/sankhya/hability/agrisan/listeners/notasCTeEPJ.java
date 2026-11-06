package br.com.sankhya.hability.agrisan.listeners;

import java.math.BigDecimal;

import br.com.sankhya.extensions.eventoprogramavel.EventoProgramavelJava;
import br.com.sankhya.jape.event.PersistenceEvent;
import br.com.sankhya.jape.event.TransactionContext;
import br.com.sankhya.jape.vo.DynamicVO;

/*EVENTO NA TGFNCT (NOTAS DO CONHECIMENTO DE TRANSPORTE).
  O VINCULO CTE x NF E GRAVADO NA TGFNCT DEPOIS DA TGFCAB DO CTE, ENTAO NO afterInsert DA TGFCAB
  AINDA NAO HA NF PARA COMPARAR. A SINCRONIZACAO DOS CAMPOS E DO RATEIO E FEITA AQUI, QUANDO O VINCULO EXISTE.*/
public class notasCTeEPJ implements EventoProgramavelJava {

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
		DynamicVO notaCTe = (DynamicVO) event.getVo();
		BigDecimal nuNotaCTe = notaCTe.asBigDecimalOrZero("NUNOTA");
		if(nuNotaCTe.signum() == 0) {
			return;
		}
		//IGUALA DTENTSAI, CODCENCUS E CODNAT DO CTE COM A NF E DEPOIS REPLICA O RATEIO
		cabEPJ.verificaDadosNFxCTE(nuNotaCTe);
		cabEPJ.replicaRateioNFxCTE(nuNotaCTe);
		
		/*
		BigDecimal userID = AuthenticationInfo.getCurrent().getUserID();
		if(userID.intValue() == 184) {
			DynamicVO cabNota = JapeFactory.dao(DynamicEntityNames.CABECALHO_NOTA).findOne("NUNOTA = "+nuNotaCTe);
			boolean criouTGFCAB = cabNota != null;
			ServiceContext sc = ServiceContext.getCurrent();
			sc.setStatusMessage("NUNOTA "+nuNotaCTe+" TIPMOV "+cabNota.asString("TIPMOV")+" CODMODDOC "+cabNota.asString("CHAVECTE")+" TEM TGFCAB VINCULADA "+criouTGFCAB);
			sc.setStatus(2);
		}
		*/
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
}
